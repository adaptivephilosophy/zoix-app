#!/usr/bin/env python3
"""Pick an available iPhone 17 simulator and write its UDID to GITHUB_OUTPUT."""

import json
import os
import subprocess
import sys


def main():
    raw = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"])
    data = json.loads(raw)
    best = None
    for runtime, devices in data.get("devices", {}).items():
        if "iOS" not in runtime:
            continue
        for device in devices:
            if device.get("isAvailable") and device.get("name") == "iPhone 17" and device.get("udid"):
                if best is None or runtime > best[0]:
                    best = (runtime, device["udid"], device["name"])
    if best is None:
        sys.exit("No available iPhone 17 simulator on this runner.")
    print(f"Selected {best[2]} on {best[0]}")
    output = os.environ.get("GITHUB_OUTPUT")
    line = f"udid={best[1]}\n"
    if output:
        with open(output, "a", encoding="utf-8") as handle:
            handle.write(line)
    else:
        sys.stdout.write(line)


if __name__ == "__main__":
    main()
