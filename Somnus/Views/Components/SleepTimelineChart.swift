import SwiftUI
import Charts

/// A per-night sleep timeline. The y-axis is clock time — evening at the top,
/// morning at the bottom — and each night is a vertical bar running from bedtime
/// down to wake, coloured by sleep stage and labelled with the hours slept.
struct SleepTimelineChart: View {
    let nights: [NightTimelinePoint]

    /// Stages shown in the legend, in the order they typically appear through the night.
    private let legendStages: [SleepStage] = [.deepSleep, .coreSleep, .remSleep, .awake]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart {
                // Stage-coloured segments make up the body of each night's bar.
                ForEach(nights) { night in
                    ForEach(night.segments) { segment in
                        BarMark(
                            x: .value("Night", night.date, unit: .day),
                            yStart: .value("Start", plotValue(segment.start)),
                            yEnd: .value("End", plotValue(segment.end)),
                            width: .ratio(0.8)
                        )
                        .foregroundStyle(segment.stage.swiftUIColor)
                        .cornerRadius(1)
                    }
                }

                // A clear full-height bar per night carries the centered hours label,
                // drawn after the segments so the text sits on top.
                ForEach(nights) { night in
                    BarMark(
                        x: .value("Night", night.date, unit: .day),
                        yStart: .value("Bedtime", plotValue(night.bedtime)),
                        yEnd: .value("Wake", plotValue(night.wakeTime)),
                        width: .ratio(0.8)
                    )
                    .foregroundStyle(.clear)
                    .annotation(position: .overlay, alignment: .center) {
                        Text(hoursText(night.sleepHours))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                }
            }
            .chartYScale(domain: yBounds.min...yBounds.max)
            .chartYAxis {
                AxisMarks(values: axisValues) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let plotted = value.as(Double.self) {
                            Text(clockLabel(plotted))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 260)

            legend
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 14) {
            ForEach(legendStages, id: \.self) { stage in
                HStack(spacing: 5) {
                    Circle()
                        .fill(stage.swiftUIColor)
                        .frame(width: 8, height: 8)
                    Text(stage.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Clock-Time Encoding

    /// Maps a timestamp to the plotted y-value. Raw "hours since midnight" are folded so
    /// after-midnight morning times sit *below* the previous evening (e.g. 7am → 31), then
    /// negated so that Charts — which renders larger values higher — puts the evening on top.
    private func plotValue(_ date: Date) -> Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        var hours = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0
        if hours < 12 { hours += 24 } // fold the small hours onto the evening's "day"
        return -hours
    }

    /// Unpadded [low, high] plotted-value extent of the data, widened to at least a 6h span so a
    /// short or single record doesn't zoom in excessively or drop every gridline.
    private var clockExtent: (low: Double, high: Double) {
        let values = nights.flatMap { [plotValue($0.bedtime), plotValue($0.wakeTime)] }
        guard var low = values.min(), var high = values.max() else {
            return (-33, -21) // fallback: 9am (bottom) → 9pm (top)
        }
        let minSpan = 6.0
        if high - low < minSpan {
            let center = (low + high) / 2
            low = center - minSpan / 2
            high = center + minSpan / 2
        }
        return (low, high)
    }

    /// Padded y-domain covering the earliest bedtime and latest wake across all nights.
    private var yBounds: (min: Double, max: Double) {
        let extent = clockExtent
        return (extent.low - 0.5, extent.high + 0.5)
    }

    /// Grid/label values every three hours (9PM, 12AM, 3AM, …). Kept strictly within the data's
    /// clock range — using the unpadded extent with ceil/floor — so no gridline lands on the
    /// padded plot edge, where Charts would clamp it and strike through the x-axis day labels.
    private var axisValues: [Double] {
        let extent = clockExtent
        let earliestRaw = Int(ceil(-extent.high)) // evening side (smallest raw hour)
        let latestRaw = Int(floor(-extent.low))   // morning side (largest raw hour)
        return stride(from: earliestRaw, through: latestRaw, by: 1)
            .filter { $0 % 3 == 0 }
            .map { Double(-$0) }
    }

    /// Formats a plotted value back into a clock label, e.g. "9PM", "12AM", "6AM".
    private func clockLabel(_ plotted: Double) -> String {
        let raw = Int((-plotted).rounded())
        let hour24 = ((raw % 24) + 24) % 24
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12
        let suffix = hour24 < 12 ? "AM" : "PM"
        return "\(hour12)\(suffix)"
    }

    private func hoursText(_ hours: Double) -> String {
        String(format: "%.1fh", hours)
    }
}

#if DEBUG
#Preview {
    SleepTimelineChart(nights: SleepAnalysisEngine.nightlyTimeline(from: SleepRecord.previewRecords))
        .padding()
}
#endif
