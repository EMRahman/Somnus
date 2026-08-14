import SwiftUI

extension Color {

    // MARK: - Sleep Stage Colors

    static let stageDeep = Color(red: 0.13, green: 0.15, blue: 0.52)      // Dark indigo
    static let stageREM = Color(red: 0.35, green: 0.28, blue: 0.72)       // Purple
    static let stageCore = Color(red: 0.55, green: 0.48, blue: 0.85)      // Light purple
    static let stageAwake = Color(red: 1.0, green: 0.60, blue: 0.35)      // Orange
    static let stageInBed = Color(red: 0.65, green: 0.65, blue: 0.75)     // Gray

    // MARK: - Score Colors

    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 90...100: return .green
        case 75..<90: return Color(red: 0.40, green: 0.78, blue: 0.35)
        case 60..<75: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    // MARK: - Trend Colors

    static let trendImproving = Color.green
    static let trendStable = Color.blue
    static let trendDeclining = Color.red

    // MARK: - Severity Colors

    static let statConcerning = Color.orange
    static let statCritical = Color.red

    // MARK: - Chart Colors

    static let chartBar = Color(red: 0.45, green: 0.38, blue: 0.82)
    static let chartBarBelow = Color.orange.opacity(0.8)
}

// MARK: - Color for SleepStage

extension SleepStage {
    var swiftUIColor: Color {
        switch self {
        case .deepSleep: return .stageDeep
        case .remSleep: return .stageREM
        case .coreSleep: return .stageCore
        case .awake: return .stageAwake
        case .inBed: return .stageInBed
        case .unspecified: return .gray
        }
    }
}
