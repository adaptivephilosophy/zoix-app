#!/usr/bin/env python3
"""Check App Store metadata limits and the statements that must stay out of the listing."""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
META = ROOT / "fastlane" / "metadata"
EN = META / "en-US"

LIMITS = {
    "name.txt": 30,
    "subtitle.txt": 30,
    "promotional_text.txt": 170,
    "keywords.txt": 100,
    "description.txt": 4000,
    "release_notes.txt": 4000,
}

FORBIDDEN = ("501(c)(3)", "501c3", "tax-exempt", "tax exempt")


def text(path: Path) -> str:
    return path.read_text(encoding="utf-8").strip()


def main():
    errors = []
    for name, limit in LIMITS.items():
        path = EN / name
        if not path.is_file():
            errors.append(f"missing {path.relative_to(ROOT)}")
            continue
        value = text(path)
        if not value:
            errors.append(f"{name} is empty")
        if len(value) > limit:
            errors.append(f"{name} is {len(value)} characters; the limit is {limit}")
        else:
            print(f"{name}: {len(value)}/{limit}")

    if text(EN / "name.txt") not in ("Zoix.ai", "Zoix.ai - Adaptive Philosophy"):
        errors.append("name.txt must be Zoix.ai or the fallback")
    if text(META / "copyright.txt") != "2026 Adaptive Philosophy Foundation":
        errors.append("copyright.txt does not match the required copyright line")
    if text(META / "primary_category.txt") != "EDUCATION":
        errors.append("primary category must be EDUCATION")
    if text(META / "secondary_category.txt") != "NEWS":
        errors.append("secondary category must be NEWS")
    if text(EN / "marketing_url.txt") != "https://zoix.ai":
        errors.append("marketing URL must be https://zoix.ai")
    if text(EN / "privacy_url.txt") != "https://adaptivephilosophy.github.io/zoix-app/privacy.html":
        errors.append("privacy URL does not match the GitHub Pages page")
    if text(EN / "support_url.txt") != "https://adaptivephilosophy.github.io/zoix-app/support.html":
        errors.append("support URL does not match the GitHub Pages page")
    if (META / "review_information" / "phone_number.txt").exists():
        errors.append("review_information must not include a phone number")
    if text(META / "review_information" / "email_address.txt") != "DanBoice@adaptivephilosophy.foundation":
        errors.append("review email does not match the public contact address")

    rating = json.loads((META / "age_rating.json").read_text(encoding="utf-8"))
    if rating.get("unrestrictedWebAccess") is not True:
        errors.append("age rating must set unrestrictedWebAccess to true")
    for key in (
        "alcoholTobaccoOrDrugUseOrReferences",
        "matureOrSuggestiveThemes",
        "medicalOrTreatmentInformation",
    ):
        if rating.get(key) != "INFREQUENT_OR_MILD":
            errors.append(f"age rating {key} must be INFREQUENT_OR_MILD")

    project = (ROOT / "Zoix.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")
    if project.count("INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;") != 2:
        errors.append("both app build configurations must set ITSAppUsesNonExemptEncryption to NO")
    if 'TARGETED_DEVICE_FAMILY = "1,2";' not in project:
        errors.append("the app must keep iPhone and iPad support")

    scanned = []
    scanned.extend(META.rglob("*.txt"))
    scanned.extend(META.rglob("*.json"))
    scanned.extend((ROOT / "docs").glob("*.html"))
    for path in scanned:
        body = path.read_text(encoding="utf-8")
        for phrase in FORBIDDEN:
            if phrase.lower() in body.lower():
                errors.append(f"{path.relative_to(ROOT)} contains {phrase}")

    support = (ROOT / "docs" / "support.html").read_text(encoding="utf-8")
    if "DanBoice@adaptivephilosophy.foundation" not in support:
        errors.append("support page is missing the public contact email")
    if "https://github.com/adaptivephilosophy/zoix-app/issues" not in support:
        errors.append("support page is missing the GitHub issues link")

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        sys.exit(1)
    print("Metadata checks passed.")


if __name__ == "__main__":
    main()
