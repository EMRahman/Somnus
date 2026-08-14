import Foundation

// MARK: - Sleep Score

struct SleepScore {
    let overall: Int          // 0-100
    let durationScore: Int    // 0-100
    let efficiencyScore: Int  // 0-100
    let consistencyScore: Int // 0-100
    let stageScore: Int       // 0-100

    var grade: SleepGrade {
        SleepGrade(score: overall)
    }

    static let zero = SleepScore(
        overall: 0, durationScore: 0, efficiencyScore: 0,
        consistencyScore: 0, stageScore: 0
    )
}

enum SleepGrade: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case veryPoor = "Very Poor"

    init(score: Int) {
        switch score {
        case 90...100: self = .excellent
        case 75..<90: self = .good
        case 60..<75: self = .fair
        case 40..<60: self = .poor
        default: self = .veryPoor
        }
    }

    var systemImage: String {
        switch self {
        case .excellent: return "star.circle.fill"
        case .good: return "hand.thumbsup.circle.fill"
        case .fair: return "minus.circle.fill"
        case .poor: return "exclamationmark.circle.fill"
        case .veryPoor: return "xmark.circle.fill"
        }
    }
}

// MARK: - Aggregated Sleep Metrics

struct SleepMetrics {
    let period: TimePeriod
    let records: [SleepRecord]
    let score: SleepScore

    /// One record per tracked night — fragmented sessions merged, stage-less "in bed only"
    /// records (0h, common before Apple Watch sleep stages arrived in ~2022) dropped — the
    /// basis for every average, so a fragmented night isn't averaged as two short nights
    /// and untracked nights don't drag averages toward zero.
    private var nightlyRecords: [SleepRecord] {
        SleepAnalysisEngine.mergedNightlyRecords(from: records)
    }

    // Averages

    /// Average hours per *night*, not per record — a night fragmented into 3.5h + 3.8h
    /// sessions averages as one 7.3h night.
    var averageSleepHours: Double {
        let nights = nightlySleepHours
        guard !nights.isEmpty else { return 0 }
        return nights.reduce(0, +) / Double(nights.count)
    }

    var averageBedtime: Date? {
        guard !nightlyRecords.isEmpty else { return nil }
        let calendar = Calendar.current
        let minutesFromMidnight = nightlyRecords.map { record -> Int in
            let components = calendar.dateComponents([.hour, .minute], from: record.bedtime)
            var minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            // Adjust for times after midnight (treat as previous day)
            if minutes < 720 { minutes += 1440 }
            return minutes
        }
        let avg = minutesFromMidnight.reduce(0, +) / minutesFromMidnight.count
        let adjustedAvg = avg >= 1440 ? avg - 1440 : avg
        let hour = adjustedAvg / 60
        let minute = adjustedAvg % 60
        return calendar.date(from: DateComponents(hour: hour, minute: minute))
    }

    var averageWakeTime: Date? {
        guard !nightlyRecords.isEmpty else { return nil }
        let calendar = Calendar.current
        let minutesFromMidnight = nightlyRecords.map { record -> Int in
            let components = calendar.dateComponents([.hour, .minute], from: record.wakeTime)
            return (components.hour ?? 0) * 60 + (components.minute ?? 0)
        }
        let avg = minutesFromMidnight.reduce(0, +) / minutesFromMidnight.count
        let hour = avg / 60
        let minute = avg % 60
        return calendar.date(from: DateComponents(hour: hour, minute: minute))
    }

    var averageEfficiency: Double {
        let nights = nightlyRecords
        guard !nights.isEmpty else { return 0 }
        return nights.map(\.sleepEfficiency).reduce(0, +) / Double(nights.count)
    }

    var averageDeepSleepMinutes: Double {
        let nights = nightlyRecords
        guard !nights.isEmpty else { return 0 }
        return nights.map { $0.deepSleepDuration / 60.0 }.reduce(0, +) / Double(nights.count)
    }

    var averageREMSleepMinutes: Double {
        let nights = nightlyRecords
        guard !nights.isEmpty else { return 0 }
        return nights.map { $0.remSleepDuration / 60.0 }.reduce(0, +) / Double(nights.count)
    }

    // Targets

