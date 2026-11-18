#!/usr/bin/env bash
# Build Zoix and capture the three tabs on the simulators App Store Connect needs.
# Writes screenshots/en-US/<slot>-<tab>.png. Does not sign the app.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEST="${ROOT}/screenshots/en-US"
mkdir -p "$DEST"
rm -f "$DEST"/*.png

SIMS="$(mktemp)"
python3 scripts/screenshot_devices.py select > "$SIMS"

DERIVED="${RUNNER_TEMP:-/tmp}/ZoixScreenshotDerived"
RESULTS="${RUNNER_TEMP:-/tmp}/ZoixScreenshotResults"
mkdir -p "$DERIVED" "$RESULTS"

python3 - "$SIMS" "$DEST" "$DERIVED" "$RESULTS" << 'PY'
import json
import os
import subprocess
import sys
from pathlib import Path

sims_path, dest, derived, results = sys.argv[1:]
devices = json.loads(Path(sims_path).read_text())
root = Path.cwd()

def run(command, env=None, check=True):
    print("+", " ".join(command), flush=True)
    merged = os.environ.copy()
    if env:
        merged.update(env)
    return subprocess.run(command, check=check, env=merged)

for device in devices:
    udid = device["udid"]
    slot = device["slot"]
    print(f"\n== {slot}: {device['name']} ==", flush=True)
    run(["xcrun", "simctl", "boot", udid], check=False)
    run(["xcrun", "simctl", "bootstatus", udid, "-b"])
    run(["xcrun", "simctl", "ui", udid, "appearance", "dark"], check=False)
    status = [
        "xcrun", "simctl", "status_bar", udid, "override",
        "--time", "9:41",
        "--batteryState", "charged",
        "--batteryLevel", "100",
        "--wifiMode", "active",
        "--wifiBars", "3",
        "--cellularMode", "active",
        "--cellularBars", "4",
    ]
    if run(status, check=False).returncode != 0:
        run(status[:-4], check=False)

    shot_dir = Path(results) / slot
    shot_dir.mkdir(parents=True, exist_ok=True)
    for stale in shot_dir.glob("*.png"):
        stale.unlink()

    device_root = Path.home() / "Library/Developer/CoreSimulator/Devices" / udid / "data" / "Containers"
    if device_root.is_dir():
        for stale in device_root.glob("**/ZoixStoreScreenshots/*.png"):
            stale.unlink()

    bundle = Path(results) / f"{slot}.xcresult"
    if bundle.exists():
        subprocess.run(["rm", "-rf", str(bundle)], check=False)

    env = {"TEST_RUNNER_ZOIX_SCREENSHOT_DIR": str(shot_dir)}
    run(
        [
            "xcodebuild", "test",
            "-project", "Zoix.xcodeproj",
            "-scheme", "ZoixScreenshots",
            "-destination", f"platform=iOS Simulator,id={udid},arch=arm64",
            "-configuration", "Debug",
            "-derivedDataPath", derived,
            "-resultBundlePath", str(bundle),
            "-only-testing:ZoixScreenshots/StoreScreenshotTests/testCaptureStoreTabs",
            "-parallel-testing-enabled", "NO",
            "CODE_SIGNING_ALLOWED=NO",
            "CODE_SIGNING_REQUIRED=NO",
            "CODE_SIGN_IDENTITY=-",
        ],
        env=env,
    )
    names = ("01-home.png", "02-updates.png", "03-mot-du-jour.png")
    for name in names:
        host_copy = shot_dir / name
        if host_copy.is_file():
            source = host_copy
        else:
            matches = list(device_root.glob(f"**/ZoixStoreScreenshots/{name}")) if device_root.is_dir() else []
            if not matches:
                sys.exit(f"{slot} did not write {name}")
            source = max(matches, key=lambda path: path.stat().st_mtime)
        target = Path(dest) / f"{slot}-{name}"
        target.write_bytes(source.read_bytes())
        print(f"Saved {target.relative_to(root)} from {source}")
    run(["xcrun", "simctl", "shutdown", udid], check=False)

print(f"\nCaptures are in {dest}")
PY

python3 scripts/screenshot_devices.py check "$DEST"
