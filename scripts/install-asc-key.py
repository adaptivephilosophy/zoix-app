#!/usr/bin/env python3
"""Write the App Store Connect API key where xcodebuild and altool look for it.

Reads ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8, and RUNNER_TEMP from the environment.
Never prints the key. If the secret was stored as one line with escaped newlines,
those escapes are turned into real line breaks before the PEM check.
"""

import os
import re
import sys
from pathlib import Path


def main():
    key_id = os.environ.get("ASC_KEY_ID", "")
    issuer = os.environ.get("ASC_ISSUER_ID", "")
    raw = os.environ.get("ASC_KEY_P8", "")
    temp = os.environ.get("RUNNER_TEMP", "")
    if not key_id or not issuer or not raw or not temp:
        sys.exit("ASC_KEY_ID, ASC_ISSUER_ID, and ASC_KEY_P8 must all be set. The key text is not printed.")
    if not re.fullmatch(r"[A-Za-z0-9]+", key_id):
        sys.exit("ASC_KEY_ID is not a usable key id. The value was not printed.")

    text = raw.replace("\r\n", "\n").replace("\r", "\n")
    if "\n" not in text and "\\n" in text:
        text = text.replace("\\n", "\n")
    if not text.endswith("\n"):
        text += "\n"
    if "PRIVATE KEY" not in text:
        sys.exit(
            "ASC_KEY_P8 does not look like a PEM private key. "
            "Paste the full .p8 text, including the BEGIN and END lines. The value was not printed."
        )

    directory = Path(temp) / "private_keys"
    directory.mkdir(parents=True, exist_ok=True)
    os.chmod(directory, 0o700)
    path = directory / f"AuthKey_{key_id}.p8"
    path.write_text(text, encoding="utf-8")
    os.chmod(path, 0o600)

    github_env = os.environ.get("GITHUB_ENV")
    if github_env:
        with open(github_env, "a", encoding="utf-8") as handle:
            handle.write(f"API_PRIVATE_KEYS_DIR={directory}\n")
            handle.write(f"ASC_KEY_PATH={path}\n")
    print("Wrote the API key into the runner temp directory.")


if __name__ == "__main__":
    main()
