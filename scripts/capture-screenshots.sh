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
    """simctl screenshots are RGBA. App Store Connect rejects the alpha channel.

    JPEG has no alpha, so the round trip is what actually clears color type 6.
    The BMP round trip used before left the original PNG in place.
    """
    if not path.is_file():
        raise RuntimeError(f"Cannot strip alpha: {path} was not written.")
    color = png_color(path)
    if color not in (4, 6):
        print(f"{path.name} already has no alpha (color type {color})", flush=True)
        return
    jpg = path.with_suffix(".jpg")
    to_jpeg = subprocess.run(
        ["sips", "-s", "format", "jpeg", "-s", "formatOptions", "100", str(path), "--out", str(jpg)],
        capture_output=True, text=True,
    )
    if to_jpeg.returncode != 0 or not jpg.is_file():
        detail = (to_jpeg.stderr or to_jpeg.stdout or "sips produced no file").strip()
        raise RuntimeError(f"Alpha strip failed while converting {path.name} to JPEG: {detail}")
    to_png = subprocess.run(
        ["sips", "-s", "format", "png", str(jpg), "--out", str(path)],
        capture_output=True, text=True,
    )
    jpg.unlink(missing_ok=True)
    if to_png.returncode != 0 or not path.is_file():
        detail = (to_png.stderr or to_png.stdout or "sips produced no file").strip()
        raise RuntimeError(f"Alpha strip failed while converting {path.name} back to PNG: {detail}")
    after = png_color(path)
    if after in (4, 6) or after is None:
        raise RuntimeError(f"Alpha remained on {path} (color type {after}, {path.stat().st_size} bytes).")
    print(f"Stripped alpha from {path.name}; color type {color} -> {after}", flush=True)

def container_root(udid):
    return Path.home() / "Library/Developer/CoreSimulator/Devices" / udid / "data" / "Containers"

def clear_flags(udid):
    root_dir = container_root(udid)
    if not root_dir.is_dir():
        return
    for flag in root_dir.glob("**/ZoixStoreScreenshots/*.flag"):
        flag.unlink()

def watch(udid, slot, stop, seen, errors):
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
                if proc.returncode != 0 or not out.is_file() or out.stat().st_size <= 1000:
                    print(
                        f"simctl io screenshot did not write {out.name} "
                        f"(exit {proc.returncode}, exists {out.is_file()})",
                        flush=True,
                    )
                    continue
                try:
                    flatten(out)
                except RuntimeError as error:
                    errors.append(str(error))
                    print(error, flush=True)
                    continue
                (marker.parent / f"done-{tab}.flag").write_bytes(b"ok")
                seen.add(marker.name)
                print(
                    f"Photographed {out} ({out.stat().st_size} bytes, color type {png_color(out)})",
                    flush=True,
                )
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
        print(f"Copied opaque screenshot {target.name} from the simulator cache", flush=True)

def export_attachments(bundle: Path, slot: str):
    """Pull XCTAttachment PNGs out of the xcresult. Names follow the test's attachment name."""
    if not bundle.is_dir():
        print(f"No xcresult at {bundle}; skipping attachment export.", flush=True)
        return []
    out = results / f"{slot}-attachments"
    if out.exists():
        shutil.rmtree(out)
    out.mkdir()
    attempts = [
        ["xcrun", "xcresulttool", "export", "attachments", "--path", str(bundle), "--output-path", str(out)],
        ["xcrun", "xcresulttool", "--legacy", "export", "attachments", "--path", str(bundle), "--output-path", str(out)],
    ]
    for command in attempts:
        proc = subprocess.run(command, capture_output=True, text=True)
        pngs = list(out.rglob("*.png"))
        print(
            f"{' '.join(command[:4])}: exit {proc.returncode}, {len(pngs)} png attachment(s)",
            flush=True,
        )
        if proc.returncode != 0:
            detail = (proc.stderr or proc.stdout or "").strip().splitlines()
            if detail:
                print(f"  {detail[-1]}", flush=True)
        if pngs:
            return pngs
    print(f"xcresulttool exported no PNGs from {bundle}.", flush=True)
    return []

