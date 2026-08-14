import SwiftUI

/// A horizontal stacked bar showing sleep stage proportions.
struct SleepStageBar: View {
    let stages: [StageChartDataPoint]
    var height: CGFloat = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                HStack(spacing: 1) {
                    ForEach(stages) { stage in
                        if stage.percentage > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(stage.stage.swiftUIColor)
                                .frame(width: max(2, geometry.size.width * stage.percentage))
                        }
                    }
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: height / 2))

            // Legend
            HStack(spacing: 12) {
                ForEach(stages.filter { $0.percentage > 0.01 }) { stage in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(stage.stage.swiftUIColor)
                            .frame(width: 8, height: 8)

                        Text("\(stage.stage.rawValue) \(String(format: "%.0f%%", stage.percentage * 100))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SleepStageBar(
            stages: [
                StageChartDataPoint(stage: .deepSleep, minutes: 60, percentage: 0.20),
                StageChartDataPoint(stage: .remSleep, minutes: 75, percentage: 0.25),
                StageChartDataPoint(stage: .coreSleep, minutes: 140, percentage: 0.45),
                StageChartDataPoint(stage: .awake, minutes: 30, percentage: 0.10)
            ]
        )
    }
    .padding()
}
