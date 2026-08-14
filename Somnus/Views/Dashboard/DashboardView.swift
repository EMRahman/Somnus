import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject private var navigation: AppNavigation

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.hasNoData && !viewModel.isLoading {
                        // No data at all: guidance beats a "0 — Very Poor" score ring
                        emptyState
                    } else {
                        // Last Night Header
                        lastNightHeader

                        // Sleep Score Ring
                        SleepScoreRing(score: viewModel.sleepScore)
                            .padding(.vertical, 8)

                        // Sleep Debt — the headline stat, colored by how serious it is
                        debtHeroCard

                        // Sleep Stages (visual bar only; minute counts live in More Detail)
                        if let record = viewModel.latestRecord {
                            stageBarSection(record)
                        }

                        // Everything diagnostic — collapsed by default
                        moreDetailSection
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .overlay {
                if viewModel.isLoading && viewModel.latestRecord == nil {
                    // Initial load: branded full-screen splash (continues the launch screen)
                    LoadingView(message: "Loading your sleep data…")
                } else if viewModel.isLoading {
                    // Subsequent loads/refresh: lightweight inline spinner
                    ProgressView("Loading sleep data...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Sleep Data Yet", systemImage: "moon.zzz")
        } description: {
            Text("Wear your Apple Watch to bed tonight, then check back in the morning. Already tracking sleep? Make sure Somnus has Health access in Settings → Privacy & Security → Health.")
        }
        .padding(.top, 60)
    }

    private var lastNightHeader: some View {
        VStack(spacing: 6) {
            Text("Last Night")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            Text(viewModel.lastNightSummary)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)

            if let record = viewModel.latestRecord {
                Text("\(record.bedtime.timeString) — \(record.wakeTime.timeString)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// Tapping the headline debt stat deep-links to the full Sleep Debt breakdown in Trends.
    private var debtHeroCard: some View {
        Button {
            navigation.showSleepDebt()
        } label: {
            PrimaryMetricCard(
                title: "Sleep Debt",
                value: viewModel.sleepDebtText,
                subtitle: viewModel.sleepDebtSubtitle,
                icon: "exclamationmark.arrow.circlepath",
                color: severityColor(viewModel.debtSeverity)
            )
            .overlay(alignment: .topTrailing) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
                    .padding(12)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Sleep Debt breakdown in Trends")
    }

    /// Tapping the stage breakdown deep-links to the Sleep Duration chart in Trends (weekly).
    private func stageBarSection(_ record: SleepRecord) -> some View {
        Button {
            navigation.showSleepDuration()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sleep Stages")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                }

                SleepStageBar(
                    stages: SleepAnalysisEngine.stageBreakdown(for: record)
                )
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Sleep Duration chart in Trends")
    }

    /// Score breakdown, stage-minute counts, and target compliance — useful, but not what a
    /// tired glance needs; tucked behind a tap instead of competing with the headline stats.
    private var moreDetailSection: some View {
        DisclosureGroup("More Detail") {
            VStack(alignment: .leading, spacing: 16) {
                ScoreBreakdown(score: viewModel.sleepScore)

                if let record = viewModel.latestRecord {
                    HStack(spacing: 16) {
                        stageDetail("Deep", minutes: record.deepSleepDuration / 60, color: .stageDeep)
                        stageDetail("REM", minutes: record.remSleepDuration / 60, color: .stageREM)
                        stageDetail("Core", minutes: record.coreSleepDuration / 60, color: .stageCore)
                        stageDetail("Awake", minutes: record.awakeDuration / 60, color: .stageAwake)
                    }
                }

                HStack(spacing: 12) {
                    MetricCard(
                        title: "Target Nights",
                        value: viewModel.targetComplianceText,
                        icon: "target",
                        accentColor: .green
                    )

                    MetricCard(
                        title: "Efficiency",
                        value: viewModel.weeklyMetrics.map { String(format: "%.0f%%", $0.averageEfficiency * 100) } ?? "—",
                        icon: "gauge.with.dots.needle.67percent",
                        accentColor: .blue
                    )
                }
            }
            .padding(.top, 12)
        }
        .tint(.primary)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func severityColor(_ severity: StatSeverity) -> Color {
        switch severity {
        case .normal: return .green
        case .concerning: return .statConcerning
        case .critical: return .statCritical
        }
    }

    private func stageDetail(_ label: String, minutes: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.0f", minutes))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("min")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

}

#Preview {
    DashboardView()
        .environmentObject(AppNavigation())
}
