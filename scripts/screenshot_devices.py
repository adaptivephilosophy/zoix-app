#!/usr/bin/env python3
"""Choose screenshot simulators, or check that captured PNGs match App Store sizes.

Apple's screenshot specification, checked 18 November 2026, requires an iPhone
with Dynamic Island (medium display) and, because this app runs on iPad, a
13-inch iPad. The 6.9-inch sizes are the large Dynamic Island display. fastlane
maps those pixels onto the App Store slots.
"""

import json
import subprocess
import sys
from pathlib import Path

LARGE_NAMES = [
    "iPhone 18 Pro Max",
    "iPhone 17 Pro Max",
    "iPhone 16 Pro Max",
    "iPhone Air",
    "iPhone 16 Plus",
    "iPhone 15 Pro Max",
    "iPhone 15 Plus",
    "iPhone 14 Pro Max",
]
MEDIUM_NAMES = [
    "iPhone 18 Pro",
    "iPhone 17 Pro",
    "iPhone 16 Pro",
    "iPhone 17",
    "iPhone 16",
    "iPhone 15 Pro",
    "iPhone 15",
    "iPhone 14 Pro",
]
IPAD_NAMES = [
    "iPad Pro 13-inch (M5)",
    "iPad Pro 13-inch (M4)",
    "iPad Pro (13-inch) (M5)",
    "iPad Pro (13-inch) (M4)",
    "iPad Pro 13-inch",
    "iPad Air 13-inch (M4)",
    "iPad Air 13-inch (M3)",
    "iPad Air 13-inch (M2)",
    "iPad Air 13-inch",
]

ACCEPTED = {
    "iphone-6.9": [(1320, 2868), (1290, 2796), (1260, 2736)],
    "iphone-medium": [(1206, 2622), (1179, 2556)],
    "ipad-13": [(2064, 2752), (2048, 2732)],
}
SLUGS = ("01-home", "02-updates", "03-mot-du-jour")


def available_devices():
    raw = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"])
    data = json.loads(raw)
    found = []
    for runtime, devices in data.get("devices", {}).items():
        if "iOS" not in runtime:
            continue
        for device in devices:
            if device.get("isAvailable") and device.get("udid") and device.get("name"):
                found.append((runtime, device["name"], device["udid"]))
    return found


def pick(found, names):
    for name in names:
        matches = [item for item in found if item[1] == name]
        if matches:
            runtime, picked, udid = max(matches, key=lambda item: item[0])
            return {"name": picked, "udid": udid, "runtime": runtime}
    return None


def select():
    found = available_devices()
    chosen = []
    missing = []
    for slot, names in (
        ("iphone-6.9", LARGE_NAMES),
        ("iphone-medium", MEDIUM_NAMES),
        ("ipad-13", IPAD_NAMES),
    ):
        match = pick(found, names)
        if match is None:
            missing.append(slot)
        else:
            match["slot"] = slot
            chosen.append(match)
    if missing:
        print("No simulator for: " + ", ".join(missing), file=sys.stderr)
        print("Available devices:", file=sys.stderr)
        for runtime, name, udid in sorted(found):
            print(f"  {name}  {runtime}  {udid}", file=sys.stderr)
        sys.exit(1)
    json.dump(chosen, sys.stdout, indent=2)
    sys.stdout.write("\n")
    for item in chosen:
        print(f"Selected {item['slot']}: {item['name']} on {item['runtime']}", file=sys.stderr)


def png_info(path: Path):
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"{path.name} is not a PNG")
    if data[12:16] != b"IHDR":
        raise SystemExit(f"{path.name} has no IHDR")
    width = int.from_bytes(data[16:20], "big")
    height = int.from_bytes(data[20:24], "big")
    color = data[25]
    return width, height, color


def check(directory: Path):
    errors = []
    for slot, sizes in ACCEPTED.items():
        for slug in SLUGS:
            path = directory / f"{slot}-{slug}.png"
            if not path.is_file():
                errors.append(f"missing {path.name}")
                continue
            width, height, color = png_info(path)
            if (width, height) not in sizes:
                allowed = ", ".join(f"{w}x{h}" for w, h in sizes)
                errors.append(f"{path.name} is {width}x{height}; allowed {allowed}")
            if color in (4, 6):
                errors.append(f"{path.name} has an alpha channel (color type {color})")
            else:
                print(f"{path.name} {width}x{height} color-type {color}")
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        sys.exit(1)


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("select", "check"):
        sys.exit("usage: screenshot_devices.py select | check <directory>")
    if sys.argv[1] == "select":
        select()
        return
    if len(sys.argv) != 3:
        sys.exit("usage: screenshot_devices.py check <directory>")
    check(Path(sys.argv[2]))


if __name__ == "__main__":
    main()
