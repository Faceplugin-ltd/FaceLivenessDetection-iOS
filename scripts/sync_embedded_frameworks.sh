#!/bin/bash
# Re-copy the vendor-built engine from the repo after the Embed Frameworks phase.
# Xcode incremental Debug builds can replace facerecognitionsdk with a small Swift stub.
#
# The engine is facerecognitionsdk.framework — the same build Face-Recognition-LivenessDetection-iOS
# ships — plus the three companion frameworks it links (@rpath FaceDetect / FacePPlugin /
# FacePluginSDK). Get them from that product's GitHub release (or the SDK repo) and drop them
# at the repo root.
set -euo pipefail

DEST="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
SRC="${PROJECT_DIR}"

if [[ -z "${DEST}" || ! -d "${SRC}" ]]; then
  echo "sync_embedded_frameworks: skip (not an app build)" >&2
  exit 0
fi

mkdir -p "${DEST}"

# Stamp of last successful sync from SRC. Destination binaries are codesigned after
# copy, so size/mtime no longer match the unsigned source — comparing those would
# force a ~70MB re-ditto on every Debug rebuild.
STAMP_DIR="${DEST}/.sync_embedded_stamps"
mkdir -p "${STAMP_DIR}"

source_token() {
  local bin="$1"
  local size mtime
  size=$(/usr/bin/stat -f%z "${bin}")
  mtime=$(/usr/bin/stat -f%m "${bin}")
  printf '%s %s' "${size}" "${mtime}"
}

framework_fresh() {
  local stamp_name="$1"
  local from_bin="$2"
  local to_bin="$3"
  local min_bytes="${4:-80000}"
  [[ -f "${from_bin}" && -f "${to_bin}" ]] || return 1
  local to_size
  to_size=$(/usr/bin/stat -f%z "${to_bin}")
  # Reject Xcode's tiny Swift stub if Embed replaced our copy.
  [[ "${to_size}" -ge "${min_bytes}" ]] || return 1
  local stamp="${STAMP_DIR}/${stamp_name}"
  [[ -f "${stamp}" ]] || return 1
  local expected actual
  expected=$(/bin/cat "${stamp}")
  actual=$(source_token "${from_bin}")
  [[ "${expected}" == "${actual}" ]]
}

record_stamp() {
  local stamp_name="$1"
  local from_bin="$2"
  source_token "${from_bin}" > "${STAMP_DIR}/${stamp_name}"
}

copy_framework() {
  local name="$1"
  local from="${SRC}/${name}.framework"
  local to="${DEST}/${name}.framework"
  if [[ ! -d "${from}" ]]; then
    echo "error: missing ${from}" >&2
    exit 1
  fi
  if framework_fresh "${name}" "${from}/${name}" "${to}/${name}"; then
    echo "sync_embedded_frameworks: keep ${name}.framework"
    return 0
  fi
  rm -rf "${to}"
  /usr/bin/ditto "${from}" "${to}"
  record_stamp "${name}" "${from}/${name}"
}

# Device slice only (ios-arm64). Simulator xcframeworks are not shipped.
copy_xcframework() {
  local xcname="$1"
  local slice="${SRC}/${xcname}.xcframework/ios-arm64"
  local from
  from="$(/bin/ls -d "${slice}"/*.framework 2>/dev/null | /usr/bin/head -1 || true)"
  if [[ -z "${from}" || ! -d "${from}" ]]; then
    echo "error: missing ${slice}/*.framework" >&2
    exit 1
  fi
  local fwname
  fwname="$(/usr/bin/basename "${from}" .framework)"
  local to="${DEST}/${fwname}.framework"
  # Companion frameworks can be smaller than the engine; only require a real binary.
  if framework_fresh "${fwname}" "${from}/${fwname}" "${to}/${fwname}" 10000; then
    echo "sync_embedded_frameworks: keep ${fwname}.framework"
    return 0
  fi
  rm -rf "${to}"
  /usr/bin/ditto "${from}" "${to}"
  record_stamp "${fwname}" "${from}/${fwname}"
}

copy_framework facerecognitionsdk
copy_xcframework FacePluginSDK
copy_xcframework FacePlugin
copy_xcframework FaceDetect

# Drop leftovers from the previous engine so dyld / codesign do not carry them.
for stale in facelivenessdk FaceLivenessEngine onnxruntime; do
  if [[ -d "${DEST}/${stale}.framework" ]]; then
    rm -rf "${DEST}/${stale}.framework"
    echo "sync_embedded_frameworks: removed stale ${stale}.framework"
  fi
done

SDK_BIN="${DEST}/facerecognitionsdk.framework/facerecognitionsdk"
if [[ ! -f "${SDK_BIN}" ]]; then
  echo "error: facerecognitionsdk binary missing after sync" >&2
  exit 1
fi

SIZE=$(/usr/bin/stat -f%z "${SDK_BIN}" 2>/dev/null || /usr/bin/stat -c%s "${SDK_BIN}")
# The LX wrapper is a few hundred KB; the old 3DiVi engine was tens of MB.
# Xcode's Swift link stub is about 50 KB and has a swbuild.tmp install name.
if [[ "${SIZE}" -lt 80000 ]]; then
  echo "error: facerecognitionsdk is ${SIZE} bytes (expected the native wrapper)" >&2
  /usr/bin/otool -L "${SDK_BIN}" 2>&1 | head -5 >&2 || true
  exit 1
fi
if /usr/bin/otool -L "${SDK_BIN}" 2>/dev/null | /usr/bin/grep -q swbuild.tmp; then
  echo "error: facerecognitionsdk is still an Xcode Swift stub (swbuild.tmp)" >&2
  exit 1
fi

if [[ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" && "${CODE_SIGNING_ALLOWED:-}" == "YES" ]]; then
  for fw in facerecognitionsdk FacePluginSDK FacePPlugin FaceDetect; do
    /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
      --preserve-metadata=identifier,entitlements,flags \
      --timestamp=none \
      "${DEST}/${fw}.framework" 2>/dev/null || true
  done
fi

echo "sync_embedded_frameworks: facerecognitionsdk ok (${SIZE} bytes)"
