#!/usr/bin/env python3
"""Report whether the public App Store already shows the Zoix names.

An empty result does not prove the name is free. An unpublished app record can
still reserve it. The upload lane learns that when it saves the name.
"""

import json
import urllib.request

NAMES = ("Zoix.ai", "Zoix.ai - Adaptive Philosophy", "Zoix")


def search(term):
    url = "https://itunes.apple.com/search?term=" + urllib.request.quote(term) + "&entity=software&limit=50"
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.load(response)


def lookup_bundle():
    url = "https://itunes.apple.com/lookup?bundleId=ai.zoix.app"
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.load(response)


def main():
    published = lookup_bundle()
    print(f"Published apps with bundle ID ai.zoix.app: {published.get('resultCount', 0)}")
    for name in NAMES:
        payload = search(name)
        exact = [
            item for item in payload.get("results", [])
            if (item.get("trackName") or "").casefold() == name.casefold()
        ]
        if exact:
            for item in exact:
                print(
                    f"Exact public name {name!r}: {item.get('trackName')} "
                    f"({item.get('bundleId')}, {item.get('artistName')})"
                )
        else:
            print(f"No published app has the exact name {name!r}.")
    print("Unpublished reservations are checked when the upload lane saves the name.")


if __name__ == "__main__":
    main()
