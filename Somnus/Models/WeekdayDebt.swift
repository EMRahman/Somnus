import Foundation

/// A calendar night is labelled by its evening, one day before SleepRecord's wake date.
struct WeekdayDebtNight: Identifiable {
    var id: Date { date }
    let date: Date
    let hours: Double?
    let occurrence: Int
}

struct WeekdayDebtSummary: Identifiable {
    var id: Int { weekday }
    /// Calendar weekday (Sunday = 1), displayed in Monday–Sunday order.
    let weekday: Int
    let nights: [WeekdayDebtNight]

    var label: String { Calendar.current.shortWeekdaySymbols[weekday - 1] }
    var fullLabel: String { Calendar.current.weekdaySymbols[weekday - 1] }
    var recordedCount: Int { nights.compactMap(\.hours).count }
    var averageHours: Double? {
        let recorded = nights.compactMap(\.hours)
        guard !recorded.isEmpty else { return nil }
        return recorded.reduce(0, +) / Double(recorded.count)
    }
}

struct WeekdayDebtBucket: Identifiable {
    var id: Date { date }
    let date: Date
    let hours: Double?
    let recordedCount: Int
}
