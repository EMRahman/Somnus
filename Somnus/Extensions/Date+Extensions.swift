import Foundation

extension Date {

    /// Formats as a localized clock time (e.g., "10:30 PM" or "22:30"), respecting the user's
    /// 12-hour / 24-hour system preference.
    var timeString: String {
        formatted(date: .omitted, time: .shortened)
    }

    /// Formats as a localized clock time using an explicit locale (for deterministic tests).
    func timeString(locale: Locale) -> String {
        formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale))
    }
}
