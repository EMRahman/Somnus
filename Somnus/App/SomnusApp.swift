import SwiftUI

@main
struct SomnusApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .preferredColorScheme(.dark)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .preferredColorScheme(.dark)
            }
        }
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var isRequestingAccess = false

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                onboardingPage(
                    icon: "moon.stars.fill",
                    title: "Welcome to Somnus",
                    subtitle: "Understand your sleep. Transform your health.",
                    description: "Somnus analyzes your Apple Watch sleep data to reveal patterns, score your sleep quality, and track your sleep debt to help you consistently achieve 7-8 hours of restorative sleep."
                )
                .tag(0)

                onboardingPage(
                    icon: "chart.xyaxis.line",
                    title: "Track Your Trends",
                    subtitle: "Daily, weekly, monthly, yearly, even 5 or 10 years.",
                    description: "See how your sleep changes over time with detailed charts showing duration, sleep stages, efficiency, and consistency. Spot patterns you'd never notice on your own."
                )
                .tag(1)

                onboardingPage(
                    icon: "exclamationmark.arrow.circlepath",
                    title: "Know Your Sleep Debt",
                    subtitle: "The number Apple Health won't show you.",
                    description: "Somnus tracks your cumulative shortfall against your personal target — night by night, and running over weeks, months, or years — so you can see debt build up, and pay it down, instead of guessing."
                )
                .tag(2)

                healthAccessPage
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Navigation
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation { currentPage -= 1 }
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if currentPage < 3 {
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Next")
                            Image(systemName: "arrow.right")
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    private func onboardingPage(icon: String, title: String, subtitle: String, description: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.purple)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(subtitle)
                    .font(.headline)
                    .foregroundStyle(.purple)
            }

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding()
    }

    private var healthAccessPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.pink)

            VStack(spacing: 8) {
                Text("Connect Health Data")
                    .font(.title)
                    .fontWeight(.bold)

                Text("We need access to your sleep data")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Text("Somnus reads sleep data from Apple Health to provide analysis. Your data never leaves your device. We only read sleep information — nothing else.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button {
                    Task {
                        isRequestingAccess = true
                        do {
                            try await HealthKitManager.shared.requestAuthorization()
                        } catch {
                            // User can still continue without granting access
                        }
                        isRequestingAccess = false
                        hasCompletedOnboarding = true
                    }
                } label: {
                    HStack {
                        if isRequestingAccess {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.shield.fill")
                        }
                        Text("Grant Access & Get Started")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isRequestingAccess)

                Button("Skip for Now") {
                    hasCompletedOnboarding = true
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding()
    }
}

#Preview("Onboarding") {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .preferredColorScheme(.dark)
}

#Preview("Main App") {
    ContentView()
}
