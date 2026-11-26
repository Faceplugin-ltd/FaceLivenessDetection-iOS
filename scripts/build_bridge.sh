#!/bin/bash
# Build FaceLivenessBridge.xcframework (+ FaceLivenessKit.xcframework) for non-Swift hosts.
#
# The liveness screens in this project are Swift. .NET MAUI, Xamarin, Unity and anything else that
# binds a framework through its generated Objective-C header cannot see Swift-only API, so
# FaceLivenessBridge wraps it: see FaceLivenessBridge/Public/FaceLivenessBridge.swift. This script
# builds that framework, and the kit it links, as xcframeworks a host can embed.
#
#   ./scripts/build_bridge.sh [output-dir]
#
# Default output: build/xcframeworks/
#
# DEVICE ONLY. The vendor engine (facerecognitionsdk + the three xcframeworks it links) ships an
# ios-arm64 slice and nothing else, so there is no simulator build to produce — the same reason
# the app itself only runs on a physical phone.
#
# macOS with Xcode only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-${ROOT}/build/xcframeworks}"
DERIVED="${ROOT}/build/bridge-archives"
PROJECT="${ROOT}/FaceLivenessSDK.xcodeproj"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: this needs Xcode, so it only runs on macOS" >&2
  exit 1
fi

# --- the engine has to be in place first ------------------------------------------------------
missing=()
[[ -d "${ROOT}/facerecognitionsdk.framework" ]] || missing+=("facerecognitionsdk.framework")
for name in FacePluginSDK FacePlugin FaceDetect; do
  [[ -d "${ROOT}/${name}.xcframework" ]] || missing+=("${name}.xcframework")
done
if (( ${#missing[@]} )); then
  echo "error: missing engine framework(s) at the repository root:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  echo >&2
  echo "They are the same binaries this app embeds. Get them from the" >&2
  echo "Face-Recognition-LivenessDetection-iOS release and drop them beside FaceLivenessSDK.xcodeproj." >&2
  exit 1
fi

rm -rf "${DERIVED}"
mkdir -p "${OUT}"

echo "==> Archiving FaceLivenessBridge (ios-arm64)"
xcodebuild archive \
  -project "${PROJECT}" \
  -scheme FaceLivenessBridge \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "${DERIVED}/ios" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=NO \
  ONLY_ACTIVE_ARCH=NO \
  | tail -20

ARCHIVED="${DERIVED}/ios.xcarchive/Products/Library/Frameworks"
for name in FaceLivenessBridge FaceLivenessKit; do
  if [[ ! -d "${ARCHIVED}/${name}.framework" ]]; then
    echo "error: ${name}.framework is not in the archive at ${ARCHIVED}" >&2
    echo "       (check that the FaceLivenessBridge scheme builds the FaceLivenessKit dependency)" >&2
    exit 1
  fi
done

# The bridge's Objective-C face is the generated header; without it a host has nothing to bind.
HEADER="${ARCHIVED}/FaceLivenessBridge.framework/Headers/FaceLivenessBridge-Swift.h"
if [[ ! -f "${HEADER}" ]]; then
  echo "error: FaceLivenessBridge-Swift.h was not generated." >&2
  echo "       DEFINES_MODULE must be YES and the facade's members must be @objc." >&2
  exit 1
fi

for name in FaceLivenessBridge FaceLivenessKit; do
  echo "==> Packaging ${name}.xcframework"
  rm -rf "${OUT}/${name}.xcframework"
  xcodebuild -create-xcframework \
    -framework "${ARCHIVED}/${name}.framework" \
    -output "${OUT}/${name}.xcframework" \
    | tail -3
done

echo
echo "Built in ${OUT}:"
ls -1 "${OUT}"
echo
cat <<'NOTE'
A host embeds both of these, plus the four engine bundles from this repository's root:

  FaceLivenessBridge.xcframework      the Objective-C face of the liveness screens
  FaceLivenessKit.xcframework         the engine lifecycle the bridge calls
  facerecognitionsdk.framework        the engine (FacePlugin engine build)
  FacePluginSDK.xcframework           vendor runtime the engine links
  FacePlugin.xcframework              vendor runtime the engine links
  FaceDetect.xcframework              vendor detector the engine links

Objective-C / Swift hosts should use FaceLivenessKit and the screens directly instead; the bridge
exists only for hosts that cannot read a Swift interface.
NOTE
