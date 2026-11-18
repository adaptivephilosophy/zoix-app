#!/usr/bin/env bash
# Capture the three tabs on each required simulator.
# Sample data is inside the app, so this does not wait on zoix.ai.
# A failed capture leaves any already valid screenshots in screenshots/en-US.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEST="${ROOT}/screenshots/en-US"
mkdir -p "$DEST"

SIMS="$(mktemp)"
python3 scripts/screenshot_devices.py select > "$SIMS"

DERIVED="${RUNNER_TEMP:-/tmp}/ZoixScreenshotDerived"
RESULTS="${RUNNER_TEMP:-/tmp}/ZoixScreenshotResults"
mkdir -p "$DERIVED" "$RESULTS"

python3 - "$SIMS" "$DEST" "$DERIVED" "$RESULTS" << 'PY'
import json
import os
import shutil
import subprocess
import sys
import threading
import time
from pathlib import Path

sims_path, dest, derived, results = sys.argv[1:]
devices = json.loads(Path(sims_path).read_text())
dest = Path(dest)
results = Path(results)
staging = results / "staged"
staging.mkdir(parents=True, exist_ok=True)
root = Path.cwd()
names = ("01-home.png", "02-updates.png", "03-mot-du-jour.png")

def run(command, env=None, check=True):
    print("+", " ".join(command), flush=True)
    merged = os.environ.copy()
    if env:
        merged.update(env)
    return subprocess.run(command, check=check, env=merged)

def png_color(path: Path):
    data = path.read_bytes()
    if len(data) < 26 or data[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return data[25]

def flatten(path: Path):
    if png_color(path) not in (4, 6):
        return
    bmp = path.with_suffix(".bmp")
    subprocess.run(["sips", "-s", "format", "bmp", str(path), "--out", str(bmp)], check=False)
    if bmp.is_file():
        subprocess.run(["sips", "-s", "format", "png", str(bmp), "--out", str(path)], check=False)
        bmp.unlink(missing_ok=True)

def container_root(udid):
    return Path.home() / "Library/Developer/CoreSimulator/Devices" / udid / "data" / "Containers"

def clear_flags(udid):
    root_dir = container_root(udid)
    if not root_dir.is_dir():
        return
    for flag in root_dir.glob("**/ZoixStoreScreenshots/*.flag"):
        flag.unlink()

def watch(udid, slot, stop, seen):
    while not stop.is_set():
        root_dir = container_root(udid)
        if root_dir.is_dir():
            for marker in root_dir.glob("**/ZoixStoreScreenshots/ready-*.flag"):
                if marker.name in seen:
                    continue
                tab = marker.name[len("ready-"):-len(".flag")]
                out = staging / f"{slot}-{tab}.png"
                proc = subprocess.run(
                    ["xcrun", "simctl", "io", udid, "screenshot", str(out)],
                    check=False,
                )
                if proc.returncode == 0 and out.is_file() and out.stat().st_size > 1000:
                    flatten(out)
                    (marker.parent / f"done-{tab}.flag").write_bytes(b"ok")
                    seen.add(marker.name)
                    print(f"Photographed {out.name}", flush=True)
        time.sleep(0.4)

def test_device(udid, slot, suffix):
    bundle = results / f"{slot}{suffix}.xcresult"
    if bundle.exists():
        shutil.rmtree(bundle, ignore_errors=True)
    shot_dir = results / slot
    shot_dir.mkdir(parents=True, exist_ok=True)
    env = {"TEST_RUNNER_ZOIX_SCREENSHOT_DIR": str(shot_dir)}
    completed = run(
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
        check=False,
    )
    return completed.returncode == 0

def collect_from_cache(udid, slot):
    root_dir = container_root(udid)
    if not root_dir.is_dir():
        return
    for name in names:
        target = staging / f"{slot}-{name}"
        if target.is_file():
            continue
        matches = list(root_dir.glob(f"**/ZoixStoreScreenshots/{name}"))
        if not matches:
            continue
        source = max(matches, key=lambda path: path.stat().st_mtime)
        shutil.copyfile(source, target)
        flatten(target)
        print(f"Copied {target.name} from the simulator cache")

failures = []
for device in devices:
    udid = device["udid"]
    slot = device["slot"]
    print(f"\n== {slot}: {device['name']} ==", flush=True)
    run(["xcrun", "simctl", "boot", udid], check=False)
    run(["xcrun", "simctl", "bootstatus", udid, "-b"])
    run(["xcrun", "simctl", "ui", udid, "appearance", "dark"], check=False)
    run(["xcrun", "simctl", "launch", udid, "com.apple.springboard"], check=False)
    time.sleep(8)
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

    stop = threading.Event()
    seen = set()
    thread = threading.Thread(target=watch, args=(udid, slot, stop, seen), daemon=True)
    thread.start()
    try:
        clear_flags(udid)
        ok = test_device(udid, slot, "")
        if not ok:
            print(f"{slot} failed once. Retrying on the warm simulator.", flush=True)
            clear_flags(udid)
            ok = test_device(udid, slot, "-retry")
    finally:
        stop.set()
        thread.join(timeout=5)
    collect_from_cache(udid, slot)
    missing = [name for name in names if not (staging / f"{slot}-{name}").is_file()]
    if missing:
        failures.append(f"{slot} ({device['name']}): missing {', '.join(missing)}")
    run(["xcrun", "simctl", "shutdown", udid], check=False)

if not failures:
    check = subprocess.run([sys.executable, "scripts/screenshot_devices.py", "check", str(staging)])
    if check.returncode == 0:
        for path in staging.glob("*.png"):
            shutil.copyfile(path, dest / path.name)
        print(f"Captures are in {dest}")
        sys.exit(0)
    failures.append("captured files do not match App Store sizes")

print("Capture did not produce a full set:", file=sys.stderr)
for item in failures:
    print(f"  {item}", file=sys.stderr)

kept = subprocess.run([sys.executable, "scripts/screenshot_devices.py", "check", str(dest)])
if kept.returncode == 0:
    print("Using the screenshots already in screenshots/en-US.")
    sys.exit(0)

print("No valid screenshots are available to upload.", file=sys.stderr)
sys.exit(1)
PY
