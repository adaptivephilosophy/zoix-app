#!/usr/bin/env python3
"""Write ExportOptions.plist for an automatic App Store export.

Reads APPLE_TEAM_ID and RUNNER_TEMP. Does not print secrets.
"""

import os
import re
import sys


def main():
    team = os.environ.get("APPLE_TEAM_ID", "").strip()
    temp = os.environ.get("RUNNER_TEMP", "")
    if not re.fullmatch(r"[A-Za-z0-9]{10}", team):
        sys.exit("APPLE_TEAM_ID must be 10 letters or digits.")
    if not temp:
        sys.exit("RUNNER_TEMP is not set.")
    plist = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>destination</key>
	<string>export</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>teamID</key>
	<string>{team}</string>
	<key>uploadSymbols</key>
	<true/>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
</dict>
</plist>
"""
    path = os.path.join(temp, "ExportOptions.plist")
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(plist)
    print("Wrote export options for automatic App Store signing.")


if __name__ == "__main__":
    main()
