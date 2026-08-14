import Foundation

@MainActor
final class TrendsViewModel: ObservableObject {

    // MARK: - Published State

    @Published var selectedPeriod: TimePeriod = .weekly
    @Published var records: [SleepRecord] = []
    @Published var metrics: SleepMetrics?
    @Published var chartData: [SleepChartDataPoint] = []
    /// Per-night bars for the sleep timeline chart (daily/weekly only).
    @Published var timelineData: [NightTimelinePoint] = []
    @Published var debtChartData: [SleepChartDataPoint] = []
    /// Running total of the nightly debt bars — each point's rise equals that bucket's bar.
    @Published var cumulativeDebtData: [SleepChartDataPoint] = []
    @Published var patternFlags: [SleepPatternFlag] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let healthKitManager = HealthKitManager.shared

    // MARK: - Computed Properties

    var averageSleepText: String {
        guard let metrics else { return "—" }
        return String(format: "%.1f hours", metrics.averageSleepHours)
    }

    var averageBedtimeText: String {
        guard let time = metrics?.averageBedtime else { return "—" }
        return time.timeString
    }

    var averageWakeTimeText: String {
        guard let time = metrics?.averageWakeTime else { return "—" }
        return time.timeString
    }

    var efficiencyText: String {
        guard let metrics else { return "—" }
        return String(format: "%.0f%%", metrics.averageEfficiency * 100)
    }

    var durationTrend: TrendDirection {
        metrics?.sleepDurationTrend ?? .stable
    }

    var targetRate: Double {
        metrics?.targetComplianceRate ?? 0
    }

    var targetRateText: String {
        guard let metrics else { return "—" }
        return String(format: "%.0f%%", metrics.targetComplianceRate * 100)
    }

    var deepSleepText: String {
        guard let metrics else { return "—" }
        return String(format: "%.0f min", metrics.averageDeepSleepMinutes)
    }

    var remSleepText: String {
        guard let metrics else { return "—" }
        return String(format: "%.0f min", metrics.averageREMSleepMinutes)
    }

    // MARK: - Sleep Debt

    /// The user's nightly goal used for the sleep-debt section.
    var sleepTarget: Double {
        SleepAnalysisEngine.targetSleepHours
    }

    /// Net running balance versus the goal, e.g. "4.2h behind goal" or "0.8h ahead".
    var runningBalanceText: String {
        guard let metrics else { return "—" }
        let balance = metrics.targetRunningBalance
        if balance < -0.05 {
            return String(format: "%.1fh behind goal", -balance)
        } else if balance > 0.05 {
            return String(format: "%.1fh ahead", balance)
        }
        return "On goal"
    }

    /// Average nightly shortfall/surplus magnitude, e.g. "0.6h/night".
    var avgNightlyDebtText: String {
        guard let metrics else { return "—" }
        return String(format: "%.1fh/night", abs(metrics.averageNightlyBalance))
    }

    /// Drives the debt section's color — escalates when accumulated shortfall crosses a
    /// threshold worth calling out, matching the Dashboard hero card's logic.
    var debtSeverity: StatSeverity {
        SleepAnalysisEngine.debtSeverity(hours: metrics?.totalSleepDebt ?? 0)
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        errorMessage = nil

        #if DEBUG
        if ScreenshotSupport.isEnabled {
            records = ScreenshotSupport.records(for: selectedPeriod)
            metrics = SleepAnalysisEngine.computeMetrics(records: records, period: selectedPeriod)
            updateChartData()
            isLoading = false
            return
        }
        #endif

        guard await healthKitManager.hasCompletedAuthorizationRequest() else {
            records = []
            metrics = nil
            chartData = []
            timelineData = []
            debtChartData = []
            cumulativeDebtData = []
            patternFlags = []
            isLoading = false
            return
        }

        do {
            records = try await healthKitManager.fetchSleepRecords(for: selectedPeriod)
            metrics = SleepAnalysisEngine.computeMetrics(records: records, period: selectedPeriod)
            updateChartData()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func changePeriod(to period: TimePeriod) async {
        selectedPeriod = period
        await loadData()
    }

    // MARK: - Chart Data

    private func updateChartData() {
        // Only nights with recorded sleep count toward debt. Stage-less "in bed only"
        // nights (common before Apple Watch sleep stages arrived in ~2022) read as 0h
        // and would otherwise register as a full night of phantom debt.
        let tracked = records.filter { $0.totalSleepHours > 0 }
        let target = SleepAnalysisEngine.targetSleepHours

        patternFlags = SleepAnalysisEngine.detectPatterns(from: records)

        // Debt per bucket = sum of each night's shortfall in that bucket. Daily/weekly buckets
        // are single nights; monthly and longer sum every night in the week/month/year so the
        // cumulative line below tracks real accumulated debt, not the debt of an average night.
        debtChartData = SleepAnalysisEngine.debtByBucket(from: tracked, target: target, period: selectedPeriod)

        // Cumulative debt = running total of the debt bars, so the line's bucket-over-bucket
        // rise is exactly that bar (the bars and line share one hours axis).
        var runningDebt = 0.0
        cumulativeDebtData = debtChartData.map { point in
            runningDebt += point.hours
            return SleepChartDataPoint(date: point.date, hours: runningDebt, label: point.label)
        }

        // Per-night timeline (clock-time axis + stage-coloured bars) is only meaningful for
        // short periods where each bar is an individual night with bedtime/wake/stage detail.
        // Longer periods average nights into buckets, so they keep the duration bar chart.
        switch selectedPeriod {
        case .daily, .weekly:
            chartData = SleepAnalysisEngine.durationChartData(from: records)
            timelineData = SleepAnalysisEngine.nightlyTimeline(from: records)

        case .monthly:
            chartData = SleepAnalysisEngine.weeklyAverages(from: records)
            timelineData = []

        case .yearly:
            chartData = SleepAnalysisEngine.monthlyAverages(from: records)
            timelineData = []

        case .fiveYears, .tenYears:
            chartData = SleepAnalysisEngine.yearlyAverages(from: records)
            timelineData = []
        }
    }

    // MARK: - Preview Support

    #if DEBUG
    static var preview: TrendsViewModel {
        let vm = TrendsViewModel()
        vm.records = SleepRecord.previewRecords
        vm.metrics = SleepAnalysisEngine.computeMetrics(records: SleepRecord.previewRecords, period: .weekly)
        vm.chartData = SleepAnalysisEngine.durationChartData(from: SleepRecord.previewRecords)
        let previewTarget = SleepAnalysisEngine.targetSleepHours
        vm.debtChartData = SleepAnalysisEngine.debtByBucket(
            from: SleepRecord.previewRecords, target: previewTarget, period: .weekly
        )
        var running = 0.0
        vm.cumulativeDebtData = vm.debtChartData.map { point in
            running += point.hours
            return SleepChartDataPoint(date: point.date, hours: running, label: point.label)
        }
        vm.timelineData = SleepAnalysisEngine.nightlyTimeline(from: SleepRecord.previewRecords)
        vm.patternFlags = SleepAnalysisEngine.detectPatterns(from: SleepRecord.previewRecords)
        return vm
    }
    #endif
}
