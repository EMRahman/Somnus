import XCTest
@testable import Somnus

final class SleepAnalysisEngineTests: XCTestCase {

    private let calendar = Calendar.current
    private let defaults = UserDefaults.standard

    override func setUp() {
        super.setUp()
        // The engine reads these Settings keys directly; pin them so tests are deterministic.
        defaults.set(8.0, forKey: "sleepGoalHours")
        defaults.set(7.0, forKey: "sleepGoalMinimum")
    }

    override func tearDown() {
        defaults.removeObject(forKey: "sleepGoalHours")
        defaults.removeObject(forKey: "sleepGoalMinimum")
        super.tearDown()
    }

    // MARK: - Record Builders

    /// The calendar night `daysAgo` — the start of the wake day, matching `SleepRecord.date`.
    private func night(daysAgo: Int) -> Date {
        calendar.startOfDay(for: calendar.date(byAdding: .day, value: -daysAgo, to: Date())!)
    }

    /// A sleep session on the given night: asleep (core) from `bedHour:bedMinute` for
    /// `sleepHours`. Evening hours (>= 12) place the bedtime on the previous calendar day,
    /// matching how `HealthKitManager` dates records by their wake day.
    private func record(night: Date, bedHour: Int, bedMinute: Int = 0, sleepHours: Double) -> SleepRecord {
        let bedtimeDay = bedHour >= 12 ? calendar.date(byAdding: .day, value: -1, to: night)! : night
        let bedtime = calendar.date(bySettingHour: bedHour, minute: bedMinute, second: 0, of: bedtimeDay)!
        let wake = bedtime.addingTimeInterval(sleepHours * 3600)
        return SleepRecord(
            date: night,
            bedtime: bedtime,
            wakeTime: wake,
            stages: [SleepStageSample(stage: .coreSleep, startDate: bedtime, endDate: wake)]
        )
    }

