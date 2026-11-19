import XCTest
@testable import Somnus

final class AppReviewTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func day(_ day: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    @MainActor
    func testRequiresThreeDistinctDaysAndAFullWeek() async {
        let suite = "AppReviewTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let review = AppReview(defaults: defaults)

        review.recordSleepCheck(on: day(1), calendar: calendar)
        review.recordSleepCheck(on: day(1, hour: 18), calendar: calendar)
        review.recordSleepCheck(on: day(2), calendar: calendar)
        XCTAssertFalse(review.canRequest(on: day(8), calendar: calendar))

        review.recordSleepCheck(on: day(3), calendar: calendar)
        XCTAssertFalse(review.canRequest(on: day(7), calendar: calendar))
        XCTAssertTrue(review.canRequest(on: day(8), calendar: calendar))
    }

    @MainActor
    func testRequestsOnceOnALaterDayAndPersistsAcrossLaunches() async {
        let suite = "AppReviewTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let review = AppReview(defaults: defaults)

        for checkDay in [1, 5, 8] {
            review.recordSleepCheck(on: day(checkDay), calendar: calendar)
        }

        let reopenedReview = AppReview(defaults: UserDefaults(suiteName: suite)!)
        XCTAssertFalse(reopenedReview.markRequest(on: day(8, hour: 18), calendar: calendar))
        XCTAssertTrue(reopenedReview.markRequest(on: day(9), calendar: calendar))
        XCTAssertFalse(review.markRequest(on: day(10), calendar: calendar))
    }
}
