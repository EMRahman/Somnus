import XCTest
import Combine
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

    func testDebtBucketsAndCumulativeLineRateShortfallPerNight() {
        let debt = [
            SleepChartDataPoint(date: night(daysAgo: 14), hours: 2.1, label: "", nightCount: 7),  // 0.3h/night
            SleepChartDataPoint(date: night(daysAgo: 7), hours: 10.5, label: "", nightCount: 7)   // 1.5h/night
        ]

        XCTAssertEqual(SleepAnalysisEngine.shortfallSeverity(hours: debt[0].hoursPerNight), .normal)
        XCTAssertEqual(SleepAnalysisEngine.shortfallSeverity(hours: debt[1].hoursPerNight), .critical)

        // Running average after both weeks: 12.6h over 14 nights = 0.9h/night.
        let cumulative = TrendsViewModel.cumulative(debt)
        XCTAssertEqual(cumulative.map(\.nightCount), [7, 14])
        XCTAssertEqual(cumulative[1].hours, 12.6, accuracy: 0.001)
        XCTAssertEqual(SleepAnalysisEngine.shortfallSeverity(hours: cumulative[1].hoursPerNight), .concerning)
    }

    func testDebtByBucketCountsNightsPerBucket() {
        let records = [
            record(night: night(daysAgo: 2), bedHour: 23, sleepHours: 6),
            record(night: night(daysAgo: 1), bedHour: 23, sleepHours: 9)
        ]

        let debt = SleepAnalysisEngine.debtByBucket(from: records, target: 8.0, period: .weekly)

        XCTAssertEqual(debt.map(\.nightCount), [1, 1])
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

    // MARK: - Chart Selection & Bucket Averages

    func testNearestBucketDateSnapsWithinFullBarSpan() {
        let nov1 = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))!
        let dec1 = calendar.date(from: DateComponents(year: 2026, month: 12, day: 1))!
        let nov24 = calendar.date(from: DateComponents(year: 2026, month: 11, day: 24))!

        let snapped = SleepAnalysisEngine.nearestBucketDate(
            to: nov24,
            in: [nov1, dec1],
            unit: .month,
            calendar: calendar
        )

        XCTAssertEqual(snapped, nov1)
    }

    func testBucketLabelFormatsPeriods() {
        let nov10 = calendar.date(from: DateComponents(year: 2026, month: 11, day: 10))!

        let weeklyLabel = SleepAnalysisEngine.bucketLabel(for: nov10, period: .weekly, calendar: calendar)
        let monthlyLabel = SleepAnalysisEngine.bucketLabel(for: nov10, period: .monthly, calendar: calendar)
        let yearlyLabel = SleepAnalysisEngine.bucketLabel(for: nov10, period: .yearly, calendar: calendar)
        let fiveYearLabel = SleepAnalysisEngine.bucketLabel(for: nov10, period: .fiveYears, calendar: calendar)

        XCTAssertFalse(weeklyLabel.isEmpty)
        XCTAssertTrue(monthlyLabel.contains("–"))
        XCTAssertFalse(yearlyLabel.isEmpty)
        XCTAssertFalse(fiveYearLabel.isEmpty)
        XCTAssertNotEqual(weeklyLabel, yearlyLabel)
        XCTAssertNotEqual(yearlyLabel, fiveYearLabel)
    }

    func testAveragedDurationBucketsPopulateNightCountAndIgnorePhantoms() {
        let nov2 = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2))!
        let nov3 = calendar.date(from: DateComponents(year: 2026, month: 11, day: 3))!
        let nov4 = calendar.date(from: DateComponents(year: 2026, month: 11, day: 4))!
        let dec5 = calendar.date(from: DateComponents(year: 2026, month: 12, day: 5))!

        let records = fragmentedNight(nov2) + [
            record(night: nov3, bedHour: 23, sleepHours: 7.7),
            inBedOnlyRecord(night: nov4),
            record(night: dec5, bedHour: 23, sleepHours: 8.0)
        ]

        let weekly = SleepAnalysisEngine.weeklyAverages(from: records)
        let monthly = SleepAnalysisEngine.monthlyAverages(from: records)
        let yearly = SleepAnalysisEngine.yearlyAverages(from: records)

        XCTAssertEqual(weekly.count, 2)
        XCTAssertEqual(weekly[0].nightCount, 2)
        XCTAssertEqual(weekly[0].hours, 7.5, accuracy: 0.001)
        XCTAssertEqual(weekly[1].nightCount, 1)

        XCTAssertEqual(monthly.count, 2)
        XCTAssertEqual(monthly.map(\.nightCount), [2, 1])

        XCTAssertEqual(yearly.count, 1)
        XCTAssertEqual(yearly[0].nightCount, 3)
        XCTAssertEqual(yearly[0].hours, (7.3 + 7.7 + 8.0) / 3.0, accuracy: 0.001)
    }

    func testNightTimelinePointStageMinutes() {
        let base = Date()
        let point = NightTimelinePoint(
            date: base,
            bedtime: base,
            wakeTime: base.addingTimeInterval(3600),
            sleepHours: 0.85,
            segments: [
                StageSegment(stage: .deepSleep, start: base, end: base.addingTimeInterval(18 * 60)),
                StageSegment(stage: .coreSleep, start: base.addingTimeInterval(18 * 60), end: base.addingTimeInterval(38 * 60)),
                StageSegment(stage: .remSleep, start: base.addingTimeInterval(38 * 60), end: base.addingTimeInterval(51 * 60)),
                StageSegment(stage: .awake, start: base.addingTimeInterval(51 * 60), end: base.addingTimeInterval(60 * 60))
            ]
        )

        XCTAssertEqual(point.deepMinutes, 18, accuracy: 0.001)
        XCTAssertEqual(point.coreMinutes, 20, accuracy: 0.001)
        XCTAssertEqual(point.remMinutes, 13, accuracy: 0.001)
        XCTAssertEqual(point.awakeMinutes, 9, accuracy: 0.001)
    }

    // MARK: - Pattern Detection

    func testDetectPatternsMergesFragmentedNights() {
        // 4 unique nights split across 6 fragments should still be below the 5-night threshold.
        let fourFragmentedNights =
            fragmentedNight(night(daysAgo: 4)) +
            fragmentedNight(night(daysAgo: 3)) +
            [
                record(night: night(daysAgo: 2), bedHour: 23, sleepHours: 7.5),
                record(night: night(daysAgo: 1), bedHour: 23, sleepHours: 7.6)
            ]
        XCTAssertTrue(SleepAnalysisEngine.detectPatterns(from: fourFragmentedNights).isEmpty)

        // Pick 5 consecutive weekdays (Mon-Fri, Nov 2-6 2026) and 2 weekend nights (Sat-Sun, Nov 7-8 2026)
        // where 3 weekday nights are fragmented (23:00 + 03:00 = 7.3h total).
        // Without merging, the 3:00 AM fragments would count as 3/10+ late nights and drag weekday avg down
        // enough to risk Social Jet Lag; merged, every night started at 23:00 and averaged 7.4h vs 7.5h.
        let mon = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2))!
        let tue = calendar.date(from: DateComponents(year: 2026, month: 11, day: 3))!
        let wed = calendar.date(from: DateComponents(year: 2026, month: 11, day: 4))!
        let thu = calendar.date(from: DateComponents(year: 2026, month: 11, day: 5))!
        let fri = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6))!
        let sat = calendar.date(from: DateComponents(year: 2026, month: 11, day: 7))!
        let sun = calendar.date(from: DateComponents(year: 2026, month: 11, day: 8))!

        let weekWithFragments =
            fragmentedNight(mon) +
            fragmentedNight(tue) +
            fragmentedNight(wed) +
            [
                record(night: thu, bedHour: 23, sleepHours: 7.5),
                record(night: fri, bedHour: 23, sleepHours: 7.6),
                record(night: sat, bedHour: 23, sleepHours: 7.5),
                record(night: sun, bedHour: 23, sleepHours: 7.5)
            ]

        let flags = SleepAnalysisEngine.detectPatterns(from: weekWithFragments)
        XCTAssertFalse(flags.contains { $0.title == "Late Bedtimes" })
        XCTAssertFalse(flags.contains { $0.title == "Social Jet Lag" })
    }

    func testWeekendEffectMergesFragmentsAndDropsPhantoms() {
        let mon = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2))!
        let tue = calendar.date(from: DateComponents(year: 2026, month: 11, day: 3))!
        let sat = calendar.date(from: DateComponents(year: 2026, month: 11, day: 7))!

        let records = fragmentedNight(mon) + [
            inBedOnlyRecord(night: tue),
            record(night: sat, bedHour: 23, sleepHours: 8.3)
        ]

        let effect = SleepAnalysisEngine.weekendEffect(from: records)
        XCTAssertNotNil(effect)
        XCTAssertEqual(effect?.weekdayAvg ?? 0, 7.3, accuracy: 0.001)
        XCTAssertEqual(effect?.weekendAvg ?? 0, 8.3, accuracy: 0.001)
    }

    // MARK: - Locale Clock Formatting

    func testClockAndTimeFormattingRespectsLocale() {
        let us = Locale(identifier: "en_US")
        let gb = Locale(identifier: "en_GB")
        let fr = Locale(identifier: "fr_FR")

        XCTAssertEqual(SleepTimelineChart.clockLabel(forPlotted: -21, locale: us), "9PM")
        XCTAssertEqual(SleepTimelineChart.clockLabel(forPlotted: -24, locale: us), "12AM")
        XCTAssertEqual(SleepTimelineChart.clockLabel(forPlotted: -30, locale: us), "6AM")

        XCTAssertEqual(SleepTimelineChart.clockLabel(forPlotted: -21, locale: gb), "21:00")
        XCTAssertEqual(SleepTimelineChart.clockLabel(forPlotted: -24, locale: gb), "00:00")
        XCTAssertEqual(SleepTimelineChart.clockLabel(forPlotted: -30, locale: gb), "06:00")

        XCTAssertEqual(SleepTimelineChart.clockLabel(forPlotted: -21, locale: fr), "21:00")

        let evening = calendar.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 22, minute: 30))!
        let usText = evening.timeString(locale: us)
        let gbText = evening.timeString(locale: gb)
        XCTAssertTrue(usText.contains("10:30"))
        XCTAssertTrue(gbText.contains("22:30"))
    }

    // MARK: - Live Goal Synchronization

    @MainActor
    func testViewModelsRecalculateForGoalChanges() {
        let trendsVM = TrendsViewModel.preview
        let dashboardVM = DashboardViewModel.preview

        var trendsChanges = 0
        var dashboardChanges = 0
        let trendsSub = trendsVM.objectWillChange.sink { _ in trendsChanges += 1 }
        let dashboardSub = dashboardVM.objectWillChange.sink { _ in dashboardChanges += 1 }
        defer {
            trendsSub.cancel()
            dashboardSub.cancel()
        }

        XCTAssertNotEqual(dashboardVM.sleepDebtText, "No debt")
        let initialTargetRate = trendsVM.targetRateText

        // Lower target below every preview night's generated stage duration so all shortfalls clear.
        defaults.set(4.0, forKey: "sleepGoalHours")
        trendsVM.syncGoalsIfNeeded()
        dashboardVM.syncGoalsIfNeeded()

        XCTAssertGreaterThan(trendsChanges, 0)
        XCTAssertEqual(dashboardChanges, 1)
        let changesAfterTarget = trendsChanges
        XCTAssertTrue(trendsVM.runningBalanceText.contains("ahead"))
        XCTAssertTrue(trendsVM.debtChartData.allSatisfy { $0.hours < 0.01 })
        XCTAssertTrue(trendsVM.cumulativeDebtData.allSatisfy { $0.hours < 0.01 })
        XCTAssertFalse(trendsVM.weekdayDebtData.isEmpty)
        XCTAssertEqual(dashboardVM.sleepDebtText, "No debt")

        defaults.set(9.0, forKey: "sleepGoalMinimum")
        trendsVM.syncGoalsIfNeeded()
        dashboardVM.syncGoalsIfNeeded()

        XCTAssertGreaterThan(trendsChanges, changesAfterTarget)
        XCTAssertEqual(dashboardChanges, 2)
        XCTAssertNotEqual(trendsVM.targetRateText, initialTargetRate)
        XCTAssertEqual(trendsVM.targetRateText, "0%")
        XCTAssertEqual(dashboardVM.targetComplianceText, "0/7 nights")
    }
}
