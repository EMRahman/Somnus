# App Store Submission Readiness — Somnus

Last verified: 14 August 2026

## Binary status

Somnus 1.0.0 (build 1) is ready to upload as an iOS/iPadOS archive:

- Built with the iOS 26 SDK, satisfying Apple's current SDK requirement.
- Release archive and App Store Connect export both succeed.
- Distribution export contains an arm64 binary, dSYM symbols, HealthKit entitlements, and `get-task-allow = false`.
- The 1024px source icon and generated iPhone/iPad icons are opaque.
- `PrivacyInfo.xcprivacy` is bundled and declares the app-only UserDefaults reason `CA92.1`.
- `Info.plist` includes the read-only HealthKit purpose string and declares no non-exempt encryption.
- The app exposes its privacy policy in Settings and requests HealthKit permission only from explicit user actions.
- Twelve unit tests and the UI release smoke test pass.

A locally exported IPA is available at `/private/tmp/Somnus-AppStore-export/Somnus.ipa`. Recreate it from a clean checkout rather than treating this temporary artifact as a source-controlled release.

## App Store Connect tasks

These require product/account information and cannot be completed from the repository alone:

1. Publish the GitHub Pages website and enter `https://emrahman.github.io/Somnus/privacy.html` as the Privacy Policy URL in App Store Connect.
2. Enter `https://emrahman.github.io/Somnus/support.html` as the Support URL. It includes direct developer contact information as required by App Store Connect.
3. Complete the listing: description, subtitle, keywords, Health & Fitness category, territories, pricing, age-rating questionnaire, copyright, and screenshots for every supported device family.
4. Complete App Privacy using the shipped behavior: no tracking and no data transmitted off-device. Reassess these answers if analytics, accounts, networking, advertising, or third-party SDKs are added.
5. State that Somnus is not a regulated medical device unless its legal/regulatory status changes.
6. Add Review Notes explaining that Somnus reads only Apple Health sleep-analysis data, performs all analysis on-device, has no account, and never writes Health data.
7. Give App Review a practical way to inspect data-driven screens. Reviewers without Apple Watch sleep history will otherwise see the intentional no-data state; decide whether to provide review instructions/hardware context or ship a clearly disclosed sample-data mode.
8. Upload the exported build through Xcode Organizer or App Store Connect and run Apple's server-side validation before submitting for review.

## Suggested Review Notes

> Somnus is a read-only HealthKit sleep-analysis app. It requests access only after the user taps the onboarding or Settings connection button. Sleep scores, debt, and trends are calculated entirely on-device; the app has no account, analytics, advertising, backend, or third-party SDKs and never writes Health data. Users may skip Health access and browse the app's no-data guidance and Settings. Full charts require sleep-analysis samples already present in Apple Health.

## Reverification commands

```bash
xcodegen generate
xcodebuild -project Somnus.xcodeproj -scheme Somnus \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
xcodebuild -project Somnus.xcodeproj -scheme Somnus -configuration Release \
  -destination 'generic/platform=iOS' -archivePath /private/tmp/Somnus-release.xcarchive archive
```
