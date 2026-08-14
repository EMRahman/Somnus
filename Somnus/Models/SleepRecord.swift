import Foundation
import HealthKit

// MARK: - Sleep Stage

enum SleepStage: String, CaseIterable, Codable {
    case awake = "Awake"
    case remSleep = "REM"
    case coreSleep = "Core"
    case deepSleep = "Deep"
    case inBed = "In Bed"
    case unspecified = "Asleep"

    var color: String {
        switch self {
        case .awake: return "stageAwake"
        case .remSleep: return "stageREM"
        case .coreSleep: return "stageCore"
        case .deepSleep: return "stageDeep"
        case .inBed: return "stageInBed"
        case .unspecified: return "stageUnspecified"
        }
    }

    var sortOrder: Int {
        switch self {
        case .awake: return 0
        case .remSleep: return 1
        case .coreSleep: return 2
        case .deepSleep: return 3
        case .inBed: return 4
        case .unspecified: return 5
        }
    }

    init(from hkValue: HKCategoryValueSleepAnalysis) {
        switch hkValue {
        case .awake:
            self = .awake
        case .asleepREM:
            self = .remSleep
        case .asleepCore:
            self = .coreSleep
        case .asleepDeep:
            self = .deepSleep
        case .inBed:
            self = .inBed
        default:
            self = .unspecified
        }
    }
}

// MARK: - Sleep Stage Sample

struct SleepStageSample: Identifiable, Codable {
    let id: UUID
    let stage: SleepStage
    let startDate: Date
    let endDate: Date

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var durationMinutes: Double {
        duration / 60.0
    }

    init(id: UUID = UUID(), stage: SleepStage, startDate: Date, endDate: Date) {
        self.id = id
        self.stage = stage
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Sleep Record

struct SleepRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let bedtime: Date
    let wakeTime: Date
    let stages: [SleepStageSample]

    init(id: UUID = UUID(), date: Date, bedtime: Date, wakeTime: Date, stages: [SleepStageSample] = []) {
        self.id = id
        self.date = date
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.stages = stages
    }

    /// Total time in bed (bedtime to wake)
    var timeInBed: TimeInterval {
        wakeTime.timeIntervalSince(bedtime)
    }

    var timeInBedHours: Double {
        timeInBed / 3600.0
    }

    /// Total time actually asleep (excluding awake stages)
    var totalSleepDuration: TimeInterval {
        stages.filter { $0.stage != .awake && $0.stage != .inBed }
            .reduce(0) { $0 + $1.duration }
    }

    var totalSleepHours: Double {
        totalSleepDuration / 3600.0
    }

    /// Duration of each stage
    var deepSleepDuration: TimeInterval {
        stageDuration(for: .deepSleep)
    }

    var remSleepDuration: TimeInterval {
        stageDuration(for: .remSleep)
    }

    var coreSleepDuration: TimeInterval {
        stageDuration(for: .coreSleep)
    }

    var awakeDuration: TimeInterval {
        stageDuration(for: .awake)
    }

    /// Sleep efficiency: ratio of sleep time to time in bed
    var sleepEfficiency: Double {
        guard timeInBed > 0 else { return 0 }
        return min(totalSleepDuration / timeInBed, 1.0)
    }

    /// Whether the user met a given nightly target (Settings' "Minimum Acceptable").
    func meetsTarget(_ target: Double) -> Bool {
        totalSleepHours >= target
    }

    // MARK: - Helpers

    private func stageDuration(for stage: SleepStage) -> TimeInterval {
        stages.filter { $0.stage == stage }
            .reduce(0) { $0 + $1.duration }
    }
}

// MARK: - Time Period

enum TimePeriod: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case fiveYears = "5 Years"
    case tenYears = "10 Years"

    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let end = calendar.startOfDay(for: now).addingTimeInterval(86400)

        switch self {
        case .daily:
            // Start the window at 6pm the previous evening: the HealthKit query uses a strict
            // start date, so beginning at midnight would drop the pre-midnight portion of a
            // night that started before 12am and show a truncated night on the 1D view.
            let start = calendar.startOfDay(for: now).addingTimeInterval(-6 * 3600)
            return (start, end)
        case .weekly:
            let start = calendar.date(byAdding: .day, value: -7, to: end)!
            return (start, end)
        case .monthly:
            let start = calendar.date(byAdding: .month, value: -1, to: end)!
            return (start, end)
        case .yearly:
            let start = calendar.date(byAdding: .year, value: -1, to: end)!
            return (start, end)
        case .fiveYears:
            let start = calendar.date(byAdding: .year, value: -5, to: end)!
            return (start, end)
        case .tenYears:
            let start = calendar.date(byAdding: .year, value: -10, to: end)!
            return (start, end)
        }
    }

    var chartLabel: String {
        switch self {
        case .daily: return "Today"
        case .weekly: return "Past 7 Days"
        case .monthly: return "Past Month"
        case .yearly: return "Past Year"
        case .fiveYears: return "Past 5 Years"
        case .tenYears: return "Past 10 Years"
        }
    }

    /// Compact label for the segmented period selector.
    var shortLabel: String {
        switch self {
        case .daily: return "1D"
        case .weekly: return "1W"
        case .monthly: return "1M"
        case .yearly: return "1Y"
        case .fiveYears: return "5Y"
        case .tenYears: return "10Y"
        }
    }
}
