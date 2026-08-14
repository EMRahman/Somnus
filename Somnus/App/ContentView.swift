import SwiftUI

/// App-wide navigation coordinator for cross-tab deep links — e.g. the Dashboard's Sleep Debt
/// card jumping straight to the Trends sleep-debt section. Owned by `ContentView` and injected
/// into the tabs via `.environmentObject`.
@MainActor
final class AppNavigation: ObservableObject {
    enum Tab: Int, Hashable {
        case dashboard = 0
        case trends = 1
        case settings = 2
    }

    /// A section within the Trends tab that another screen can request we scroll to.
    enum TrendsSection: Hashable {
        case sleepDuration
        case sleepDebt
    }

    @Published var selectedTab: Tab = .dashboard

    /// Set by a deep link to ask `TrendsView` to scroll to a section once it's on screen and its
    /// data has loaded. `TrendsView` clears it after scrolling (or when there's nothing to show).
    @Published var trendsScrollTarget: TrendsSection?

    /// A period a deep link wants Trends to adopt before scrolling — the Dashboard cards summarize
    /// the week, so they deep-link into the weekly view. `TrendsView` applies and clears it.
    @Published var trendsPeriodRequest: TimePeriod?

    init() {
        #if DEBUG
        guard ScreenshotSupport.isEnabled else { return }

        switch ScreenshotSupport.destination {
        case .dashboard:
            selectedTab = .dashboard
        case .sleepDebt:
            selectedTab = .trends
            trendsPeriodRequest = .weekly
        case .sleepDuration:
            selectedTab = .trends
            trendsPeriodRequest = .weekly
            trendsScrollTarget = .sleepDuration
        case .monthlyDuration:
            selectedTab = .trends
            trendsPeriodRequest = .monthly
        }
        #endif
    }

    /// Switch to the Trends tab, select the weekly period, and scroll to the sleep-debt section.
    func showSleepDebt() {
        showTrendsSection(.sleepDebt, period: .weekly)
    }

    /// Switch to the Trends tab, select the weekly period, and scroll to the sleep-duration section.
    func showSleepDuration() {
        showTrendsSection(.sleepDuration, period: .weekly)
    }

    private func showTrendsSection(_ section: TrendsSection, period: TimePeriod) {
        trendsPeriodRequest = period
        trendsScrollTarget = section
        selectedTab = .trends
    }
}

struct ContentView: View {
    @StateObject private var navigation = AppNavigation()

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "moon.fill")
                }
                .tag(AppNavigation.Tab.dashboard)

            TrendsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.xyaxis.line")
                }
                .tag(AppNavigation.Tab.trends)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppNavigation.Tab.settings)
        }
        .tint(.purple)
        .environmentObject(navigation)
    }
}

#Preview {
    ContentView()
}
