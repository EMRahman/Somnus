import Foundation

@MainActor
struct AppReview {
    private static let sleepCheckDatesKey = "appReview.sleepCheckDates"
    private static let requestedKey = "appReview.requested"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var hasRequestedReview: Bool {
        defaults.bool(forKey: Self.requestedKey)
    }

    private var sleepCheckDates: [Date] {
        defaults.array(forKey: Self.sleepCheckDatesKey) as? [Date] ?? []
    }

    func recordSleepCheck(on date: Date = .now, calendar: Calendar = .current) {
        #if DEBUG
        guard !ScreenshotSupport.isEnabled else { return }
        #endif
        let dates = sleepCheckDates
        guard !hasRequestedReview, dates.count < 3 else { return }
        if let last = dates.last, calendar.compare(date, to: last, toGranularity: .day) != .orderedDescending {
            return
        }
        defaults.set(dates + [date], forKey: Self.sleepCheckDatesKey)
    }

    func canRequest(on date: Date = .now, calendar: Calendar = .current) -> Bool {
        #if DEBUG
        guard !ScreenshotSupport.isEnabled else { return false }
        #endif
        let dates = sleepCheckDates
        guard !hasRequestedReview, dates.count == 3, let first = dates.first, let last = dates.last,
              let earliest = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: first))
        else { return false }

        return date >= earliest && calendar.compare(date, to: last, toGranularity: .day) == .orderedDescending
    }

    func markRequest(on date: Date = .now, calendar: Calendar = .current) -> Bool {
        guard canRequest(on: date, calendar: calendar) else { return false }
        defaults.set(true, forKey: Self.requestedKey)
        return true
    }
}
