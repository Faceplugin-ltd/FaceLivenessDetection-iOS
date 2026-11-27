#!/usr/bin/env python3
# Windows:  python run_ios.py          (prints that iOS needs a Mac)
# macOS:    python3 run_ios.py   or  ./run_ios.py
"""Build FaceLivenessDetectioniOS and install/launch on a physical iPhone without LLDB.

Xcode Run + wireless debugging often hangs (~6 min) then kills LLDB RPC Server
(IDEDebugSessionErrorDomain Code 28) when DeviceSupport has no dyld shared cache.
This script builds, installs, and launches with no debugger attach.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
IS_MAC = sys.platform == "darwin"
BUNDLE_ID = "com.faceplugin.faceliveness.app"
SCHEME = "FaceLivenessDetectioniOS"
PROJECT = ROOT / "FaceLivenessSDK.xcodeproj"
DERIVED = ROOT / "DerivedDataDevice"
APP = DERIVED / "Build" / "Products" / "Debug-iphoneos" / "FaceLivenessDetectioniOS.app"


def die(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def need(name: str, hint: str) -> str:
    path = shutil.which(name)
    if not path:
        die(f"{name} is not on PATH. {hint}")
    return path


def run(args: list[str], cwd: Path | None = None) -> None:
    print("+", " ".join(str(a) for a in args))
    r = subprocess.run(args, cwd=str(cwd or ROOT))
    if r.returncode:
        raise SystemExit(r.returncode)


def ios_udid() -> str:
    need("xcrun", "Install Xcode and its command-line tools.")
    raw = subprocess.check_output(
        ["xcrun", "xctrace", "list", "devices"],
        text=True,
        stderr=subprocess.STDOUT,
        errors="replace",
    )
    in_sims = False
    for line in raw.splitlines():
        lower = line.lower()
        if "simulator" in lower:
            in_sims = True
            continue
        if in_sims or "(" not in line or ")" not in line:
            continue
        if "mac" in lower or "watch" in lower or "apple tv" in lower:
            continue
        udid = line.rsplit("(", 1)[-1].strip().rstrip(")")
        token = udid.replace("-", "")
        if len(token) >= 16 and token.isalnum():
            print(f"iOS device: {line.strip()}")
            return udid
    die("no physical iPhone. Plug one in over USB and trust this computer.")
    raise SystemExit(1)


def warn_if_wireless(udid: str) -> None:
    try:
        out = subprocess.check_output(
            ["xcrun", "devicectl", "list", "devices", "--json-output", "-"],
            text=True,
            stderr=subprocess.DEVNULL,
            errors="replace",
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return
    # Prefer a quick transport check via details when json-output - fails on some Xcodes.
    try:
        details = subprocess.check_output(
            [
                "xcrun",
                "devicectl",
                "device",
                "info",
                "details",
                "--device",
                udid,
                "--timeout",
                "15",
            ],
            text=True,
            stderr=subprocess.STDOUT,
            errors="replace",
        )
    except subprocess.CalledProcessError:
        return
    if "localNetwork" in details or "transportType: localNetwork" in details:
        print(
            "WARNING: device is on Wi‑Fi only. Installs of this ~75MB app are slow or hang;\n"
            "         LLDB also cannot refresh the dyld shared cache. Plug in USB for a fast run.",
            file=sys.stderr,
        )
    _ = out


def main() -> None:
    if not IS_MAC:
        die("iOS builds need macOS and Xcode.")
    need("xcodebuild", "Install Xcode.")
    if not PROJECT.is_dir():
        die(f"missing {PROJECT}")
    udid = ios_udid()
    warn_if_wireless(udid)
    run(
        [
            "xcodebuild",
            "-project",
            str(PROJECT),
            "-scheme",
            SCHEME,
            "-configuration",
            "Debug",
            "-destination",
            f"id={udid}",
            "-derivedDataPath",
            str(DERIVED),
            "-allowProvisioningUpdates",
            "ENABLE_PREVIEWS=NO",
        ]
    )
    if not APP.is_dir():
        die(f"app bundle missing: {APP}")
    run(
        [
            "xcrun",
            "devicectl",
            "device",
            "install",
            "app",
            "--device",
            udid,
            "--timeout",
            "300",
            str(APP),
        ]
    )
    run(
        [
            "xcrun",
            "devicectl",
            "device",
            "process",
            "launch",
            "--terminate-existing",
            "--device",
            udid,
            BUNDLE_ID,
        ]
    )
    print(f"launched {BUNDLE_ID} (no LLDB attach)")


if __name__ == "__main__":
    main()
