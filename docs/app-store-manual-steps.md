# App Store steps the API cannot finish

**Français :** Cette liste est la liste de contrôle pour Daniel. Le workflow [App Store metadata](../.github/workflows/appstore.yml) envoie les textes, les captures, la classification d'âge, et joint le build traité. Il ne soumet pas la revue tant que `submit` n'est pas coché. Les points ci-dessous restent dans le site App Store Connect, ou dans les réglages GitHub.

**English:** The [App Store metadata](../.github/workflows/appstore.yml) workflow uploads the listing text, the screenshots, and the age-rating answers, and it attaches the latest processed build. It does not submit for review unless `submit` is turned on. The steps below stay in the App Store Connect website, or in the GitHub repository settings.

Checked 18 November 2026 against the app source, https://zoix.ai, and the public article feed.

## What the workflow already sends

- Store name `Zoix.ai`. If Apple says that name is taken, the lane saves `Zoix.ai - Adaptive Philosophy` (29 characters).
- Subtitle, promotional text, description, keywords, What's New, support URL, marketing URL `https://zoix.ai`, privacy URL, and copyright `2026 Adaptive Philosophy Foundation`.
- Primary category Education. Secondary category News.
- Age-rating answers in `fastlane/metadata/age_rating.json`.
- Screenshots for the 6.9-inch iPhone, the medium Dynamic Island iPhone, and the 13-inch iPad.
- The latest processed build whose train is 1.0.0, when one exists.
- Content rights set to third-party content, because Mot du jour reads Transparent Language's public widget feed.
- Review contact name and email. There is no phone number in the repo.

`ITSAppUsesNonExemptEncryption` is already `NO` on both the Debug and Release app configurations. The app uses only standard HTTPS. A separate Info.plist file is not used; Xcode generates the key.

## 1. Turn on GitHub Pages

The privacy and support pages are `docs/privacy.html` and `docs/support.html`. They are not public until Pages is on. The repository is public, so the support page links to GitHub issues.

Settings → Pages → Build and deployment → Source: Deploy from a branch → Branch: `main`, folder: `/docs` → Save.

The URLs are then:

- https://adaptivephilosophy.github.io/zoix-app/privacy.html
- https://adaptivephilosophy.github.io/zoix-app/support.html

Open both before submit. The in-app Privacy policy button uses the first URL. The workflow tries to enable Pages and records the HTTP status. A 403 means this token cannot change the setting.

## 2. Confirm the app record

TestFlight uploads already use bundle ID `ai.zoix.app`, so the record should exist. If the upload lane stops because it cannot find that bundle ID, create the record: bundle ID `ai.zoix.app`, SKU `zoix-ios`, primary language English (U.S.). The public name is set by the lane, not by that form.

The public iTunes Search API, checked 18 November 2026, shows no published app with the exact name Zoix.ai, Zoix, or Zoix.ai - Adaptive Philosophy, and no published app with this bundle ID. An unpublished record can still reserve a name. The lane learns that when it saves the name.

## 3. Agreements

Accept the Free Apps agreement under Agreements, Tax, and Banking if it is not already accepted. The Paid Apps agreement is not required: the app is free and has no in-app purchase.

Do not describe the foundation as a 501(c)(3) or as tax-exempt. The listing calls it a Washington nonprofit corporation.

## 4. Pricing and availability

This lane does not change price or countries. In App Store Connect, set the price to Free and choose the territories. New apps are often free in all territories already. Confirm that before submit.

## 5. App Privacy

Answer **Data Not Collected**, then publish the answers. The nutrition-label screen is still a website step. The privacy manifest in the app already says the same thing: no tracking, no collected data types, and no required-reason API.

Recommended answers, from the code as of 18 November 2026:

| Question | Answer |
| --- | --- |
| Do you or your third-party partners collect data from this app? | No. Data Not Collected. |
| Tracking | No. There is no advertising identifier, no tracking domain, and no analytics kit. |
| Contact info, health, financial info, location, contacts, user content, browsing history, search history, identifiers, purchases, usage data, diagnostics | Do not declare any of these. |
| Linked to the user | Not collected. |
| Used to track the user | Not collected. |

