# App Store Submission Readiness — Somnus

Last verified: 15 August 2026

## Binary status

Somnus 1.0.0 (build 1) is ready to upload as an iOS/iPadOS archive:

- Built with the iOS 26 SDK, satisfying Apple's current SDK requirement.
- Release archive and App Store Connect export both succeed.
- Distribution export contains an arm64 binary, dSYM symbols, HealthKit entitlements, and `get-task-allow = false`.
- The 1024px source icon and generated iPhone/iPad icons are opaque.
- `PrivacyInfo.xcprivacy` is bundled and declares the app-only UserDefaults reason `CA92.1`.
- `Info.plist` includes the read-only HealthKit purpose string and declares no non-exempt encryption.
- The app exposes its privacy policy in Settings and requests HealthKit permission only from explicit user actions.
- The only HealthKit entitlement claimed is `com.apple.developer.healthkit`. Background delivery was removed for 1.0: Somnus has no work to perform while backgrounded, and its `HKObserverQuery` runs only while the app is open.
- Twelve unit tests and the UI release smoke test pass.

Rebuild the distribution archive from a clean checkout at submission time rather than reusing an older local export.

## App Store Connect tasks

These require product/account information and cannot be completed from the repository alone:

1. Enter `https://emrahman.github.io/Somnus/privacy.html` as the Privacy Policy URL in App Store Connect. The GitHub Pages site is published and this page is live.
2. Enter `https://emrahman.github.io/Somnus/support.html` as the Support URL. It includes direct developer contact information as required by App Store Connect.
3. Complete the listing: description, subtitle, keywords, Health & Fitness category, territories, pricing, age-rating questionnaire, copyright, and screenshots for every supported device family. Sets for iPhone 6.9" (1320×2868) and iPad 13" (2064×2752) are in `docs/app-store-screenshots/`; the iPad set is mandatory because the app targets device families 1 and 2.
4. Complete App Privacy using the shipped behavior: no tracking and no data transmitted off-device. Reassess these answers if analytics, accounts, networking, advertising, or third-party SDKs are added.
5. State that Somnus is not a regulated medical device unless its legal/regulatory status changes.
6. Paste the Review Notes below. They explain the read-only HealthKit design and give App Review a self-contained way to populate the data-driven screens.
7. Upload the exported build through Xcode Organizer or App Store Connect and run Apple's server-side validation before submitting for review.

## Review Notes

App Review devices generally have no Apple Watch sleep history, so every data screen would otherwise show the intentional "No Sleep Data Yet" state. Rather than shipping synthetic data in the production binary — `ScreenshotSupport` stays behind `#if DEBUG` and is compiled out of App Store builds — the notes tell the reviewer how to add sleep samples in the Health app.

> Somnus is a read-only HealthKit sleep-analysis app. It requests access only after the user taps the onboarding or Settings connection button. Sleep scores, debt, and trends are calculated entirely on-device; the app has no account, analytics, advertising, backend, or third-party SDKs, and never writes Health data.
>
> Somnus renders data from sleep-analysis samples already present in Apple Health, normally recorded by an Apple Watch. On a device with no sleep history the app intentionally shows a "No Sleep Data Yet" guidance state rather than a misleading zero score. To see the full Dashboard and Trends UI:
>
> 1. Open the **Health** app → **Browse** → **Sleep** → **Add Data**.
> 2. Add two or three nights, each roughly 23:00 to 07:00 on consecutive days.
> 3. Launch Somnus, tap **Grant Access & Get Started**, and allow Sleep Analysis when the Health sheet appears.
> 4. Pull down on the Dashboard to refresh. Trends → 1W will then show the sleep-debt and duration charts.
>
> Users may also skip Health access entirely and browse the app's guidance and Settings.

## Reverification commands

```bash
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