    /// A stage-less "in bed only" record (0h asleep), as HealthKit produced before
    /// Apple Watch sleep stages arrived — must never count as a tracked night.
    private func inBedOnlyRecord(night: Date, hoursInBed: Double = 7.0) -> SleepRecord {
        let bedtimeDay = calendar.date(byAdding: .day, value: -1, to: night)!
        let bedtime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: bedtimeDay)!
        let wake = bedtime.addingTimeInterval(hoursInBed * 3600)
        return SleepRecord(
            date: night,
            bedtime: bedtime,
            wakeTime: wake,
            stages: [SleepStageSample(stage: .inBed, startDate: bedtime, endDate: wake)]
        )
    }

    /// A 7.3h night fragmented into two sessions (3.5h + 3.8h) split by a >2h gap,
    /// the shape `groupSamplesIntoRecords` produces for an interrupted night.
    private func fragmentedNight(_ night: Date) -> [SleepRecord] {
        [
            record(night: night, bedHour: 23, sleepHours: 3.5),
            record(night: night, bedHour: 5, bedMinute: 0, sleepHours: 3.8)
        ]
    }

    // MARK: - Nightly Totals

    func testNightlyTotalsMergesSameNightFragments() {
        let totals = SleepAnalysisEngine.nightlyTotals(from: fragmentedNight(night(daysAgo: 1)))

        XCTAssertEqual(totals.count, 1)
        XCTAssertEqual(totals[0].hours, 7.3, accuracy: 0.001)
    }

    func testMergedNightlyRecordsMergesFragmentsAndDropsPhantoms() {
        let merged = SleepAnalysisEngine.mergedNightlyRecords(
            from: fragmentedNight(night(daysAgo: 2)) + [inBedOnlyRecord(night: night(daysAgo: 1))]
        )

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].totalSleepHours, 7.3, accuracy: 0.001)
        XCTAssertEqual(merged[0].stages.count, 2) // both fragments' stages, none lost
        // Bedtime = first session's, wake = last session's — the whole night's span.
        XCTAssertEqual(merged[0].timeInBedHours, 9.8, accuracy: 0.001)
    }

    func testNightlyTotalsSortsByDate() {
        let records = [
            record(night: night(daysAgo: 1), bedHour: 23, sleepHours: 8),
            record(night: night(daysAgo: 3), bedHour: 23, sleepHours: 6),
            record(night: night(daysAgo: 2), bedHour: 23, sleepHours: 7)
        ]

        let totals = SleepAnalysisEngine.nightlyTotals(from: records)

        XCTAssertEqual(totals.map(\.date), [night(daysAgo: 3), night(daysAgo: 2), night(daysAgo: 1)])
    }

    // MARK: - Sleep Debt

    func testDebtByBucketComputesNightlyShortfallOnly() {
        let records = [
            record(night: night(daysAgo: 2), bedHour: 23, sleepHours: 6),  // 2h short
            record(night: night(daysAgo: 1), bedHour: 23, sleepHours: 9)   // surplus, no debt
        ]

        let debt = SleepAnalysisEngine.debtByBucket(from: records, target: 8.0, period: .weekly)

        XCTAssertEqual(debt.count, 2)
        XCTAssertEqual(debt[0].hours, 2.0, accuracy: 0.001)
        XCTAssertEqual(debt[1].hours, 0.0, accuracy: 0.001)
    }

    func testDebtByBucketMergesFragmentsBeforeApplyingTarget() {
        // 3.5h + 3.8h fragments = one 7.3h night → 0.7h debt, not 4.5h + 4.2h.
        let debt = SleepAnalysisEngine.debtByBucket(
            from: fragmentedNight(night(daysAgo: 1)), target: 8.0, period: .weekly
        )

        XCTAssertEqual(debt.count, 1)
        XCTAssertEqual(debt[0].hours, 0.7, accuracy: 0.001)
    }

    // MARK: - Score

    func testScoreIsZeroWithoutTrackedSleep() {
        XCTAssertEqual(SleepAnalysisEngine.calculateScore(for: []).overall, 0)

        let phantomOnly = SleepAnalysisEngine.calculateScore(for: [inBedOnlyRecord(night: night(daysAgo: 1))])
        XCTAssertEqual(phantomOnly.overall, 0)
    }

    func testScoreIgnoresInBedOnlyRecords() {
        let tracked = [
            record(night: night(daysAgo: 2), bedHour: 23, sleepHours: 7.5),
            record(night: night(daysAgo: 1), bedHour: 23, sleepHours: 8.0)
        ]

        let withPhantom = SleepAnalysisEngine.calculateScore(for: tracked + [inBedOnlyRecord(night: night(daysAgo: 3))])
        let without = SleepAnalysisEngine.calculateScore(for: tracked)

        XCTAssertEqual(withPhantom.overall, without.overall)
        XCTAssertEqual(withPhantom.durationScore, without.durationScore)
        XCTAssertEqual(withPhantom.consistencyScore, without.consistencyScore)
    }

    func testFragmentedNightScoresAsOneNight() {
        let fragmented = SleepAnalysisEngine.calculateScore(for: fragmentedNight(night(daysAgo: 1)))
        let whole = SleepAnalysisEngine.calculateScore(for: [
            record(night: night(daysAgo: 1), bedHour: 23, sleepHours: 7.3)
        ])

        // Duration and consistency see one 7.3h night either way.
        XCTAssertEqual(fragmented.durationScore, whole.durationScore)
        XCTAssertEqual(fragmented.consistencyScore, whole.consistencyScore)
        // Efficiency legitimately differs: once the sessions are merged, the 2.5h awake
        // gap counts as time in bed, so the interrupted night scores lower — instead of
        // each fragment scoring as a perfectly efficient mini-night.
        XCTAssertLessThan(fragmented.efficiencyScore, whole.efficiencyScore)
    }

    // MARK: - Metrics

    func testMetricsDeduplicateFragmentsAndExcludePhantomNights() {
        let records = fragmentedNight(night(daysAgo: 3)) + [                 // one 7.3h night
            record(night: night(daysAgo: 2), bedHour: 23, sleepHours: 8),    // one 8h night
            inBedOnlyRecord(night: night(daysAgo: 1))                        // untracked night
        ]

        let metrics = SleepAnalysisEngine.computeMetrics(records: records, period: .weekly)

        XCTAssertEqual(metrics.trackedNightCount, 2)
        XCTAssertEqual(metrics.nightsMeetingTarget, 2) // both nights ≥ the 7h minimum
        XCTAssertEqual(metrics.totalSleepDebt, 0.7, accuracy: 0.001) // vs the 8h target
        XCTAssertEqual(metrics.averageSleepHours, 7.65, accuracy: 0.001)
    }

    func testNightlyTimelineSkipsPhantomNights() {
        let timeline = SleepAnalysisEngine.nightlyTimeline(from: [inBedOnlyRecord(night: night(daysAgo: 1))])
        XCTAssertTrue(timeline.isEmpty)
    }

    // MARK: - Time Period

    func testDailyRangeIncludesPreviousEvening() {
        let range = TimePeriod.daily.dateRange
        let startOfToday = calendar.startOfDay(for: Date())

        XCTAssertEqual(range.start, startOfToday.addingTimeInterval(-6 * 3600))
        XCTAssertEqual(range.end, startOfToday.addingTimeInterval(86400))
    }

    // MARK: - Grades

    func testGradeBoundaries() {
        XCTAssertEqual(SleepGrade(score: 90), .excellent)
        XCTAssertEqual(SleepGrade(score: 89), .good)
        XCTAssertEqual(SleepGrade(score: 75), .good)
        XCTAssertEqual(SleepGrade(score: 74), .fair)
        XCTAssertEqual(SleepGrade(score: 60), .fair)
        XCTAssertEqual(SleepGrade(score: 59), .poor)
        XCTAssertEqual(SleepGrade(score: 40), .poor)
        XCTAssertEqual(SleepGrade(score: 39), .veryPoor)
    }
}
