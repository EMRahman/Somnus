# App Store Submission — Somnus: Sleep Debt

Submission checklist reviewed: 16 September 2026

Binary and distribution export last verified: 16 September 2026

Unit/UI test suites last verified: 15 September 2026

This is the working checklist for the first public iPhone/iPad release. Check off App Store Connect tasks only after completing them in the account; repository checks do not prove that metadata, declarations, or uploads have been submitted to Apple. Apple's validation and App Review may still request additional information.

## Confirmed app record and release values

- [x] Create a **New App**, not an App Bundle, in App Store Connect. The developer confirmed that the app record was created as **Somnus: Sleep Debt**.
- [x] Confirm the product-page name: **Somnus: Sleep Debt**. The installed app's display name remains **Somnus**; the store name does not require a code rename.

| Field | Value |
| --- | --- |
| App Store name | Somnus: Sleep Debt |
| Platform | iOS; the same app supports iPhone and iPad |
| Bundle ID | `com.ehsanrahman.somnus` |
| Release version | `1.0.0` |
| Current repository build number | `1`; use a higher number if this build number has already been uploaded |
| Intended primary category | Health & Fitness |
| Intended price | Free |
| Suggested tax category | App Store software |
| Copyright field | `2026 Ehsan Rahman` |

The “all users currently have access” creation message concerns App Store Connect team members, not the public. Full team access is fine unless access needs to be restricted. Creating the record does not publish the app. No separate iPad, Apple Watch, or App Bundle record is needed for this release: Somnus reads Apple Watch data through Apple Health but does not ship a watchOS app.

## Binary status

Somnus 1.0.0 (build 1) is ready to upload as an iOS/iPadOS archive:

