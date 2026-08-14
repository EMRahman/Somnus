import SwiftUI
import Charts

struct TrendsView: View {
    @StateObject private var viewModel = TrendsViewModel()
    @EnvironmentObject private var navigation: AppNavigation

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Period Selector — always visible so an empty period can be switched away from
                        periodSelector

                        // Tracked nights, not raw records: a period holding only stage-less
                        // "in bed only" records should get the guidance, not 0-hour charts.
                        if (viewModel.metrics?.trackedNightCount ?? 0) == 0 && !viewModel.isLoading {
                            emptyState
                        } else {
                            // Summary Stats
                            summaryCards

                            // Sleep Debt (nightly bars + cumulative-debt line) — above duration so
                            // the Dashboard's headline stat leads the Trends detail too.
                            if !viewModel.debtChartData.isEmpty {
                                sleepDebtSection
                                    .id(AppNavigation.TrendsSection.sleepDebt)
                            }

                            // Duration Chart
                            durationChart
                                .id(AppNavigation.TrendsSection.sleepDuration)

                            // Patterns (weekend gap, late bedtimes, stage imbalance)
                            if !viewModel.patternFlags.isEmpty {
                                patternsSection
                            }

                            // Detail Metrics
                            detailMetrics
                        }
                    }
                    .padding()
                }
                .navigationTitle("Trends")
                .task {
                    // Consume a deep-link period request here too: on a first visit `.onChange`
                    // doesn't fire for a value set before this view began observing, so `.task` —
                    // which always runs on first appear — is the reliable place to apply it.
                    let requestedPeriod = navigation.trendsPeriodRequest
                    navigation.trendsPeriodRequest = nil
                    if let requestedPeriod, viewModel.selectedPeriod != requestedPeriod {
                        await viewModel.changePeriod(to: requestedPeriod)
                    } else {
                        await viewModel.loadData()
                    }
                    // Drop a deep-link target this period can't satisfy, so it can't fire later when
                    // an unrelated reload happens to add data.
                    if let target = navigation.trendsScrollTarget, !isSectionAvailable(target) {
                        navigation.trendsScrollTarget = nil
                    } else {
                        // A target supplied before Trends first appears won't trigger `onChange`.
                        // Fulfill it explicitly after the initial load has rendered its section.
                        scrollToPendingSection(proxy)
                    }
                }
                .overlay {
                    if viewModel.isLoading && viewModel.records.isEmpty {
                        // Initial load: branded full-screen splash (continues the launch screen)
                        LoadingView()
                    } else if viewModel.isLoading {
                        ProgressView()
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
                // A deep link may request a period switch first; adopt it (reloading if needed)
                // before scrolling so the target section reflects the requested timeframe.
                .onChange(of: navigation.trendsPeriodRequest) { _, requested in
                    guard let requested else { return }
                    navigation.trendsPeriodRequest = nil
                    if viewModel.selectedPeriod == requested {
                        scrollToPendingSection(proxy)
                    } else {
                        Task { await viewModel.changePeriod(to: requested) }
                    }
                }
                // Fulfill a deep-link scroll when it's requested (Trends already loaded) and again
                // once a load settles and the target section has appeared.
                .onChange(of: navigation.trendsScrollTarget) { _, target in
                    if target != nil { scrollToPendingSection(proxy) }
                }
                .onChange(of: viewModel.isLoading) { _, loading in
                    if !loading { scrollToPendingSection(proxy) }
                }
            }
        }
    }

    /// Fulfills a pending deep-link scroll once its target section exists and any requested period
    /// has been applied. Deferred one runloop so the tab switch and layout settle first, then
    /// cleared so it fires exactly once.
    private func scrollToPendingSection(_ proxy: ScrollViewProxy) {
        guard navigation.trendsPeriodRequest == nil else { return }        // wait for the period switch
        guard let target = navigation.trendsScrollTarget else { return }
        guard !viewModel.isLoading, isSectionAvailable(target) else { return }
        // Clear synchronously so multiple triggers in the same runloop (e.g. isLoading and the
        // target both changing) can't each schedule a redundant scroll animation.
        navigation.trendsScrollTarget = nil
        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo(target, anchor: .top)
            }
        }
    }

    /// Whether the deep-link target section is currently rendered (and therefore scrollable) for
    /// the loaded period. Duration shows whenever there are tracked nights; debt also needs bars.
    private func isSectionAvailable(_ section: AppNavigation.TrendsSection) -> Bool {
        guard (viewModel.metrics?.trackedNightCount ?? 0) > 0 else { return false }
        switch section {
        case .sleepDuration: return true
        case .sleepDebt: return !viewModel.debtChartData.isEmpty
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Sleep Data", systemImage: "moon.zzz")
        } description: {
            Text("Nothing recorded in this period. Try a longer period, or make sure Somnus has Health access in Settings → Privacy & Security → Health.")
        }
        .padding(.top, 40)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    Task { await viewModel.changePeriod(to: period) }
                } label: {
                    Text(period.shortLabel)
                        .font(.footnote)
                        .fontWeight(viewModel.selectedPeriod == period ? .semibold : .regular)
                        .foregroundStyle(viewModel.selectedPeriod == period ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 2)
                        .background(
                            viewModel.selectedPeriod == period
                                ? Color.purple
                                : Color.clear
                        )
                }
            }
        }
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            PrimaryMetricCard(
                title: "Average Sleep",
                value: viewModel.averageSleepText,
                subtitle: viewModel.selectedPeriod.chartLabel,
                icon: "moon.fill",
                color: .purple
            )

            PrimaryMetricCard(
                title: "Target Rate",
                value: viewModel.targetRateText,
                subtitle: "\(hoursLabel(minimumHours))+ hours",
                icon: "target",
                color: targetRateColor
            )
        }
    }

    private var targetRateColor: Color {
        if viewModel.targetRate >= 0.85 { return .green }
        if viewModel.targetRate >= 0.60 { return .yellow }
        return .orange
    }

    // MARK: - Duration Chart

    private var durationChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sleep Duration")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: viewModel.durationTrend.systemImage)
                    Text(viewModel.durationTrend.rawValue)
                }
                .font(.caption)
                .foregroundStyle(trendColor(viewModel.durationTrend))
            }

            // Short periods show a per-night timeline (clock-time axis + stage-coloured bars);
            // longer periods average nights into buckets, so they keep the duration bar chart.
            if showTimeline {
                SleepTimelineChart(nights: viewModel.timelineData)
            } else {
                averagedDurationChart
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// Whether to draw the per-night sleep timeline instead of averaged duration bars.
    private var showTimeline: Bool {
        switch viewModel.selectedPeriod {
        case .daily, .weekly: return !viewModel.timelineData.isEmpty
        default: return false
        }
    }

    private var averagedDurationChart: some View {
        Chart {
            // Goal zone: the user's Minimum Acceptable → Target Sleep band from Settings
            RectangleMark(
                yStart: .value("Min", targetBand.lowerBound),
                yEnd: .value("Max", targetBand.upperBound)
            )
            .foregroundStyle(Color.green.opacity(0.1))

            // Minimum-acceptable line
            RuleMark(y: .value("Target", minimumHours))
                .foregroundStyle(Color.green.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .annotation(position: .trailing, alignment: .leading) {
                    Text(hoursLabel(minimumHours))
                        .font(.caption2)
                        .foregroundStyle(.green)
                }

            // Data bars. Anchor to the domain floor (not 0) so a zoomed axis doesn't let the
            // bars overflow below the plot and cover the x-axis labels.
            ForEach(viewModel.chartData) { point in
                let fitsInline = durationBarVisibleHeight(point.hours) >= durationBarMinHoursForInlineLabel
                BarMark(
                    x: .value("Date", point.date, unit: chartUnit),
                    yStart: .value("Base", durationYDomain.lowerBound),
                    yEnd: .value("Hours", point.hours),
                    width: .ratio(0.8)
                )
                .foregroundStyle(point.hours >= minimumHours ? Color.chartBar : Color.chartBarBelow)
                .cornerRadius(4)
                .annotation(position: fitsInline ? .overlay : .top, spacing: 2) {
                    if showsBarLabels {
                        Text(durationBarLabel(point.hours))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(fitsInline ? .white : .primary)
                    }
                }
            }
        }
        .chartYScale(domain: durationYDomain)
        .chartYAxis {
            AxisMarks(values: .stride(by: 1)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text("\(Int(hours))h")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            // Place labels only at (a thinned set of) the actual bar dates. Charts' automatic
            // date ticks render one-per-interval (e.g. per day across a month), which overruns
            // the width and collides with the bars; desiredCount isn't honoured for these
            // unit-binned bars, so we pin the marks ourselves.
            AxisMarks(values: thinnedDates(viewModel.chartData)) { _ in
                AxisGridLine()
                AxisValueLabel(format: chartDateFormat)
            }
        }
        .frame(height: 220)
    }

    /// The user's Minimum Acceptable from Settings — the threshold for the rule mark and
    /// bar coloring, used directly (not via `targetBand`) so a minimum configured above
    /// the target still colors sub-minimum nights orange.
    private var minimumHours: Double {
        SleepAnalysisEngine.minimumAcceptableHours
    }

    /// The user's goal band from Settings (Minimum Acceptable → Target Sleep), replacing the
    /// old hardcoded 7–8h zone. Ordered defensively since the two sliders are independent.
    private var targetBand: ClosedRange<Double> {
        min(minimumHours, SleepAnalysisEngine.targetSleepHours)...max(minimumHours, SleepAnalysisEngine.targetSleepHours)
    }

    /// Compact hours label without trailing zeros, e.g. "7h" or "6.5h".
    private func hoursLabel(_ hours: Double) -> String {
        String(format: "%gh", hours)
    }

    /// Y-axis range for the averaged duration bars. Tightens to the data (so trends across
    /// months/years are legible instead of dwarfed by a fixed 0–10h axis) while always keeping
    /// the goal band in view.
    private var durationYDomain: ClosedRange<Double> {
        let hours = viewModel.chartData.map(\.hours)
        let lower = (min(hours.min() ?? targetBand.lowerBound, targetBand.lowerBound)).rounded(.down)
        let upper = (max(hours.max() ?? targetBand.upperBound, targetBand.upperBound)).rounded(.up)
        return lower...upper
    }

    /// Per-bar duration label, matching the compact one-decimal treatment used by sleep debt.
    private func durationBarLabel(_ hours: Double) -> String {
        String(format: "%.1fh", hours)
    }

    /// Height represented by the visible portion of a duration bar. Duration bars start at the
    /// tightened y-axis floor rather than zero, so label fit must use this displayed height.
    private func durationBarVisibleHeight(_ hours: Double) -> Double {
        max(0, hours - durationYDomain.lowerBound)
    }

    /// Minimum visible bar height needed to keep the duration label inside the bar.
    private var durationBarMinHoursForInlineLabel: Double {
        let neededPoints: Double = 18
        let chartHeight: Double = 220
        return (durationYDomain.upperBound - durationYDomain.lowerBound) * (neededPoints / chartHeight)
    }

    /// Numeric bar labels are useful for short and medium periods, but become cluttered once
    /// the charts show a year or more of buckets.
    private var showsBarLabels: Bool {
        switch viewModel.selectedPeriod {
        case .daily, .weekly, .monthly: return true
        case .yearly, .fiveYears, .tenYears: return false
        }
    }

    /// A subset of the points' dates for x-axis labels — at most `limit`, evenly sampled — so
    /// month/week labels stay readable instead of overlapping on the denser periods.
    private func thinnedDates(_ points: [SleepChartDataPoint], limit: Int = 6) -> [Date] {
        let dates = points.map(\.date)
        guard dates.count > limit else { return dates }
        let step = Int((Double(dates.count) / Double(limit)).rounded(.up))
        return dates.enumerated().compactMap { index, date in
            index % step == 0 ? date : nil
        }
    }

    private var chartUnit: Calendar.Component {
        switch viewModel.selectedPeriod {
        case .daily: return .hour
        case .weekly: return .day
        case .monthly: return .weekOfYear
        case .yearly: return .month
        case .fiveYears, .tenYears: return .year
        }
    }

    private var chartDateFormat: Date.FormatStyle {
        switch viewModel.selectedPeriod {
        case .daily: return .dateTime.hour()
        case .weekly: return .dateTime.weekday(.abbreviated)
        case .monthly: return .dateTime.day()
        case .yearly: return .dateTime.month(.abbreviated)
        case .fiveYears, .tenYears: return .dateTime.year()
        }
    }

    // MARK: - Sleep Debt

    private var sleepDebtSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header + summary
            VStack(alignment: .leading, spacing: 4) {
                Text("Sleep Debt")
                    .font(.headline)
                Text("\(viewModel.runningBalanceText) · \(viewModel.avgNightlyDebtText)")
                    .font(.subheadline)
                    .fontWeight(viewModel.debtSeverity == .normal ? .regular : .semibold)
                    .foregroundStyle(severityColor(viewModel.debtSeverity))
            }

            // Nightly debt bars overlaid on the cumulative-debt line. The line is the running
            // total of the bars, so its rise between two days is exactly that day's bar — both
            // share a single hours axis, which makes the correlation read directly.
            Chart {
                // Nightly debt bars
                ForEach(viewModel.debtChartData) { point in
                    let fitsInline = point.hours >= debtBarMinHoursForInlineLabel
                    BarMark(
                        x: .value("Date", point.date, unit: chartUnit),
                        y: .value("Nightly debt", point.hours)
                    )
                    .foregroundStyle(Color.chartBarBelow)
                    .cornerRadius(4)
                    .annotation(position: fitsInline ? .overlay : .top, spacing: 2) {
                        if showsBarLabels, let text = debtBarLabel(point.hours) {
                            Text(text)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(fitsInline ? .white : .primary)
                        }
                    }
                }

                // Cumulative debt line (running total of the bars)
                ForEach(viewModel.cumulativeDebtData) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: chartUnit),
                        y: .value("Cumulative debt", point.hours)
                    )
                    .foregroundStyle(Color.chartBar)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(.circle)
                    .symbolSize(cumulativeMarkerSize)
                }
            }
            .chartYScale(domain: 0...cumulativeDebtYMax)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                // Label every day on short periods; let Charts thin labels on longer ones.
                if viewModel.selectedPeriod == .daily || viewModel.selectedPeriod == .weekly {
                    AxisMarks(values: viewModel.debtChartData.map(\.date)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: chartDateFormat)
                    }
                } else {
                    AxisMarks(values: thinnedDates(viewModel.debtChartData)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: chartDateFormat)
                    }
                }
            }
            .frame(height: 200)

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.chartBarBelow)
                        .frame(width: 10, height: 10)
                    Text("Nightly debt")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 5) {
                    Capsule()
                        .fill(Color.chartBar)
                        .frame(width: 16, height: 3)
                    Text("Cumulative debt")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// Upper bound for the sleep-debt chart's y-axis — the peak cumulative debt plus a little
    /// headroom, at least 1h so a debt-free period still renders a sensible axis.
    private var cumulativeDebtYMax: Double {
        let maxDebt = viewModel.cumulativeDebtData.map(\.hours).max() ?? 0
        return max(1, (maxDebt * 1.15).rounded(.up))
    }

    /// Per-bar debt label, e.g. "0.2h" / "1.3h" — nil when it rounds to zero, since there's no
    /// meaningful bar to anchor a "0.0h" label to.
    private func debtBarLabel(_ hours: Double) -> String? {
        let formatted = String(format: "%.1fh", hours)
        return formatted == "0.0h" ? nil : formatted
    }

    /// Minimum nightly-debt height (in hours) for its label to fit fully inside the bar, given
    /// the chart's fixed 200pt height and the current y-axis domain. Shorter bars get the label
    /// positioned above instead.
    private var debtBarMinHoursForInlineLabel: Double {
        let neededPoints: Double = 18
        let chartHeight: Double = 200
        return cumulativeDebtYMax * (neededPoints / chartHeight)
    }

    /// Marker size for the cumulative line — visible per-day dots on short periods, hidden on
    /// longer ones where a dot per bucket would clutter the line.
    private var cumulativeMarkerSize: Double {
        switch viewModel.selectedPeriod {
        case .daily, .weekly: return 40
        default: return 0
        }
    }

    // MARK: - Patterns

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patterns")
                .font(.headline)

            ForEach(viewModel.patternFlags) { flag in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: flag.systemImage)
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(flag.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(flag.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Detail Metrics

    /// Bedtime/wake averages, stage minutes, efficiency, record count — reference detail for
    /// someone who wants it, not what a quick check needs. Collapsed by default.
    private var detailMetrics: some View {
        DisclosureGroup("More Detail") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Avg Bedtime",
                    value: viewModel.averageBedtimeText,
                    icon: "bed.double.fill",
                    accentColor: .indigo
                )

                MetricCard(
                    title: "Avg Wake",
                    value: viewModel.averageWakeTimeText,
                    icon: "sunrise.fill",
                    accentColor: .orange
                )

                MetricCard(
                    title: "Deep Sleep",
                    value: viewModel.deepSleepText,
                    icon: "waveform.path",
                    accentColor: .stageDeep
                )

                MetricCard(
                    title: "REM Sleep",
                    value: viewModel.remSleepText,
                    icon: "eye.fill",
                    accentColor: .stageREM
                )

                MetricCard(
                    title: "Efficiency",
                    value: viewModel.efficiencyText,
                    icon: "gauge.with.dots.needle.67percent",
                    accentColor: .blue
                )

                MetricCard(
                    title: "Records",
                    value: "\(viewModel.metrics?.trackedNightCount ?? 0) nights",
                    icon: "calendar",
                    accentColor: .gray
                )
            }
            .padding(.top, 12)
        }
        .tint(.primary)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func trendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .improving: return .trendImproving
        case .stable: return .trendStable
        case .declining: return .trendDeclining
        }
    }

    /// Only paints when something's actually wrong — a normal debt reads as plain secondary
    /// text rather than adding another color to a screen that already has plenty.
    private func severityColor(_ severity: StatSeverity) -> Color {
        switch severity {
        case .normal: return .secondary
        case .concerning: return .statConcerning
        case .critical: return .statCritical
        }
    }
}

#Preview {
    TrendsView()
        .environmentObject(AppNavigation())
}
