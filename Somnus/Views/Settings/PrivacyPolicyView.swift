import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Last updated: 14 August 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                policySection(
                    title: "Data Somnus Accesses",
                    text: "With your permission, Somnus reads sleep analysis data from Apple Health, including sleep and wake times and sleep stages. Somnus requests read-only access and never writes to your Health records."
                )

                policySection(
                    title: "How Data Is Used",
                    text: "Your sleep data is processed on your device to calculate sleep scores, sleep debt, trends, and related educational insights. It is not used for advertising, marketing, profiling, or data mining."
                )

                policySection(
                    title: "Collection and Sharing",
                    text: "Somnus does not transmit your health data or other personal data to a developer-operated server. The app has no accounts, analytics, advertising, or third-party software development kits, and does not sell or share Health data. External resources open outside Somnus and are governed by their own privacy policies."
                )

                policySection(
                    title: "Storage and Retention",
                    text: "Health data remains in Apple Health and is held in memory only while Somnus needs it to display your results. Somnus stores your sleep-goal preferences and onboarding status locally on your device until you change them or delete the app. Somnus does not store Health data in iCloud."
                )

                policySection(
                    title: "Your Choices and Deletion",
                    text: "You can revoke Somnus’s Health access at any time in Apple Health or in Settings under Privacy & Security → Health. Deleting Somnus removes its locally stored preferences. Your Health records remain under your control in Apple Health and can be managed there."
                )

                policySection(
                    title: "Health Disclaimer",
                    text: "Somnus provides educational wellness insights. It is not a medical device and does not diagnose, treat, cure, or prevent any condition. Seek advice from a qualified healthcare professional for medical concerns."
                )
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policySection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(text)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
