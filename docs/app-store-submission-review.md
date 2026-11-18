# App Store update handoff — Somnus: Sleep Debt 1.2.0

Prepared: **18 November 2026**. This prepares an update to the existing [Somnus: Sleep Debt app](https://apps.apple.com/app/id6812648966). Version 1.1.0 (build 4) went live on 18 November 2026; its handoff, archive and upload results remain in Git history.

**Target: version 1.2.0, build 5.** 1.2.0 is a minor-version bump because the release adds user-visible chart behaviour (severity colours) rather than only fixing bugs. Build 5 increments 1.1.0's build 4. The owner submits for review personally; this handoff ends at a saved draft.

## Release scope and evidence

The feature is merged in [PR #18](https://github.com/EMRahman/Somnus/pull/18) (weekday severity colours, selection highlight) and [PR #19](https://github.com/EMRahman/Somnus/pull/19) (sleep debt bars and cumulative line), merge commit `ead41c9`:

- **Shortfall severity colours.** Nightly shortfall is rated **under 0.5h (yellow)**, **0.5–1h (orange)** or **1h+ (red)**. A legend under each Sleep Debt chart shows the bands.
- **By time.** Sleep debt bars use the band colour. Week, month and year bars are rated by their **average shortfall per night**, so a long period is not shown red merely because it sums many nights; the legend says **Period debt** for those ranges. Inline labels switch to dark text on yellow bars.
- **Cumulative line.** Each segment takes the colour of the **running average shortfall per night**, so the line changes colour as the running average crosses a band.
- **By weekday.** Individual nights (1M), weekday averages (1Y/5Y/10Y) and monthly/yearly detail bars use the same bands. Selected weekdays get a column highlight, a filled button and a bold value; the summary and dated values take the band colour when 0.5h or more. Missing nights remain marked **No data**.
- No changes to HealthKit access, calculations of debt itself, data handling or settings.

| Evidence | Status |
| --- | --- |
| Unit and UI tests | See completion record below |
| Physical test device | **iPhone 16, iOS 27.2.1** — the owner tested the latest changes on this phone and approved them on 18 November 2026 (Debug/Xcode install of `ead41c9`) |
| Website demo | Mirrors the severity colours (PRs #18/#19); parity gaps closed in this release PR (see below) |

## App Store Connect field map

Retain everything from the 1.1.0 version unless listed here. Apple copies the live version's metadata into a new version.

| Section / field | Value or action |
| --- | --- |
| App record | **Somnus: Sleep Debt**, Apple ID **6812648966**, bundle ID `com.ehsanrahman.somnus`; reuse the existing app |
| Version / build | Create iOS **1.2.0**; select build **1.2.0 (5)** once processed |
| Locale | English (U.K.) — copy below uses UK spelling |
| What's New in This Version | Paste **What's New** below |
| Description | Paste **Description** below (adds one paragraph on severity colours) |
| Promotional Text | Paste **Promotional Text** below (can be changed without a new version) |
| Keywords | Retain the current list |
| Screenshots | Replace all five in each slot with the 1.2.0 captures (order 01–05; see **Screenshots**) |
| Support / Marketing / Privacy URLs | Retain: `https://emrahman.github.io/Somnus/support.html`, `https://emrahman.github.io/Somnus/`, `https://emrahman.github.io/Somnus/privacy.html` |
| Copyright | `2026 Ehsan Rahman` |
| App Review contact / sign-in | Retain existing contact; sign-in not required |
| App Review Notes | Paste **Review Notes** below |
| Release option | **Manually release this version** (as 1.1.0) unless the owner chooses otherwise |
| App Privacy / age rating / pricing | No change; this release adds local chart styling only |

## What's New

Paste into **What's New in This Version** (maximum 4,000 characters):

```text
See at a glance how serious each shortfall is.

- Sleep Debt bars are now colour-coded by shortfall per night: yellow under 30 minutes, orange from 30 minutes to an hour, and red for an hour or more.
- Week, month and year bars are rated by their average night, so a long period isn't marked red just because its nights add up.
- The cumulative debt line changes colour as your running average per night crosses each band.
- By weekday uses the same colours for individual nights, weekday averages and monthly or yearly detail, and the selected weekday is now clearly highlighted.

Your sleep analysis stays on your device, with read-only access to Apple Health.
```

## Description

Paste into the English **Description** field (maximum 4,000 characters). Only the **SLEEP DEBT AGAINST YOUR OWN TARGET** section changes from 1.1.0:

```text
See your sleep over time, not just last night.

Somnus: Sleep Debt reads sleep records already in Apple Health and turns them into a clear view of nightly shortfall and longer-term patterns.

FROM ONE NIGHT TO TEN YEARS
Explore daily, weekly, monthly, yearly, five-year and ten-year views. Longer views summarize your available recorded history; Somnus does not create missing records.

FIND YOUR RECURRING SHORT NIGHTS
In monthly and longer Sleep Debt views, switch between By time and By weekday. Compare individual nights across the month, or average nightly shortfall for each weekday over longer periods. Select a weekday to see its recording count and dated nights, monthly averages or yearly averages. Night labels refer to the evening, so Monday night includes Tuesday morning. Missing recordings stay distinct from recorded nights with no shortfall.

SLEEP DEBT AGAINST YOUR OWN TARGET
Choose a personal sleep target and see how much each tracked night falls short. Colour-coded bars show whether a night, or the average night in a longer period, fell short by under 30 minutes, 30 minutes to an hour, or an hour or more, and the cumulative line changes colour with your running average. Compare accumulated shortfall with your behind-or-ahead balance, where nights above target can offset nights below it. Missing nights are excluded rather than counted as a full night of debt.

CONTEXT FOR YOUR PATTERNS
View recorded sleep duration and stages, average sleep, target compliance, and an educational Sleep Score combining duration, efficiency, bedtime consistency, and sleep-stage proportions. Read the score's methodology and limitations in Settings.

FREE AND PRIVATE
No subscriptions, In-App Purchases, advertising, or accounts. Calculations happen on your device. Somnus does not upload your Health data or write to Apple Health.

GETTING STARTED
Requires iOS or iPadOS 17 or later and recorded sleep in Apple Health. An Apple Watch with sleep tracking enabled is the intended data source. Grant read access to Sleep Analysis to see your records. Somnus analyzes existing records; it does not independently measure sleep.

Somnus provides educational wellness estimates, not clinical measurements or medical advice. It is not a medical device and does not diagnose, treat, cure, or prevent any condition. Consult a qualified healthcare professional for medical concerns.
```

## Promotional Text

Paste into **Promotional Text** (maximum 170 characters; this is 154):

```text
New: colour-coded sleep debt shows at a glance whether you're short by minutes or by hours, from one night to ten years, with private, on-device analysis.
```

## Review Notes

Paste into **App Review Information → Notes** (maximum 4,000 UTF-8 bytes):

```text
Somnus: Sleep Debt 1.2.0 colour-codes sleep-debt charts by severity. The app reads Sleep Analysis from Apple Health, performs all analysis on-device, and never writes Health data. It has no login, subscription, advertising, analytics, backend, or third-party SDKs. Health access is requested only after an explicit onboarding or Settings connection action. The Sleep Score is an educational wellness estimate; its methodology and limitations are in Settings > How Sleep Score Is Calculated.

To review the change:
1. With recorded sleep available, open Trends > 1W. Sleep Debt bars are yellow (under 0.5h short), orange (0.5-1h) or red (1h or more), with a legend below the chart. The cumulative line changes colour with the running average shortfall per night.
2. Select 1M, 1Y, 5Y or 10Y. Each bar now covers a week, month or year and is coloured by its average shortfall per night, not its total.
3. Select By weekday (1M and longer). Individual nights, weekday averages and the monthly/yearly detail use the same colours, and the selected weekday is highlighted.

Night labels refer to the evening: Monday night includes Tuesday morning. Missing recordings are marked separately and do not create phantom debt.

If the review device has no sleep history:
1. Open Health > Browse/Search (or the iPad sidebar) > Sleep > Add Data; navigation varies by OS.
2. Add Asleep records, not In Bed, for recent completed nights with different lengths against the default 8-hour target, for example 23:00-06:45 (0.25h short, yellow), 23:00-06:15 (0.75h short, orange) and 23:00-05:30 (1.5h short, red). Keep samples non-overlapping.
3. Open Somnus, complete onboarding, tap Continue on the Health access page, and allow Sleep Analysis. Pull down on Dashboard to refresh, then open Trends > 1W.

Without readable data the app intentionally shows no-data guidance. A previously answered Health access sheet will not be shown again; access can be changed in Apple Health or Settings > Privacy & Security > Health.

Developer test device: iPhone 16, iOS 27.2.1. Screenshots use synthetic records in a DEBUG-only fixture; that fixture and its launch flags are compiled out of Release builds.
```

## Screenshots

All ten App Store screenshots were retaken for 1.2.0 because the Sleep Debt colours appear in 02, 04 and 05 (01 and 03 were retaken so the set shares one fixture date). Upload them in order, replacing the 1.1.0 set in each slot.

| App Store device slot | Files, in order | File dimensions |
| --- | --- | --- |
| iPhone 6.9" display | [Dashboard](app-store-screenshots/iphone-6.9/01-dashboard.png), [Sleep Debt](app-store-screenshots/iphone-6.9/02-sleep-debt.png), [Sleep Duration](app-store-screenshots/iphone-6.9/03-sleep-duration.png), [Weekday month](app-store-screenshots/iphone-6.9/04-weekday-month.png), [Weekday year](app-store-screenshots/iphone-6.9/05-weekday-year.png) | 1320 × 2868 portrait; no alpha |
| iPad 13" display | [Dashboard](app-store-screenshots/ipad-13/01-dashboard.png), [Sleep Debt](app-store-screenshots/ipad-13/02-sleep-debt.png), [Sleep Duration](app-store-screenshots/ipad-13/03-sleep-duration.png), [Weekday month](app-store-screenshots/ipad-13/04-weekday-month.png), [Weekday year](app-store-screenshots/ipad-13/05-weekday-year.png) | 2064 × 2752 portrait; no alpha |

The website's `assets/somnus-*.png` images are the iPhone captures downscaled to 900 × 1955 (`somnus-debt-month.png` is the 1M By time view captured alongside the set).

To recapture, boot the iPhone 18 Pro Max and iPad Pro 13-inch (M5) simulators, override the status bar, and run the opt-in capture test on each:

```bash
xcrun simctl status_bar <udid> override --time 9:41 --dataNetwork wifi --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
TEST_RUNNER_SOMNUS_CAPTURE_SCREENSHOTS=1 xcodebuild test -project Somnus.xcodeproj -scheme Somnus \
  -destination 'platform=iOS Simulator,id=<udid>' -resultBundlePath <path>.xcresult \
  -only-testing:SomnusUITests/SomnusUITests/testCaptureAppStoreScreenshots
xcrun xcresulttool export attachments --path <path>.xcresult --output-path <dir>
```

Alternatively, without UI automation, install a DEBUG simulator build and capture each view with `simctl`. Destinations: `dashboard` (01), `debt` (02), `duration` (03), `monthly-duration -screenshotWeekdayDebt` (04), `yearly -screenshotWeekdayDebt` (05), and `monthly-duration` alone for the website's monthly view:

```bash
xcrun simctl launch --terminate-running-process <udid> com.ehsanrahman.somnus \
  -hasCompletedOnboarding YES -screenshotMode -screenshotDestination=yearly -screenshotWeekdayDebt
xcrun simctl io <udid> screenshot --type=png 05-weekday-year.png
```

`simctl` captures include an alpha channel; flatten them to opaque RGB before uploading (App Store Connect rejects transparency). XCUITest attachments are already opaque.

The 1.2.0 iPhone set came from the capture test on the iPhone 18 Pro Max simulator (iOS 27.0). On the iPad Pro 13-inch (M5) simulator the UI-test automation session stalled on relaunch, so the iPad set was captured with `simctl` and flattened. Both sets were captured on 18 November 2026 with the status bar at 09:41.

## Build, signing and upload

`project.yml` is the source of truth for **1.2.0 / 5**; `Info.plist` reads `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`. Generated Xcode projects are ignored. Retain development team `FXNHMJHQFS`, the bundle ID and entitlements.

```bash
xcodegen generate
xcodebuild -project Somnus.xcodeproj -scheme Somnus -configuration Release \
  -destination 'generic/platform=iOS' -archivePath <path>/Somnus-1.2.0-build5.xcarchive archive
xcodebuild -exportArchive -archivePath <path>/Somnus-1.2.0-build5.xcarchive \
  -exportOptionsPlist <export-options>.plist -exportPath <path>/export -allowProvisioningUpdates
```

The export options use `method = app-store-connect`, `destination = upload`, `teamID = FXNHMJHQFS`, automatic signing. Verify in the archive: `CFBundleShortVersionString = 1.2.0`, `CFBundleVersion = 5`, arm64, dSYM, `PrivacyInfo.xcprivacy`, HealthKit entitlement, both Health purpose strings, `ITSAppUsesNonExemptEncryption = false`, no screenshot-fixture strings, and `get-task-allow = false` in the distribution-signed app.

## Owner submission checklist

The draft is left for the owner to submit:

- [ ] Open the 1.2.0 version page and check What's New, description, promotional text, screenshots and review notes.
- [ ] Confirm build **1.2.0 (5)** is selected and no Missing Compliance prompt remains.
- [ ] Optionally install 1.2.0 (5) from TestFlight on the iPhone 16 for a final distribution-build check.
- [ ] Click **Add for Review**, then **Submit for Review**. With manual release, release the approved version when ready.
- [ ] After release, merge or deploy the website update so the site's version badge (1.2.0) matches the store.

## Handoff completion record

| Item | Value / result |
| --- | --- |
| Release source commit | `ead41c9` (main) + this release PR (version bump, screenshots, docs, website) |
| Live version inspected | 1.1.0, released 18 November 2026 (public App Store lookup) |
| Owner device test | iPhone 16, iOS 27.2.1 — passed (owner, 18 November 2026) |
| Unit / UI tests | Passed 18 November 2026 on iPhone 18 Pro simulator, iOS 27.0: 23 unit, 2 UI (screenshot capture test skips unless opted in) |
| Website demo | `node --test website/tests/demo-data.test.cjs` 6/6 passed; Playwright browser suite (Chromium) passed |
| Screenshots | All ten retaken 18 November 2026 (iPhone 18 Pro Max and iPad Pro 13-inch (M5) simulators, iOS 27.0); 1320 × 2868 and 2064 × 2752, no alpha. Website assets regenerated from the iPhone captures |
| Archive / export / upload | **Pending.** Xcode 27.1 (27A9275). On 18 November the Release archive compiled but `CodeSign` failed with `errSecInternalComponent`: the login keychain was locked to the non-interactive session that ran the build. Unlock the keychain at the Mac (or allow `codesign` access when prompted), then re-run the archive and upload commands above |
| App Store Connect 1.2.0 draft | **Pending** — Claude in Chrome was not connected to the agent session; fill from this document |
| Submission / release state | Not submitted — owner will submit |
