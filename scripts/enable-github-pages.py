#!/usr/bin/env python3
"""Turn on GitHub Pages for docs/ on main, if this token is allowed to.

Prints the HTTP status only. Never prints the token or the remote URL.
Exits 0 even when Pages cannot be enabled, so a metadata upload can continue.
"""

import json
import os
import subprocess
import urllib.error
import urllib.request

REPO = "adaptivephilosophy/zoix-app"
PAGES = f"https://adaptivephilosophy.github.io/zoix-app/"


def token():
    value = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if value:
        return value
    url = subprocess.check_output(["git", "remote", "get-url", "origin"], text=True).strip()
    marker = "x-access-token:"
    if marker not in url or "@" not in url:
        return None
    return url.split(marker, 1)[1].split("@", 1)[0]


def request(method, path, body=None, credential=None):
    data = None if body is None else json.dumps(body).encode("utf-8")
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "zoix-pages",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if credential:
        headers["Authorization"] = f"Bearer {credential}"
    if data is not None:
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(f"https://api.github.com{path}", data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            raw = response.read().decode("utf-8")
            return response.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        raw = error.read().decode("utf-8", "replace")
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError:
            payload = {"message": "unreadable response"}
        return error.code, payload


def main():
    credential = token()
    if not credential:
        print("GitHub Pages was not changed: no token is available to this step.")
        print(f"Turn it on by hand, then open {PAGES}")
        return

    status, payload = request("GET", f"/repos/{REPO}/pages", credential=credential)
    if status == 200:
        print(f"GitHub Pages is already configured ({payload.get('html_url') or PAGES}).")
        print(f"Build type: {payload.get('build_type')}. Status: {payload.get('status')}.")
        return

    created, payload = request(
        "POST",
        f"/repos/{REPO}/pages",
        {
            "build_type": "legacy",
            "source": {"branch": "main", "path": "/docs"},
        },
        credential,
    )
    message = payload.get("message") or payload.get("html_url") or ""
    print(f"GitHub Pages create response: {created}. {message}")
    if created in (200, 201):
        print(f"Pages will serve {PAGES}privacy.html and {PAGES}support.html from docs/ on main.")
        return
    if created == 409:
        print("GitHub Pages already exists.")
        return
    print("This token cannot enable GitHub Pages.")
    print("In the repository: Settings → Pages → Deploy from a branch → main → /docs → Save.")
    print(f"The public URLs are then {PAGES}privacy.html and {PAGES}support.html.")


if __name__ == "__main__":
    main()
