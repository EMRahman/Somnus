import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - Published State

    @Published var latestRecord: SleepRecord?
    @Published var weeklyRecords: [SleepRecord] = []
    @Published var weeklyMetrics: SleepMetrics?
    @Published var sleepScore: SleepScore = .zero
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let healthKitManager = HealthKitManager.shared
    private var isObservingHealthKit = false

    // MARK: - Computed Properties

    /// True when no *tracked* sleep was loaded — the view pairs this with `isLoading` to
    /// decide whether to show the empty state instead of a "0 — Very Poor" score ring.
    /// Counts tracked nights, not raw records, so a week of stage-less "in bed only"
    /// records still gets the guidance screen.
    var hasNoData: Bool {
        latestRecord == nil && (weeklyMetrics?.trackedNightCount ?? 0) == 0
    }

    var lastNightSummary: String {
        guard let record = latestRecord else {
            return "No sleep data available"
        }
        let hours = record.totalSleepHours
        if hours >= SleepAnalysisEngine.minimumAcceptableHours {
            return "You slept \(String(format: "%.1f", hours)) hours last night"
        } else {
            return "Only \(String(format: "%.1f", hours)) hours last night"
        }
    }

    var scoreGrade: SleepGrade {
        sleepScore.grade
    }

    var targetComplianceText: String {
        guard let metrics = weeklyMetrics else { return "—" }
        return "\(metrics.nightsMeetingTarget)/\(metrics.trackedNightCount) nights"
    }

    var weeklyAverageText: String {
        guard let metrics = weeklyMetrics else { return "—" }
        return String(format: "%.1fh avg", metrics.averageSleepHours)
    }

    var sleepDebtText: String {
        guard let metrics = weeklyMetrics else { return "—" }
        let debt = metrics.totalSleepDebt
        if debt < 0.5 { return "No debt" }
        return String(format: "%.1fh debt", debt)
    }

    /// Companion line under the debt hero card, folding in the weekly average so it doesn't
    /// need its own separate card.
    var sleepDebtSubtitle: String {
        guard let metrics = weeklyMetrics else { return "This Week" }
        return String(format: "avg %.1fh/night this week", metrics.averageSleepHours)
    }

    /// Drives the debt hero card's color — escalates when the week's shortfall crosses a
    /// threshold worth calling out, rather than treating every debt figure the same.
    var debtSeverity: StatSeverity {
        SleepAnalysisEngine.debtSeverity(hours: weeklyMetrics?.totalSleepDebt ?? 0)
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        errorMessage = nil

        #if DEBUG
        if ScreenshotSupport.isEnabled {
            let records = ScreenshotSupport.records(for: .weekly)
            latestRecord = records.last
            weeklyRecords = records
            let metrics = SleepAnalysisEngine.computeMetrics(records: records, period: .weekly)
            weeklyMetrics = metrics
            sleepScore = metrics.score
            isLoading = false
            return
        }
        #endif

        guard await healthKitManager.hasCompletedAuthorizationRequest() else {
            latestRecord = nil
            weeklyRecords = []
            weeklyMetrics = nil
            sleepScore = .zero
            isLoading = false
            return
        }

        do {
            startObservingIfNeeded()

            // Fetch latest and weekly data in parallel
            async let latestFetch = healthKitManager.fetchLatestSleepRecord()
            async let weeklyFetch = healthKitManager.fetchSleepRecords(for: .weekly)

            latestRecord = try await latestFetch
            weeklyRecords = try await weeklyFetch

            // Compute metrics and score
            let metrics = SleepAnalysisEngine.computeMetrics(records: weeklyRecords, period: .weekly)
            weeklyMetrics = metrics
            sleepScore = metrics.score

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    /// Reloads automatically when HealthKit reports new sleep samples (e.g. after the watch
    /// syncs while the app is open). Guarded so repeated `loadData` calls — pull-to-refresh,
    /// tab switches — don't stack duplicate observers.
    private func startObservingIfNeeded() {
        guard !isObservingHealthKit else { return }
        isObservingHealthKit = true
        healthKitManager.startObservingSleepChanges { [weak self] in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    // MARK: - Preview Support

    #if DEBUG
    static var preview: DashboardViewModel {
        let vm = DashboardViewModel()
        vm.latestRecord = SleepRecord.previewRecords.last
        vm.weeklyRecords = SleepRecord.previewRecords
        let metrics = SleepAnalysisEngine.computeMetrics(records: SleepRecord.previewRecords, period: .weekly)
        vm.weeklyMetrics = metrics
        vm.sleepScore = metrics.score
        return vm
    }
    #endif
}

// MARK: - Preview Data

#if DEBUG
extension SleepRecord {
    static var previewRecords: [SleepRecord] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let sleepHours = [6.2, 7.5, 5.8, 7.1, 8.0, 6.5, 7.3][daysAgo]
            let bedHour = [23, 22, 0, 23, 22, 1, 23][daysAgo]
            let bedMinute = [30, 45, 15, 0, 30, 0, 15][daysAgo]

            let bedtime: Date
            if bedHour >= 12 {
                bedtime = calendar.date(bySettingHour: bedHour, minute: bedMinute, second: 0, of: calendar.date(byAdding: .day, value: -1, to: date)!)!
            } else {
                bedtime = calendar.date(bySettingHour: bedHour, minute: bedMinute, second: 0, of: date)!
            }

            let wakeTime = bedtime.addingTimeInterval(sleepHours * 3600 + 1800) // sleep + 30 min awake

            let stages = generatePreviewStages(bedtime: bedtime, sleepDuration: sleepHours * 3600)

            return SleepRecord(date: date, bedtime: bedtime, wakeTime: wakeTime, stages: stages)
        }.reversed()
    }

    private static func generatePreviewStages(bedtime: Date, sleepDuration: TimeInterval) -> [SleepStageSample] {
        var stages: [SleepStageSample] = []
        var currentTime = bedtime

        // Simulate realistic sleep architecture
        let cycleCount = Int(sleepDuration / (90 * 60)) // ~90 min cycles
        for cycle in 0..<max(1, cycleCount) {
            let deepRatio = max(0.05, 0.25 - Double(cycle) * 0.05) // More deep sleep early
            let remRatio = min(0.35, 0.10 + Double(cycle) * 0.05)  // More REM later
            let coreRatio = 1.0 - deepRatio - remRatio - 0.05

            let cycleDuration = min(sleepDuration / Double(max(1, cycleCount)), 5400)

            // Core sleep
            let coreDuration = cycleDuration * coreRatio
            stages.append(SleepStageSample(stage: .coreSleep, startDate: currentTime, endDate: currentTime.addingTimeInterval(coreDuration)))
            currentTime = currentTime.addingTimeInterval(coreDuration)

            // Deep sleep
            let deepDuration = cycleDuration * deepRatio
            stages.append(SleepStageSample(stage: .deepSleep, startDate: currentTime, endDate: currentTime.addingTimeInterval(deepDuration)))
            currentTime = currentTime.addingTimeInterval(deepDuration)

            // REM sleep
            let remDuration = cycleDuration * remRatio
            stages.append(SleepStageSample(stage: .remSleep, startDate: currentTime, endDate: currentTime.addingTimeInterval(remDuration)))
            currentTime = currentTime.addingTimeInterval(remDuration)

            // Brief awake
            let awakeDuration = cycleDuration * 0.05
            stages.append(SleepStageSample(stage: .awake, startDate: currentTime, endDate: currentTime.addingTimeInterval(awakeDuration)))
            currentTime = currentTime.addingTimeInterval(awakeDuration)
        }

        return stages
    }
}
#endif