- Built with Xcode 26 and the iOS 26 SDK. Apple requires Xcode 26 or later and the iOS 26 SDK or later for current iOS uploads. [Apple SDK requirements](https://developer.apple.com/news/upcoming-requirements/)
- Release archive and App Store Connect export both succeed.
- Distribution export contains an arm64 binary, dSYM symbols, HealthKit entitlements, and `get-task-allow = false`.
- The 1024px source icon and generated iPhone/iPad icons are opaque.
- The iPhone and iPad App Store screenshots are opaque RGB images with no alpha channels.
- `PrivacyInfo.xcprivacy` is bundled and declares the app-only UserDefaults reason `CA92.1`.
- `Info.plist` includes both `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription`, and declares no non-exempt encryption. The update-purpose string truthfully states that Somnus does not save or modify Apple Health data; its presence does not request or grant write access. Authorization remains read-only with `toShare: []`.
- The app exposes its privacy policy in Settings and requests HealthKit permission only from explicit user actions.
- The only HealthKit entitlement claimed is `com.apple.developer.healthkit`. Background delivery was removed for 1.0: Somnus has no work to perform while backgrounded, and its `HKObserverQuery` runs only while the app is open.
- Twelve unit tests and the UI release smoke test pass.

Rebuild the distribution archive from a clean checkout at submission time rather than reusing an older local export. These are prior verification results, not a claim that the final submission build has already been uploaded.

### HealthKit purpose-string validation fix — 16 September 2026

The missing `NSHealthUpdateUsageDescription` was added to the source plist after a reported “Missing purpose string in Info.plist” validation failure. The complete error's named key was not supplied, so this addresses the likely HealthKit update-purpose issue rather than claiming every possible purpose-string error is resolved. The existing read-purpose string was already present in both the source and the previous release archive.

Adding the update-purpose string is a metadata-only fix: do not add HealthKit write types or change the app's read-only privacy declarations. Apple may require purpose strings for referenced sensitive APIs even when the app does not use those operations. [Apple purpose-string validation guidance](https://developer.apple.com/documentation/uikit/requesting-access-to-protected-resources)

Create and validate a **new archive** containing the fix; an old archive will not pick up source-plist edits. Confirm both HealthKit purpose strings are nonempty in the archived/exported app's `Info.plist`, then retry Apple's validation. If the error names a different key, investigate that exact key and bundle path before adding further descriptions. Increment the build number only if the previous version/build combination has already been uploaded. Local archive/export success does not prove Apple's server-side validation has passed.

Local revalidation on 16 September passed: source-plist lint, a fresh Release archive, an App Store Connect distribution export, both purpose strings in the archive and exported IPA, and distribution code-signature verification. The export retains HealthKit and `get-task-allow = false`. Unit/UI suites were not rerun for this metadata-only change, and the build was not uploaded or submitted to Apple's server-side validation.

## App Store Connect tasks

### 1. Account, App Information, and declarations

- [ ] Confirm Apple Developer Program membership is active and the Account Holder has accepted any outstanding required agreements. Free apps are distributed under the Apple Developer Program License Agreement; a Paid Apps Agreement is not needed solely for this free app with no In-App Purchases. [Apple agreements guidance](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements)
- [ ] Verify the created record uses the bundle ID above and the desired primary language. English (UK) is suitable for the existing English copy; confirm what was selected when creating the record.
- [ ] Set **Health & Fitness** as the primary category. A secondary category is optional.
- [ ] Complete **Content Rights** truthfully and confirm the rights to the app's icon, assets, and any content distributed in the binary. Leave Apple's standard license agreement in place unless deliberately supplying a custom agreement.
- [ ] Complete the current **age-rating questionnaire** based on the shipped features, including educational health/wellness content. Do not automatically answer “None” to every question or declare diagnosis/treatment functionality that the app does not provide. Let the questionnaire determine the rating. [Apple age-rating guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating)
- [ ] Complete **Digital Services Act trader/non-trader status** under Business → Compliance and confirm the app-specific declaration under App Information. This declaration is needed even if not distributing in the EU. Assess the actual purpose of the app; being free does not automatically establish non-trader status. If declaring trader status, complete Apple's contact/payment information and verification requirements. [Apple DSA guidance](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements)
- [ ] Under **App Store Regulations & Permits**, declare **Regulated Medical Device: No** for the current educational wellness product, assuming its actual regulatory status has not changed. Health & Fitness apps offered in the EU/EEA, UK, or US must make this declaration. Reassess if medical intended uses or regulatory status change. [Apple medical-device declaration guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/declare-regulated-medical-device-status)

### 2. Product-page copy and screenshots

- [ ] Enter the subtitle, description, and keywords from **Suggested listing copy** below, or review and replace them with the final preferred copy. The name and subtitle each have a 30-character limit; description is plain text, up to 4,000 characters; keywords have a 100-byte limit. [Apple app information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information), [Apple version metadata](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [ ] Enter `2026 Ehsan Rahman` in **Copyright**; App Store Connect adds the copyright symbol.
- [ ] Enter `https://emrahman.github.io/Somnus/support.html` as the **Support URL**. It contains developer contact information. The merged support page is live.
- [ ] Optionally enter `https://emrahman.github.io/Somnus/` as the **Marketing URL**. Promotional text and app-preview videos are optional. **What's New in This Version** is not needed for this first release; it is for subsequent updates.
- [ ] Upload the **iPhone 6.9-inch** screenshots, in order: [01-dashboard.png](app-store-screenshots/iphone-6.9/01-dashboard.png), [02-sleep-debt.png](app-store-screenshots/iphone-6.9/02-sleep-debt.png), [03-sleep-duration.png](app-store-screenshots/iphone-6.9/03-sleep-duration.png). Each is 1320×2868, opaque RGB PNG.
- [ ] Upload the **iPad 13-inch** screenshots, in order: [01-dashboard.png](app-store-screenshots/ipad-13/01-dashboard.png), [02-sleep-debt.png](app-store-screenshots/ipad-13/02-sleep-debt.png), [03-sleep-duration.png](app-store-screenshots/ipad-13/03-sleep-duration.png). Each is 2064×2752, opaque RGB PNG. This set is required because the app supports iPad.
- [ ] Check every uploaded image in Media Manager for the correct device family, ordering, and appearance. The three screenshots per family are sufficient: Apple accepts 1–10, and the highest required resolutions can scale down where the UI is the same. Recheck sizes if Apple changes the upload requirements. [Apple screenshot upload guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots), [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)

### 3. App Privacy and export compliance

- [ ] Enter `https://emrahman.github.io/Somnus/privacy.html` as the **Privacy Policy URL** under App Privacy. The merged policy is live. A User Privacy Choices URL is optional.
- [ ] For the shipped app, select **“No, we do not collect data from this app”**, save, and **Publish** the App Privacy responses. Apple Health records are processed only on-device; the app has no tracking, analytics, accounts, advertising, backend, or third-party SDKs. Reading HealthKit data locally is not a reason to declare developer collection of Health data. Reassess these answers before adding any off-device data handling. [Apple App Privacy guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy), [Apple data-collection definition](https://developer.apple.com/app-store/app-privacy-details/)
- [ ] Confirm the uploaded build has no unresolved **Missing Compliance** status. `ITSAppUsesNonExemptEncryption = false` is already in `Info.plist`; if Apple still requests export-compliance answers, complete them for the actual binary rather than uploading unrelated encryption documents. [Apple build-selection and compliance guidance](https://developer.apple.com/help/app-store-connect/manage-builds/choose-a-build-to-submit)

### 4. Pricing, distribution, and availability

- [ ] Set **Price: Free** explicitly and confirm the **tax category**; App Store software is appropriate for the current general-purpose app offering.
- [ ] Choose **public App Store distribution**, not a private custom app, and choose the countries/regions where it should be available. Resolve any territory-specific permit or compliance requests shown by App Store Connect, or exclude those territories until their requirements are satisfied. [Apple publishing workflow](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/overview-of-publishing-your-app-on-the-app-store)
- [ ] Review **iPhone/iPad app availability on Apple silicon Macs and Apple Vision Pro** in Pricing and Availability. For this iPhone/iPad-focused release, opt out of untested compatibility distribution unless usable Apple Health access and the full experience have been verified on those devices. This does not require creating native macOS or visionOS app records. [Apple Mac availability settings](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-macs-with-apple-silicon), [Apple Vision Pro availability settings](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-apple-vision-pro)

### 5. Final build, upload, and App Review information

- [ ] Build the release from the intended merged commit and a clean worktree using **Xcode 26 or later with the iOS 26 SDK or later**. Run the tests and archive commands below.
- [ ] Confirm the marketing version is `1.0.0` and the build number is unused for that version. If `1` has already been uploaded, increment `CURRENT_PROJECT_VERSION` in `project.yml`, regenerate the Xcode project, and rebuild. Do not try to replace an uploaded build with different contents under the same version/build number. [Apple build upload guidance](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds)
- [ ] Use **Xcode Organizer** to validate and upload the new archive to **App Store Connect**, or export for App Store Connect and upload with Transporter. A successful local archive/export is not an upload or Apple's server-side validation.
- [ ] Wait for Apple's processing, inspect any upload emails/warnings, and resolve errors. Confirm the correct icon, version, build number, signing, and supported device families are recognized.
- [ ] On the iOS version page, under **Build**, select that processed build and save. Ensure the version record matches the uploaded binary and export compliance is resolved. [Apple build-selection guidance](https://developer.apple.com/help/app-store-connect/manage-builds/choose-a-build-to-submit)
- [ ] Enter **App Review contact details**: Ehsan Rahman, `ehsanr.web@gmail.com`, and a real reachable phone number in international format. Supply the phone number in App Store Connect; it is not stored in this repository.
- [ ] Leave **Sign-in required** unchecked: the app has no login and needs no demo-account credentials.
- [ ] Paste the **Review Notes** below. Ensure the notes fit the 4,000-byte field limit. They explain read-only HealthKit access, the no-data state, and how to populate the screens without an Apple Watch. [Apple reviewer-information requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [ ] Choose a **Version Release** option deliberately: manual release after approval, automatic release after approval, or automatic release no earlier than a chosen date. Phased release is for updates, not this initial launch.

## Recommended checks and optional launch improvements

These are not additional mandatory metadata fields, but the device checks are strongly recommended before submitting a HealthKit app.

- [ ] Install the intended release via **TestFlight** on a physical iPhone and, if available, iPad. Test real Apple Health sleep history, watch sync/refresh, first-run permission grant, denied/revoked access, and the no-data guidance. Do not mistake a DEBUG/sample-data build for the actual distribution build.
- [ ] Check all six Trends periods, especially 5Y/10Y with substantial history; verify changes to sleep goals, the score-methodology screen, privacy screen, and iPad rotation/multitasking. Historical views summarize only available records; they do not manufacture ten years of data.
- [ ] Optionally add a **5Y or 10Y screenshot** in each device family to demonstrate the long-term differentiator. The current screenshots are valid but show weekly data; another screenshot is not a submission blocker.
- [ ] Optionally complete **Accessibility Nutrition Labels**, but claim only features tested against Apple's criteria across the app's common tasks. The labels are currently voluntary; reassess if Apple makes them mandatory. [Apple accessibility-label guidance](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels)

## Final submission and release gate

- [ ] All required account, metadata, screenshot, privacy, pricing/availability, compliance, and App Review fields above are saved; there are no unresolved validation errors.
- [ ] The correct processed build is selected, not an older pre-disclosure build, and the intended release option is saved.
- [ ] Click **Add for Review** on the version page. This creates/adds to a draft submission; it does **not** send the app to Apple by itself.
- [ ] Open the draft submission/App Review section and click **Submit for Review**. Confirm **Waiting for Review** or **In Review**, not merely **Ready for Review**. [Apple submission steps](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)
- [ ] Monitor App Review messages and respond to questions or rejection reasons. If a binary change is required, upload a new build number and select the replacement build before resubmitting.
- [ ] After approval, release manually if that option was selected; otherwise confirm the automatic/scheduled release. Verify the public product page and download. Publication can take up to 24 hours after approval/release. [Apple publishing workflow](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/overview-of-publishing-your-app-on-the-app-store)
- [ ] After the app is live, update the website and README's “Pending submission” status and add the real App Store link. This is post-launch housekeeping, not a review prerequisite.

## Suggested listing copy

Only the app name is confirmed as entered in App Store Connect. The copy below is a paste-ready proposal matching the current binary; review it before entering it. The subtitle is 25 characters, and the ASCII keyword list fits the 100-byte limit.

Subtitle:

```text
Sleep trends across years
```

Keywords:

```text
health,watch,history,stages,consistency,duration,wellness,analysis,yearly
```

Description:

```text
See your sleep over time, not just last night.

Somnus: Sleep Debt reads sleep records already in Apple Health and turns them into a clear view of nightly shortfall and longer-term patterns.

FROM ONE NIGHT TO TEN YEARS
Explore daily, weekly, monthly, yearly, five-year and ten-year views. Longer views summarize your available recorded history; Somnus does not create missing records.

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

Optional promotional text:

```text
Explore your recorded sleep from daily views to ten-year trends. Free, read-only Apple Health analysis with no accounts, ads or subscriptions.
```

## Review Notes

App Review devices generally have no Apple Watch sleep history, so every data screen would otherwise show the intentional "No Sleep Data Yet" state. Rather than shipping synthetic data in the production binary — `ScreenshotSupport` stays behind `#if DEBUG` and is compiled out of App Store builds — the notes tell the reviewer how to add sleep samples in the Health app.

Paste the following plain text into App Review Information → Notes:

```text
Somnus: Sleep Debt is a read-only HealthKit sleep-analysis app. It requests access only after the user taps the onboarding or Settings connection button. Its Sleep Score is identified in-app as an educational wellness estimate, with the data source, weighted methodology, and limitations disclosed under Settings → How Sleep Score Is Calculated. Scores, debt, and trends are calculated entirely on-device; the app has no account, analytics, advertising, backend, or third-party SDKs, and never writes Health data.

Somnus renders data from sleep-analysis samples already present in Apple Health, normally recorded by an Apple Watch. On a device with no sleep history the app intentionally shows a "No Sleep Data Yet" guidance state rather than a misleading zero score. To see the full Dashboard and Trends UI:

1. Open the Health app → Browse/Search (or the iPad sidebar) → Sleep → Add Data. The navigation label varies with the OS version.
2. Choose Asleep, not In Bed, and add the most recent two or three completed nights, including last night. Each sample should start roughly 23:00 on one date and end 07:00 the following date. In-bed-only samples are deliberately excluded from sleep analysis.
3. Launch Somnus, tap Grant Access & Get Started, and allow Sleep Analysis when the Health sheet appears.
4. Pull down on the Dashboard to refresh. Trends → 1W will then show the sleep-debt and duration charts.

Manual Asleep samples are sufficient to test duration and debt. Actual Apple Watch stage history is needed to exercise the real Deep/REM breakdown. Longer Trends periods summarize the available history and may have only a few populated buckets on a review device.

If onboarding has already been skipped, request Health access from Settings and then refresh the Dashboard. Users may also skip Health access entirely and browse the app's guidance and Settings. No login, subscription, or purchase is required.
```

## Reverification commands

```bash
plutil -lint Somnus/Resources/Info.plist
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
xcodegen generate
xcodebuild -project Somnus.xcodeproj -scheme Somnus \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
xcodebuild -project Somnus.xcodeproj -scheme Somnus -configuration Release \
  -destination 'generic/platform=iOS' -archivePath /private/tmp/Somnus-release.xcarchive archive
```

Confirm the signed app claims HealthKit but not background delivery:

```bash
codesign -d --entitlements - --xml \
  /private/tmp/Somnus-release.xcarchive/Products/Applications/Somnus.app 2>/dev/null | plutil -p -
```

Check the purpose strings in the newly built archive:

```bash
/usr/libexec/PlistBuddy -c 'Print :NSHealthShareUsageDescription' \
  /private/tmp/Somnus-release.xcarchive/Products/Applications/Somnus.app/Info.plist
/usr/libexec/PlistBuddy -c 'Print :NSHealthUpdateUsageDescription' \
  /private/tmp/Somnus-release.xcarchive/Products/Applications/Somnus.app/Info.plist
```

For the exported **distribution** app, also confirm `get-task-allow = false`, bundled `PrivacyInfo.xcprivacy`, the expected version/build, and opaque generated app icons. The intermediate archive may be development-signed; distribution entitlements must be checked on the distribution export, not inferred from the archive. Use Organizer for the final export/validation/upload and retain its delivery logs with the submission build.
