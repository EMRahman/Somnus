import Foundation

extension Date {

    /// Formats as time string (e.g., "10:30 PM").
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
}