def adopt_attachment(slot: str, png: Path):
    stem = png.stem
    for name in names:
        if stem == name[:-4] or name[:-4] in stem:
            target = staging / f"{slot}-{name}"
            shutil.copyfile(png, target)
            flatten(target)
            print(f"Using attachment {png.name} as {target.name}", flush=True)
            return
    print(f"Attachment {png} did not match a tab name; left unused.", flush=True)

def diagnose(directory: Path):
    print(f"PNG files in {directory}:", flush=True)
    if not directory.is_dir():
        print("  directory does not exist", flush=True)
        return
    files = sorted(directory.glob("*.png"))
    if not files:
        print("  none", flush=True)
        return
    for path in files:
        print(f"  {path.name} {path.stat().st_size} bytes color-type {png_color(path)}", flush=True)

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
    errors = []
    thread = threading.Thread(target=watch, args=(udid, slot, stop, seen, errors), daemon=True)
    thread.start()
    try:
        clear_flags(udid)
        bundle = results / f"{slot}.xcresult"
        ok = test_device(udid, slot, "")
        have = all((staging / f"{slot}-{name}").is_file() for name in names)
        if not ok and not have:
            print(f"{slot} failed before any screenshot was saved. Retrying.", flush=True)
            clear_flags(udid)
            ok = test_device(udid, slot, "-retry")
            bundle = results / f"{slot}-retry.xcresult"
        elif not ok:
            print(f"{slot} test reported a failure after screenshots were saved. Keeping those files.", flush=True)
    finally:
        stop.set()
        thread.join(timeout=5)
    for message in errors:
        failures.append(f"{slot}: {message}")
    for png in export_attachments(bundle, slot):
        try:
            adopt_attachment(slot, png)
        except RuntimeError as error:
            failures.append(f"{slot}: {error}")
    try:
        collect_from_cache(udid, slot)
    except RuntimeError as error:
        failures.append(f"{slot}: {error}")
    missing = [name for name in names if not (staging / f"{slot}-{name}").is_file()]
    if missing:
        diagnose(staging)
        failures.append(f"{slot} ({device['name']}): simctl and xcresult export did not produce {', '.join(missing)}")
    run(["xcrun", "simctl", "shutdown", udid], check=False)

expected = [f"{device['slot']}-{name}" for device in devices for name in names]
if not failures:
    print("Checking staged screenshot sizes.", flush=True)
    diagnose(staging)
    check = subprocess.run([sys.executable, "scripts/screenshot_devices.py", "check", str(staging)])
    if check.returncode != 0:
        sys.exit(f"Size check rejected files in {staging}. They were not copied to {dest}.")
    for name in expected:
        source = staging / name
        if not source.is_file():
            sys.exit(f"Copy aborted: {source} disappeared between capture and copy.")
        shutil.copyfile(source, dest / name)
    missing_after_copy = [name for name in expected if not (dest / name).is_file()]
    if missing_after_copy:
        sys.exit(f"Copy to {dest} dropped {', '.join(missing_after_copy)}.")
    print(f"Wrote {len(expected)} screenshots to {dest}")
    sys.exit(0)

print("Capture did not produce a full set:", file=sys.stderr)
for item in failures:
    print(f"  {item}", file=sys.stderr)
diagnose(staging)
print(f"Committed directory {dest} was left unchanged.", file=sys.stderr)
kept = subprocess.run([sys.executable, "scripts/screenshot_devices.py", "check", str(dest)])
if kept.returncode == 0:
    print("Using the screenshots already in screenshots/en-US.")
    sys.exit(0)
sys.exit(f"No valid screenshots in {staging} or {dest}.")
PY
