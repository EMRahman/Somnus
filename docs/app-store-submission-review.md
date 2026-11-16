# App Store update handoff — Somnus: Sleep Debt 1.1.0

Prepared: **16 November 2026**. This prepares an update to the existing [Somnus: Sleep Debt app](https://apps.apple.com/app/id6812648966), live since 30 September 2026. It supersedes the first-release checklist; earlier archive/export results remain in Git history.

**Target: version 1.1.0, build 4.** The owner confirmed version 1.1.0. Build 4 increments the repository's previous build 3; check App Store Connect for availability before uploading. No account edits, archive upload, TestFlight installation, submission, or release are claimed by this handoff.

## Release scope and evidence

The feature is merged in [PR #12](https://github.com/EMRahman/Somnus/pull/12), merge commit `6413d778180e2f0794aaf269d9ecfbfd1d4cd943`:

- **1M:** Sleep Debt → **By weekday** groups nights Monday–Sunday, four or five occurrences per weekday, oldest first. Selecting a weekday shows its recording count, average shortfall and dated nightly values.
- **1Y:** Seven weekday averages, with monthly averages for the selected weekday.
- **5Y / 10Y:** Seven weekday averages, with yearly averages for the selected weekday.
- Night labels refer to the evening: Monday night includes Tuesday morning, including bedtimes after midnight. Fragmented sessions are merged before applying the target. Missing recordings stay distinct from recorded zero-shortfall nights. Averages include recorded zero-shortfall nights.
- The **By time / By weekday** control appears for 1M and longer. The cumulative debt line stays in **By time**; 1D/1W retain their charts.

| Evidence | Status |
| --- | --- |
| Feature unit tests | 20 passed on 16 November 2026, including 8 weekday-debt cases |
| Feature UI tests | Both passed on iPhone 18 Pro simulator, iOS 27.0; covers all longer ranges and return to By time / 1W / 1D |
| Review | Codex gave feature commit `62b8974` a thumbs-up with no findings before merge |
| Visual check | The owner saw the simulator chart and approved its appearance |
| Release configuration | 1.1.0 (4) Release simulator build passed on 16 November 2026; this is not a signed device archive or distribution export |
| Physical test device | **iPhone 16, iOS 27.2.1**, confirmed by the owner; use the same phone for release testing |
| Candidate on that phone | Pending installation and verification of **1.1.0 (4)**; the device information alone is not a pass result |
| Signed archive / distribution export / upload | Pending for 1.1.0 (4); September's 1.0 archive checks do not verify this build |

The website's interactive demo can be updated later, as agreed with the owner. It is separate from the app and is not a binary test or an App Review demo account. Website changes are outside this release-preparation PR.

## Start here: coding-agent handoff

The owner will open the App Store Connect login page and handle sign-in/2FA. Use the authenticated browser session they provide. Do not store credentials, authentication codes, or the private review contact phone number in the repository.

1. Open [App Store Connect → this app](https://appstoreconnect.apple.com/apps/6812648966/distribution). Verify the app name, Apple ID, bundle ID, team, live version and existing drafts/builds. Reuse a matching 1.1.0 draft if present. Do not create a second app record or App Bundle.
2. Confirm 1.1.0 is above the live version and build 4 is unused. If either conflicts, record the account values and adjust this plan and `project.yml` before building. Do not silently attach another version's build.
3. Create **iOS 1.1.0** if needed. Apple copies the current version's metadata; inspect that inherited content before editing. This version covers iPhone and iPad; there is no watchOS app. [Apple: create a new version](https://developer.apple.com/help/app-store-connect/update-your-app/create-a-new-version/)
4. Use the field map below. Fill **What's New**, update the description with the weekday feature and replace the review notes. Preserve the actual primary language and existing localizations; the English copy is for the existing English localization, not a request to add a locale.
5. Inspect inherited screenshots, URLs, contact details, declarations and release settings. Retain accurate existing values. Record account-only blockers instead of guessing answers or inventing assets.
6. Save each edited section. Select **1.1.0 (4)** only after the exact Release binary is uploaded, processed and verified. Metadata can be prepared while build upload and physical testing are pending.
7. Leave a **saved draft** for the owner to inspect. This request prepares the form; it does not authorize **Add for Review**, **Submit for Review**, or publication. Report the version URL, saved fields, selected build (or no build) and outstanding actions.

Suggested prompt for the next agent after login:

```text
Prepare the existing Somnus: Sleep Debt App Store Connect record (Apple ID 6812648966, bundle ID com.ehsanrahman.somnus) for version 1.1.0, proposed build 4, using docs/app-store-submission-review.md from the merged release-preparation PR. I will handle login and 2FA. Inspect the live version and existing drafts/builds first. Fill and save the English release metadata and review notes from the document; preserve account settings and localizations unless a documented change is needed. Use the existing review contact details and ask only for genuinely missing account information. The physical test phone is an iPhone 16 on iOS 27.2.1; do not mark the candidate tested without evidence. Select the exact processed 1.1.0 (4) build only if available and verified. Leave a saved draft; do not add or submit it for review or release it. Report saved fields, the version URL, and remaining build, device-test, screenshot or validation blockers. The website demo update can wait.
```

## App Store Connect field map

The public UK listing was inspected on 16 November 2026. It shows the name, subtitle, Free pricing, Health & Fitness category and 9+ rating below. It does not establish the uploaded build, primary localization, private contact or draft status; inspect those after login. [Public listing](https://apps.apple.com/gb/app/somnus-sleep-debt/id6812648966)

| Section / field | Value or action |
| --- | --- |
| App record | **Somnus: Sleep Debt**, Apple ID **6812648966**; reuse the existing app |
| Bundle ID | `com.ehsanrahman.somnus` |
| Platform / devices | iOS; iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`) |
| Version / build | **1.1.0 (4)** in `project.yml`; confirm account availability before archive/upload |
| Minimum OS | iOS / iPadOS **17.0**; the test phone's OS does not change the deployment target |
| Name | Retain **Somnus: Sleep Debt**; installed display name remains **Somnus** |
| Subtitle | Retain **Sleep debt trends across years** (30 characters), matching the public listing |
| Primary language / localizations | Inspect and retain existing values; public language EN does not identify the account's locale |
| What's New in This Version | Paste **What's New** below; required for updates |
| Description | Paste **Description** below into the existing English localization |
| Keywords | Preserve the current list unless deliberately adopting the optional list below |
| Promotional Text | Preserve existing text or use the optional copy below |
| Support URL | `https://emrahman.github.io/Somnus/support.html` |
| Marketing URL | `https://emrahman.github.io/Somnus/` (optional); the older browser demo is not a release blocker |
| Privacy Policy URL | `https://emrahman.github.io/Somnus/privacy.html` |
| Copyright | `2026 Ehsan Rahman` (Apple supplies the symbol) |
| Category / price | Retain **Health & Fitness / Free**; no subscriptions or In-App Purchases |
| Age rating | Public listing shows **9+**; retain truthful questionnaire responses and inspect any new questions rather than forcing a rating |
| App Review contact | Retain the saved reachable contact. Previous handoff: Ehsan Rahman, `ehsanr.web@gmail.com`. Verify the real international-format number in the account; **iPhone 16 is the test device, not a contact phone number** |
| Sign-in required | Unchecked: no account or demo credentials |
| App Review Notes | Paste **Review Notes** below; an attachment is optional |
| Release option | Prepare **manual release after approval** for owner control, unless the owner has already specified another option |
| Phased release / ratings reset | No change proposed; retain existing settings and report them |

Check support, privacy and marketing URLs load before saving. Apple distinguishes character limits for description/What's New from the review-notes byte limit. [Version metadata](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/), [app information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)

## What's New

Paste into **What's New in This Version** (maximum 4,000 characters):

```text
Spot the nights that tend to leave you short on sleep.

- Switch between By time and By weekday in Sleep Debt for monthly and longer views.
- Compare each Monday, Tuesday and other weekday across the month, with dated nightly values and recording counts.
- Explore weekday averages over a year, five years or ten years, with monthly or yearly detail for your selected weekday.

Night labels follow the evening, so Monday night includes Tuesday morning. Missing recordings stay separate from nights with no shortfall, and weekday averages use only recorded nights.

Your sleep analysis stays on your device, with read-only access to Apple Health.
```

## Description

Paste into the English **Description** field (maximum 4,000 characters):

```text
See your sleep over time, not just last night.

Somnus: Sleep Debt reads sleep records already in Apple Health and turns them into a clear view of nightly shortfall and longer-term patterns.

FROM ONE NIGHT TO TEN YEARS
Explore daily, weekly, monthly, yearly, five-year and ten-year views. Longer views summarize your available recorded history; Somnus does not create missing records.

FIND YOUR RECURRING SHORT NIGHTS
In monthly and longer Sleep Debt views, switch between By time and By weekday. Compare individual nights across the month, or average nightly shortfall for each weekday over longer periods. Select a weekday to see its recording count and dated nights, monthly averages or yearly averages. Night labels refer to the evening, so Monday night includes Tuesday morning. Missing recordings stay distinct from recorded nights with no shortfall.

SLEEP DEBT AGAINST YOUR OWN TARGET
Choose a personal sleep target and see how much each tracked night falls short. Compare accumulated shortfall with your behind-or-ahead balance, where nights above target can offset nights below it. Missing nights are excluded rather than counted as a full night of debt.

CONTEXT FOR YOUR PATTERNS
View recorded sleep duration and stages, average sleep, target compliance, and an educational Sleep Score combining duration, efficiency, bedtime consistency, and sleep-stage proportions. Read the score's methodology and limitations in Settings.

FREE AND PRIVATE
No subscriptions, In-App Purchases, advertising, or accounts. Calculations happen on your device. Somnus does not upload your Health data or write to Apple Health.

GETTING STARTED
Requires iOS or iPadOS 17 or later and recorded sleep in Apple Health. An Apple Watch with sleep tracking enabled is the intended data source. Grant read access to Sleep Analysis to see your records. Somnus analyzes existing records; it does not independently measure sleep.

Somnus provides educational wellness estimates, not clinical measurements or medical advice. It is not a medical device and does not diagnose, treat, cure, or prevent any condition. Consult a qualified healthcare professional for medical concerns.
```

Optional **Keywords** (ASCII; maximum 100 bytes). Retain the current list if no keyword change is desired:

```text
health,watch,history,stages,consistency,duration,wellness,analysis,yearly,weekday
```

Optional **Promotional Text** (maximum 170 characters):

```text
Spot recurring short nights with weekday sleep-debt comparisons. Explore your recorded history from one night to ten years, with private, on-device analysis.
```

## Review Notes

Paste into **App Review Information → Notes** (maximum 4,000 UTF-8 bytes). These instructions exercise the feature with sparse data without claiming a completed physical-device check for the new build.

```text
Somnus: Sleep Debt 1.1.0 adds weekday sleep-debt comparisons. The app reads Sleep Analysis from Apple Health, performs all analysis on-device, and never writes Health data. It has no login, subscription, advertising, analytics, backend, or third-party SDKs. Health access is requested only after an explicit onboarding or Settings connection action. The Sleep Score is an educational wellness estimate; its methodology and limitations are in Settings > How Sleep Score Is Calculated.

To review the new feature:
1. With recorded sleep available, open Trends > 1M. In Sleep Debt, select By weekday.
2. Select Monday or another weekday. The month chart groups individual nights oldest first and shows the selected weekday's average shortfall, recording count, and dated values. A month may contain four or five instances of a weekday.
3. Select 1Y to compare weekday averages and view monthly averages for the selected weekday. Select 5Y or 10Y for yearly averages. These ranges summarize only available history; a new device does not need years of data.
4. Switch back to By time for chronological bars and the cumulative debt line. The 1D and 1W charts retain their existing views.

Night labels refer to the evening: Monday night includes Tuesday morning, including bedtimes after midnight. Averages use recorded nights, including nights with zero shortfall. Missing recordings are marked separately and do not create phantom debt. Fragmented sessions are combined before applying one nightly target.

If the review device has no sleep history:
1. Open Health > Browse/Search (or the iPad sidebar) > Sleep > Add Data; navigation varies by OS.
2. Add Asleep records, not In Bed, for recent completed nights. For a useful comparison, include the same weekday in two weeks, for example two Monday 23:00 to Tuesday 05:30 sessions seven days apart. Add a separate 23:00 to 07:00 session to show a night meeting the default 8-hour target. Keep samples non-overlapping.
3. Open Somnus, complete onboarding, tap Continue on the Health access page, and allow Sleep Analysis. Pull down on Dashboard to refresh, then open Trends > 1M > By weekday.

Without readable data the app intentionally shows no-data guidance. Manual Asleep entries can exercise duration and debt; Apple Watch stage history is needed for the real Deep/REM breakdown. A previously answered Health access sheet will not be shown again; access can be changed in Apple Health or Settings > Privacy & Security > Health.

Developer test device: iPhone 16, iOS 27.2.1. Screenshots may use synthetic records in a DEBUG-only fixture; that fixture and its launch flags are compiled out of Release builds. The website browser demo is separate from the app and is not required to review it.
```

## Screenshots

Inspect inherited screenshots before uploading duplicates. Existing assets show the unchanged dashboard and weekly charts. They do not demonstrate the weekday feature; an additional monthly weekday screenshot is useful but not a prerequisite to prepare the draft.

| App Store device slot | Existing assets, in order | File dimensions |
| --- | --- | --- |
| Large iPhone display (existing `iphone-6.9` set) | [Dashboard](app-store-screenshots/iphone-6.9/01-dashboard.png), [Sleep Debt](app-store-screenshots/iphone-6.9/02-sleep-debt.png), [Sleep Duration](app-store-screenshots/iphone-6.9/03-sleep-duration.png), [Weekday month](app-store-screenshots/iphone-6.9/04-weekday-month.png), [Weekday year](app-store-screenshots/iphone-6.9/05-weekday-year.png) | 1320 × 2868 portrait; no alpha |
| iPad 13-inch | [Dashboard](app-store-screenshots/ipad-13/01-dashboard.png), [Sleep Debt](app-store-screenshots/ipad-13/02-sleep-debt.png), [Sleep Duration](app-store-screenshots/ipad-13/03-sleep-duration.png), [Weekday month](app-store-screenshots/ipad-13/04-weekday-month.png), [Weekday year](app-store-screenshots/ipad-13/05-weekday-year.png) | 2064 × 2752 portrait; no alpha |

Apple currently accepts these dimensions; iPad screenshots are needed because the app supports iPad. Confirm the slots and validation shown in the account. The physical **iPhone 16** is the test phone, not a substitute for the large-display set. Capture new large-display assets on a suitable simulator/device; do not stretch phone screenshots to invent another device size. [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)

For optional new assets, capture Trends → 1M → By weekday and, if useful, 1Y with a weekday selected. Use fictional sample records rather than the owner's health history. Install a DEBUG simulator build first; its fixture supports:

```bash
xcrun simctl launch --terminate-running-process booted com.ehsanrahman.somnus \
  -hasCompletedOnboarding YES -screenshotMode \
  -screenshotDestination=monthly-duration -screenshotWeekdayDebt
```

Select a specific simulator if several are booted. These flags are absent from App Store builds. Scroll to show the full chart, labels and selected-day details. Check dimensions, opacity and legibility before adding/uploading an asset. The 04/05 weekday screenshots were captured on 16 November 2026 (iPhone 18 Pro Max and iPad Pro 13-inch (M5) simulators, iOS 27.2, status bar overridden to 09:41) by running `TEST_RUNNER_SOMNUS_CAPTURE_SCREENSHOTS=1 xcodebuild test ... -only-testing:SomnusUITests/SomnusUITests/testCaptureWeekdayDebtScreenshots` and exporting the result bundle's attachments.

## Physical-device acceptance checks

Use the owner's **iPhone 16 running iOS 27.2.1**. Record the exact candidate version/build, install source, date and result. Prefer the processed TestFlight build for the final distribution check. Simulator approval does not replace this step.

- [ ] Install/upgrade to **1.1.0 (4)**; verify Settings → Version plus TestFlight/Xcode build information. Confirm existing sleep-goal preferences and Health access survive the upgrade.
- [ ] Open 1M → By weekday with real records. Compare a Monday's dated values to its Monday-evening/Tuesday-morning Health records; check four/five occurrences, count, average and order.
- [ ] Check recorded zero shortfall versus a missing night. Use a controlled simulator fixture or separate test data if the phone lacks an edge case; do not alter the owner's real records to manufacture it.
- [ ] Select another weekday, then 1Y, 5Y and 10Y. Check selected-day summaries and monthly/yearly averages; sparse history must leave gaps rather than manufacture data.
- [ ] Return to By time and confirm the cumulative line. Check 1D/1W, change the sleep target and reload Trends to check recalculation.
- [ ] Check scrolling, weekday selection, larger text and VoiceOver. Do not claim whole-app Accessibility Nutrition Labels based only on chart identifiers.
- [ ] Check Dashboard, Settings, permission/no-readable-data guidance and refresh after Watch sync. Coordinate access changes with the owner and restore their preferences.
- [ ] Check iPad layout/rotation on an available iPad or simulator; record which was used. The iPhone result alone does not establish iPad coverage.

## Build, signing and upload

`project.yml` is the source of truth for **1.1.0 / 4**; `Info.plist` reads `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`. Generated Xcode projects are ignored. Do not change only a generated project or archive old 1.0.0 settings.

The toolchain inspected on 16 November is **Xcode 27.1 (27A9275), iOS SDK 27.1**. Apple's current upload minimum is Xcode 26 with the iOS 26 SDK or later; recheck at upload time. The iOS 17 deployment target is unchanged. [Apple upload requirements](https://developer.apple.com/news/upcoming-requirements/)

From a clean checkout of the merged release-preparation commit, record `git rev-parse HEAD` and run:

```bash
plutil -lint Somnus/Resources/Info.plist Somnus/Resources/PrivacyInfo.xcprivacy
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
xcodegen generate
xcrun simctl list devices available
```

Choose an installed simulator (the example matches the feature verification device):

```bash
xcodebuild -project Somnus.xcodeproj -scheme Somnus -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  -parallel-testing-enabled NO -resultBundlePath /private/tmp/Somnus-1.1.0-tests.xcresult test

xcodebuild -project Somnus.xcodeproj -scheme Somnus -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath /private/tmp/Somnus-1.1.0-build4.xcarchive archive
```

Use fresh result/archive paths if those exist. Retain development team `FXNHMJHQFS` and the bundle ID; resolve actual signing/provisioning errors in the owner's Xcode account. Do not change identity, entitlements or Health access to bypass them.

- [ ] Verify `CFBundleShortVersionString = 1.1.0`, `CFBundleVersion = 4`, bundle ID and device families in the **new archive** and distribution export. Settings shows the marketing version only, not proof of the build number.
- [ ] Verify arm64 binary, retained dSYM, opaque icons, bundled `PrivacyInfo.xcprivacy`, HealthKit entitlement, no background delivery, and distribution `get-task-allow = false`. An intermediate archive can be development-signed; inspect the distribution export for final entitlements.
- [ ] Verify both nonempty Health purpose strings and `ITSAppUsesNonExemptEncryption = false`. Authorization is read-only (`toShare: []`); the update-purpose string does not mean the app writes Health data.
- [ ] Validate/upload using Organizer or App Store Connect export/Transporter. Local archive/export success is not an upload or Apple's server validation. Retain delivery logs and resolve processing warnings.
- [ ] Once processed, select **1.1.0 (4)** on the version page, resolve any Missing Compliance prompt for that binary, and save. Do not select an older 1.0.0 build.

Archive inspection examples:

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  /private/tmp/Somnus-1.1.0-build4.xcarchive/Products/Applications/Somnus.app/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \
  /private/tmp/Somnus-1.1.0-build4.xcarchive/Products/Applications/Somnus.app/Info.plist
/usr/libexec/PlistBuddy -c 'Print :NSHealthShareUsageDescription' \
  /private/tmp/Somnus-1.1.0-build4.xcarchive/Products/Applications/Somnus.app/Info.plist
/usr/libexec/PlistBuddy -c 'Print :NSHealthUpdateUsageDescription' \
  /private/tmp/Somnus-1.1.0-build4.xcarchive/Products/Applications/Somnus.app/Info.plist
codesign -d --entitlements - --xml \
  /private/tmp/Somnus-1.1.0-build4.xcarchive/Products/Applications/Somnus.app 2>/dev/null | plutil -p -
```

## Account declarations to verify after login

This release adds local charts, not new collection or account features. Inspect inherited answers and new prompts; do not reset completed declarations simply because this is an update.

- [ ] Membership and required agreements are current; inspect account alerts. Free pricing and no In-App Purchases remain intended.
- [ ] App Privacy matches the binary: **No, we do not collect data from this app**. Health data is read/processed on-device; there is no tracking or off-device collection. The manifest declares no collected data/tracking and UserDefaults reason `CA92.1`. Reassess if the binary adds SDKs or off-device handling; save/publish privacy responses only if an actual update is needed. [Apple App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- [ ] Retain existing content-rights, age-rating, trader/non-trader, medical-device and tax declarations if accurate. Answer any new mandatory prompts from the owner's actual circumstances; free pricing does not determine trader status. The intended use remains educational wellness analysis.
- [ ] Confirm countries/regions and iPhone/iPad compatibility distribution on Mac/Vision Pro. Do not expand to untested platforms as part of filling this form.
- [ ] Retain the reachable contact, no sign-in requirement and existing license agreement unless the owner specifies a change.

## Submission and release after draft approval

The form-filling handoff ends at **saved draft**. Once the owner separately requests submission:

- [ ] Complete the device/build gates, confirm accepted metadata/screenshots, and verify the exact processed build and release option.
- [ ] Click **Add for Review** and inspect the draft submission; this alone does not send it to Apple.
- [ ] Click **Submit for Review**, confirm/record the resulting state, and monitor messages. A replacement binary needs a new build number. [Apple submission steps](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/)
- [ ] Manual release leaves an approved update pending developer release. Release when requested, then verify the public listing and installed version.

## Handoff completion record

Fill this with evidence as work happens. Keep pending items pending; repository state and successful login do not prove account completion.

| Item | Value / result |
| --- | --- |
| Release source commit | `bb2f989` (main, includes PR #14 fix for missing 1Y/5Y/10Y weekday bars) |
| Live version / latest uploaded build inspected in account | 1.0 Ready for Distribution; builds 1–3 under 1.0.0; no 1.1.0 draft existed |
| Existing/new 1.1.0 version-page URL / English locale | Created 16 Nov 2026: https://appstoreconnect.apple.com/apps/6812648966/distribution/ios/version/inflight ; English (U.K.) |
| Version/build availability | 1.1.0 (4) confirmed unused before upload |
| What's New / description / review notes saved | Saved from this document and verified after reload; promotional text updated to the optional copy; keywords kept, `weekday` appended (92 chars) |
| Inherited screenshots and URLs checked | Inherited 01–03 retained; 04/05 weekday screenshots added to iPhone large-display and iPad 13" slots (5 of 10 each). Support, marketing and privacy URLs return 200 |
| Contact, declarations and release settings checked | Existing review contact retained; sign-in not required. Release changed from automatic to **manual**; phased release off and rating kept (unchanged). App Privacy/age rating/pricing not edited |
| Archive / export / upload evidence | Xcode 27.2 (27B52), iOS SDK 27.2. Full test suite passed (20 unit, 2 UI). Archive verified 1.1.0 / 4, arm64, dSYM, privacy manifest, HealthKit entitlement, no screenshot flags. App Store Connect export signed Apple Distribution, `get-task-allow = false`. Uploaded via `xcodebuild -exportArchive` (destination upload); Apple validation passed, "Upload succeeded" |
| Selected processed build / compliance state | Build 4 processed (Ready to Submit) and selected on 1.1.0; no Missing Compliance prompt (`ITSAppUsesNonExemptEncryption = false`) |
| iPhone 16, iOS 27.2.1 candidate result | Pending |
| iPad result | Pending |
| Remaining blockers / owner input | Physical iPhone 16 acceptance checks for 1.1.0 (4) via TestFlight; owner review of the saved draft |
| Submission / release state | Saved draft, Prepare for Submission. **Not** added for review or submitted |