    /// Nights meeting the minimum, counted per deduped night (see `nightlySleepHours`) —
    /// otherwise a night fragmented into two HealthKit sessions (e.g. 3.5h + 3.8h, split by
    /// the >2h gap threshold) would be checked as two separate sub-target records instead of
    /// one 7.3h night that actually met the goal.
    var nightsMeetingTarget: Int {
        let minimum = SleepAnalysisEngine.minimumAcceptableHours
        return nightlySleepHours.filter { $0 >= minimum }.count
    }

    /// Nights with recorded sleep — the shared denominator for `targetComplianceRate` and the
    /// "X/Y nights" compliance text, so it agrees with `nightsMeetingTarget`'s numerator.
    var trackedNightCount: Int {
        nightlySleepHours.count
    }

    var targetComplianceRate: Double {
        guard trackedNightCount > 0 else { return 0 }
        return Double(nightsMeetingTarget) / Double(trackedNightCount)
    }

    var totalSleepDebt: Double {
        let target = SleepAnalysisEngine.targetSleepHours
        return nightlySleepHours.map { max(0, target - $0) }.reduce(0, +)
    }

    /// Hours slept per tracked night (one merged record per night, so a stage-less "in bed
    /// only" night never counts as a full night of phantom debt).
    private var nightlySleepHours: [Double] {
        nightlyRecords.map(\.totalSleepHours)
    }

    /// Signed net balance (hours) versus the user's Settings target over tracked nights.
    /// Negative = behind goal (debt), positive = ahead. Surplus nights offset prior debt.
    var targetRunningBalance: Double {
        let target = SleepAnalysisEngine.targetSleepHours
        return nightlySleepHours.map { $0 - target }.reduce(0, +)
    }

    /// Average nightly balance versus the Settings target (signed), over tracked nights.
    var averageNightlyBalance: Double {
        let nights = nightlySleepHours
        guard !nights.isEmpty else { return 0 }
        return targetRunningBalance / Double(nights.count)
    }

    // Consistency
    var bedtimeConsistencyMinutes: Double {
        let nights = nightlyRecords
        guard nights.count > 1 else { return 0 }
        let calendar = Calendar.current
        let minutesFromMidnight = nights.map { record -> Double in
            let components = calendar.dateComponents([.hour, .minute], from: record.bedtime)
            var minutes = Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
            if minutes < 720 { minutes += 1440 }
            return minutes
        }
        let mean = minutesFromMidnight.reduce(0, +) / Double(minutesFromMidnight.count)
        let variance = minutesFromMidnight.map { pow($0 - mean, 2) }.reduce(0, +) / Double(minutesFromMidnight.count)
        return sqrt(variance)
    }

    // Trends
    var sleepDurationTrend: TrendDirection {
        calculateTrend(values: nightlySleepHours)
    }

    private func calculateTrend(values: [Double]) -> TrendDirection {
        guard values.count >= 3 else { return .stable }
        let recentHalf = Array(values.suffix(values.count / 2))
        let earlierHalf = Array(values.prefix(values.count / 2))
        let recentAvg = recentHalf.reduce(0, +) / Double(recentHalf.count)
        let earlierAvg = earlierHalf.reduce(0, +) / Double(earlierHalf.count)
        let diff = recentAvg - earlierAvg
        if abs(diff) < 0.1 { return .stable }
        return diff > 0 ? .improving : .declining
    }
}

/// How urgently a stat (duration, debt) deserves visual attention.
enum StatSeverity {
    case normal
    case concerning
    case critical
}

enum TrendDirection: String {
    case improving = "Improving"
    case stable = "Stable"
    case declining = "Declining"

    var systemImage: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var colorName: String {
        switch self {
        case .improving: return "trendImproving"
        case .stable: return "trendStable"
        case .declining: return "trendDeclining"
        }
    }
}

// MARK: - Chart Data Points

struct SleepChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double
    let label: String
}

struct StageChartDataPoint: Identifiable {
    let id = UUID()
    let stage: SleepStage
    let minutes: Double
    let percentage: Double
}

/// A single stage block within a night, used by the sleep timeline chart.
struct StageSegment: Identifiable {
    let id = UUID()
    let stage: SleepStage
    let start: Date
    let end: Date
}

/// One night for the sleep timeline chart: a vertical bar spanning bedtime→wake,
/// coloured by stage, labelled with the hours actually slept.
struct NightTimelinePoint: Identifiable {
    let id = UUID()
    let date: Date          // the night, labelled by its wake day (x-axis position)
    let bedtime: Date
    let wakeTime: Date
    let sleepHours: Double   // hours asleep (falls back to time in bed when no stage data)
    let segments: [StageSegment]
}
