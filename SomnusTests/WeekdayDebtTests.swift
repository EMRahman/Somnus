import XCTest
@testable import Somnus

final class WeekdayDebtTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    private func date(_ year: Int = 2026, _ month: Int = 11, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func record(_ wake: Date, hours: Double, afterMidnight: Bool = false) -> SleepRecord {
        let bedtime = calendar.date(byAdding: .hour, value: afterMidnight ? 1 : -1, to: wake)!
        let end = bedtime.addingTimeInterval(hours * 3600)
        return SleepRecord(date: wake, bedtime: bedtime, wakeTime: end,
                           stages: [SleepStageSample(stage: .coreSleep, startDate: bedtime, endDate: end)])
    }

    private func summaries(_ records: [SleepRecord], range: Range<Date>) -> [WeekdayDebtSummary] {
        SleepAnalysisEngine.weekdayDebt(from: records, target: 8, wakeRange: range, calendar: calendar)
    }

    func testEveningLabelsIncludeAfterMidnightBedtimes() {
        let result = summaries([
            record(date(2026, 11, 3), hours: 6),
            record(date(2026, 11, 10), hours: 7, afterMidnight: true)
        ], range: date(2026, 11, 1)..<date(2026, 12, 1))
        XCTAssertEqual(result.map(\.weekday), [2, 3, 4, 5, 6, 7, 1])
        XCTAssertEqual(result[0].recordedCount, 2)
        XCTAssertEqual(result[0].averageHours!, 1.5, accuracy: 0.001)
        XCTAssertEqual(result[0].nights.compactMap { $0.hours == nil ? nil : $0.date }, [date(2026, 11, 2), date(2026, 11, 9)])
    }

    func testFragmentsMergeBeforeDebtAndSurplusCannotEraseShortfall() {
        let wake = date(2026, 11, 3)
        let result = summaries([
            record(wake, hours: 3.5), record(wake, hours: 3.8, afterMidnight: true),
            record(date(2026, 11, 10), hours: 10)
        ], range: date(2026, 11, 1)..<date(2026, 12, 1))
        XCTAssertEqual(result[0].recordedCount, 2)
        XCTAssertEqual(result[0].nights[0].hours!, 0.7, accuracy: 0.001)
        XCTAssertEqual(result[0].averageHours!, 0.35, accuracy: 0.001)
    }

    func testMissingDataIsDifferentFromRecordedZero() {
        let wake = date(2026, 11, 3)
        let empty = SleepRecord(date: date(2026, 11, 10), bedtime: wake, wakeTime: wake)
        let result = summaries([record(wake, hours: 9), empty], range: date(2026, 11, 1)..<date(2026, 12, 1))
        XCTAssertEqual(result[0].nights[0].hours, 0)
        XCTAssertNil(result[0].nights[1].hours)
        XCTAssertEqual(result[0].recordedCount, 1)
        XCTAssertEqual(result[0].averageHours, 0)
        XCTAssertNil(result[1].averageHours)
    }

    func testMonthIncludesFifthOccurrenceAndStableMissingSlots() {
        // March 2026 has five Monday evenings, including the night crossing into April.
        let result = summaries([], range: date(2026, 3, 2)..<date(2026, 4, 2))
        XCTAssertEqual(result[0].nights.count, 5)
        XCTAssertEqual(result[0].nights.map(\.occurrence), [0, 1, 2, 3, 4])
        XCTAssertEqual(result[0].nights.last?.date, date(2026, 3, 30))
    }

    func testWindowExcludesOutsideRecords() {
        let result = summaries([
            record(date(2026, 11, 3), hours: 4),
            record(date(2026, 11, 10), hours: 7),
            record(date(2026, 11, 17), hours: 4)
        ], range: date(2026, 11, 4)..<date(2026, 11, 17))
        XCTAssertEqual(result[0].recordedCount, 1)
        XCTAssertEqual(result[0].averageHours, 1)
    }

    func testDaylightSavingChangeDoesNotSkipOrDuplicateNights() {
        let result = summaries([], range: date(2026, 10, 20)..<date(2026, 10, 28))
        let dates = result.flatMap(\.nights).map(\.date)
        XCTAssertEqual(dates.count, 8)
        XCTAssertEqual(Set(dates).count, 8)
        XCTAssertTrue(dates.contains(date(2026, 10, 25)))
    }

    func testMonthlyDrilldownUsesRecordedNightDenominators() {
        let result = summaries([
            record(date(2026, 10, 6), hours: 6),
            record(date(2026, 10, 13), hours: 8),
            record(date(2026, 11, 3), hours: 5)
        ], range: date(2026, 10, 1)..<date(2026, 12, 1))
        let buckets = SleepAnalysisEngine.weekdayDebtBuckets(for: result[0], component: .month, calendar: calendar)
        XCTAssertEqual(buckets.count, 2)
        XCTAssertEqual(buckets[0].recordedCount, 2)
        XCTAssertEqual(buckets[0].hours, 1)
        XCTAssertEqual(buckets[1].recordedCount, 1)
        XCTAssertEqual(buckets[1].hours, 3)
        XCTAssertEqual(result[0].averageHours!, 5.0 / 3, accuracy: 0.001)
    }

    func testYearlyDrilldownPreservesEmptyYears() {
        let result = summaries([record(date(2026, 11, 3), hours: 6)],
                               range: date(2024, 1, 2)..<date(2027, 1, 2))
        let buckets = SleepAnalysisEngine.weekdayDebtBuckets(for: result[0], component: .year, calendar: calendar)
        XCTAssertEqual(buckets.count, 3)
        XCTAssertNil(buckets[0].hours)
        XCTAssertNil(buckets[1].hours)
        XCTAssertEqual(buckets[2].hours, 2)
        XCTAssertEqual(buckets[2].recordedCount, 1)
    }

    func testShortfallSeverityRanksLowModerateAndHighWeekdayDebt() {
        let result = summaries([
            record(date(2026, 11, 3), hours: 6.5), // Monday night: 1.5h shortfall (.critical)
            record(date(2026, 11, 4), hours: 7.3), // Tuesday night: 0.7h shortfall (.concerning)
            record(date(2026, 11, 5), hours: 7.7)  // Wednesday night: 0.3h shortfall (.normal)
        ], range: date(2026, 11, 1)..<date(2026, 11, 8))
        XCTAssertEqual(result[0].severity, .critical)
        XCTAssertEqual(result[0].nights[0].severity, .critical)
        XCTAssertEqual(result[1].severity, .concerning)
        XCTAssertEqual(result[1].nights[0].severity, .concerning)
        XCTAssertEqual(result[2].severity, .normal)
        XCTAssertEqual(result[2].nights[0].severity, .normal)
        XCTAssertEqual(result[3].severity, .normal) // Unrecorded weekday defaults to .normal
    }
}