What the app actually does:

- No account, no login, and no analytics, advertising, or crash SDK.
- Home loads https://zoix.ai in a web view. The app adds no identifier. On 18 November 2026 the homepage HTML had no analytics or tag-manager script, and the response set no cookie.
- Updates requests https://ap-notion-articles.vercel.app/api/articles with the shared URL session and no auth header. That response set no cookie.
- Mot du jour requests https://wotd.transparent.com/rss/fr-widget.xml and sends only the User-Agent `Zoix/1.0 (iOS)`.
- The last article list and the last word are stored in the app's cache directory on the device. They are not uploaded.
- Donate, the privacy link, and mailto open in Safari, outside the app. Card numbers and payments never enter Zoix.

Those servers still see the device's IP address as part of ordinary HTTPS. Apple does not treat that as collected data when the developer does not store it as an identifier. If zoix.ai, the article host, or Transparent Language later adds analytics, or if the foundation starts logging identifiers, these answers have to change before the next release. The web view loads the foundation's own site, so analytics added to zoix.ai would count.

## 6. Age rating

The lane uploads `fastlane/metadata/age_rating.json`. Review the answers before submit. The calculated rating is **not 4+**.

Apple's current definitions (checked 18 November 2026) put unrestricted web access at 16+. Devices on the older scale show that capability as 17+.

| Question | Answer | Why |
| --- | --- | --- |
| Cartoon or fantasy violence | None | |
| Realistic violence | None | |
| Prolonged graphic or sadistic realistic violence | None | |
| Profanity or crude humor | None | |
| Horror or fear themes | None | |
| Mature or suggestive themes | Infrequent / Mild | The public reading list includes academic titles about trauma, abuse, and sexual topics. They are citations, not depictions. |
| Medical or treatment information | Infrequent / Mild | Some reading-list titles name psychotherapy, hypnosis, and clinical subjects. The app does not diagnose or give treatment advice. |
| Health or wellness topics | No | The app does not give diet, exercise, or self-care instructions. |
| Alcohol, tobacco, or drug use or references | Infrequent / Mild | At least one reading-list title refers to drugs. The app does not depict use. |
| Sexual content or nudity | None | Titles are not depictions. |
| Graphic sexual content and nudity | None | |
| Guns or other weapons | None | |
| Gambling, simulated gambling, contests, loot boxes | None / No | |
| Unrestricted web access | Yes | Home follows any https link that is not a payment link, including Notion, X, Facebook, GitHub, and the Washington corporations site. There is no address bar, and there is no host allowlist. |
| User-generated content | No | Readers do not post into the app. |
| Social media | No | The app is not a social feed. Links to X and Facebook do not make it one. |
| Messaging and chat | No | |
| Advertising | No | |
| Parental controls, age assurance | No | |
| Made for Kids | No | Leave the kids age band empty. |
| Age rating override | None | Let Apple calculate it. |

A scan of the 532 public article titles on 18 November 2026 is what the Infrequent answers are based on. The homepage itself is the foundation's notes and a reading list. It is not a general-audience children's reader, and it is not a medical product.

If the goal is a 4+ rating, two things have to change first: the Home web view needs a host allowlist, and the age-rating answers for web access, medical information, drug references, and mature themes need to be reviewed against whatever content remains visible. This repository does not make that product change.

## 7. Phone number for App Review

The review contact email is DanBoice@adaptivephilosophy.foundation. The repo does not contain a phone number, and one should not be invented. Before submit, add a phone number on the App Review Information page. It is not shown on the public product page.

## 8. Encryption banner

If App Store Connect still asks, answer that the app does not use non-exempt encryption. Standard HTTPS is exempt. The generated Info.plist already says so.

## 9. Release after approval

Automatic release is off. After Apple approves version 1.0.0, release it from App Store Connect when you want it on the store.

## 10. Submit

When steps 1 through 8 are done, run Actions → App Store metadata and turn **submit** on. Leave it off until then. The default run uploads the listing and stops before review.
