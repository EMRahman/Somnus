import Foundation

/// A compact, non-redundant sleep pattern finding — the handful of things not already
/// visible as a chart, score, or metric card elsewhere in the app.
struct SleepPatternFlag: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let systemImage: String
}
