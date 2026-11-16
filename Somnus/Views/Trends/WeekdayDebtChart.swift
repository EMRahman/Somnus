import SwiftUI
import Charts

struct WeekdayDebtChart: View {
    let summaries: [WeekdayDebtSummary]
    let period: TimePeriod
    @State private var selectedWeekday = 2

    private var isMonthly: Bool { period == .monthly }
    private var selected: WeekdayDebtSummary? {
        summaries.first { $0.weekday == selectedWeekday }
    }
    private var detailComponent: Calendar.Component { period == .yearly ? .month : .year }
    private var detailBuckets: [WeekdayDebtBucket] {
        guard let selected else { return [] }
        return SleepAnalysisEngine.weekdayDebtBuckets(for: selected, component: detailComponent)
    }
    private var yMaximum: Double {
        let hours = isMonthly
            ? summaries.flatMap { $0.nights.compactMap(\.hours) }
            : summaries.compactMap(\.averageHours)
        return max(1, ((hours.max() ?? 0) * 1.15).rounded(.up))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isMonthly ? "Nightly shortfall · hours" : "Average shortfall per recorded night · hours")
                .font(.caption)
                .foregroundStyle(.secondary)

            overviewChart

            // These are also the chart's weekday labels. Full button hit areas allow
            // selection by touch and VoiceOver without targeting a narrow bar.
            HStack(spacing: 0) {
                ForEach(summaries) { summary in
                    Button {
                        selectedWeekday = summary.weekday
                    } label: {
                        VStack(spacing: 3) {
                            Text(summary.label)
                                .fontWeight(selectedWeekday == summary.weekday ? .bold : .regular)
                            Text(summary.recordedCount == 0 ? "—" : "\(summary.recordedCount)")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption2)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedWeekday == summary.weekday ? Color.primary : .secondary)
                    .accessibilityLabel("\(summary.fullLabel) nights, \(summary.recordedCount) recorded")
                    .accessibilityAddTraits(selectedWeekday == summary.weekday ? .isSelected : [])
                    .accessibilityIdentifier("weekday-debt-\(summary.weekday)")
                }
            }
            // Reserve the same trailing space as the chart's fixed-width y-axis labels.
            .padding(.trailing, 34)

            if let selected {
                selectedSummary(selected)

                if isMonthly {
                    monthlyDetails(selected)
                } else {
                    detailChart
                }
            }

            HStack(spacing: 12) {
                Label("Recorded", systemImage: "circle.fill")
                    .foregroundStyle(Color.chartBarBelow)
                Label("No data", systemImage: "xmark")
                    .foregroundStyle(.secondary)
            }
            .font(.caption2)

            Text("Nights are labelled by their evening: Monday night includes Tuesday morning.\(isMonthly ? " Bars run oldest to newest within each weekday." : " Averages include recorded nights with no shortfall.")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var overviewChart: some View {
        Chart {
            ForEach(Array(summaries.enumerated()), id: \.element.id) { index, summary in
                if isMonthly {
                    ForEach(summary.nights) { night in
                        let x = Double(index) + (Double(night.occurrence) - Double(summary.nights.count - 1) / 2) * 0.15
                        if let hours = night.hours, hours > 0 {
                            BarMark(x: .value("Weekday", x), y: .value("Shortfall", hours), width: .fixed(5))
                                .foregroundStyle(Color.chartBarBelow.opacity(summary.weekday == selectedWeekday ? 1 : 0.5))
                                .cornerRadius(2)
                                .accessibilityLabel(night.date.formatted(.dateTime.weekday(.wide).month().day()))
                                .accessibilityValue(String(format: "%.1f hours shortfall", hours))
                        } else {
                            PointMark(x: .value("Weekday", x), y: .value("Shortfall", 0))
                                .symbol(night.hours == nil ? .cross : .circle)
                                .symbolSize(night.hours == nil ? 18 : 12)
                                .foregroundStyle(night.hours == nil ? Color.secondary : Color.chartBarBelow)
                                .accessibilityLabel(night.date.formatted(.dateTime.weekday(.wide).month().day()))
                                .accessibilityValue(night.hours == nil ? "No data" : "No shortfall")
                        }
                    }
                } else if let hours = summary.averageHours, hours > 0 {
                    BarMark(x: .value("Weekday", Double(index)), y: .value("Average shortfall", hours), width: .ratio(0.65))
                        .foregroundStyle(Color.chartBarBelow.opacity(summary.weekday == selectedWeekday ? 1 : 0.5))
                        .cornerRadius(4)
                        .annotation(position: .top) {
                            Text(String(format: "%.1f", hours)).font(.caption2)
                        }
                        .accessibilityLabel("\(summary.fullLabel) nights")
                        .accessibilityValue(String(format: "%.1f hours average, %d recorded nights", hours, summary.recordedCount))
                } else {
                    PointMark(x: .value("Weekday", Double(index)), y: .value("Average shortfall", 0))
                        .symbol(summary.averageHours == nil ? .cross : .circle)
                        .symbolSize(20)
                        .foregroundStyle(summary.averageHours == nil ? Color.secondary : Color.chartBarBelow)
                        .accessibilityLabel("\(summary.fullLabel) nights")
                        .accessibilityValue(summary.averageHours == nil ? "No data" : "No shortfall")
                }
            }
        }
        .chartXScale(domain: -0.5...6.5)
        .chartYScale(domain: 0...yMaximum)
        .chartXAxis(.hidden)
        .chartYAxis { debtAxis }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let frame = proxy.plotFrame else { return }
                        let bounds = geometry[frame]
                        guard bounds.contains(location),
                              let value = proxy.value(atX: location.x - bounds.minX, as: Double.self) else { return }
                        let index = min(6, max(0, Int(value.rounded())))
                        if summaries.indices.contains(index) { selectedWeekday = summaries[index].weekday }
                    }
            }
        }
        .frame(height: 190)
    }

    private var debtAxis: some AxisContent {
        AxisMarks(position: .trailing) { value in
            AxisGridLine()
            AxisValueLabel {
                if let hours = value.as(Double.self) {
                    Text(String(format: "%gh", hours))
                        .font(.caption2)
                        .frame(width: 28, alignment: .leading)
                }
            }
        }
    }

    private func selectedSummary(_ summary: WeekdayDebtSummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(summary.fullLabel) nights")
                .font(.subheadline.weight(.semibold))
            Text(summary.averageHours.map {
                String(format: "%.1fh average shortfall · %d recorded nights", $0, summary.recordedCount)
            } ?? "No recorded nights in this period")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("weekday-debt-summary")
    }

    private func monthlyDetails(_ summary: WeekdayDebtSummary) -> some View {
        // Four or five dated values stay readable at large Dynamic Type sizes.
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(summary.nights) { night in nightDetail(night) }
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(summary.nights) { night in nightDetail(night) }
            }
        }
    }

    private func nightDetail(_ night: WeekdayDebtNight) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(night.date, format: .dateTime.day().month(.abbreviated))
                .foregroundStyle(.secondary)
            Text(night.hours.map { String(format: "%.1fh", $0) } ?? "No data")
        }
        .font(.caption2)
        .accessibilityElement(children: .combine)
    }

    private var detailChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(period == .yearly ? "Monthly averages" : "Yearly averages")
                .font(.caption.weight(.medium))
            Chart(detailBuckets) { bucket in
                if let hours = bucket.hours, hours > 0 {
                    BarMark(x: .value("Period", bucket.date, unit: detailComponent), y: .value("Average shortfall", hours))
                        .foregroundStyle(Color.chartBarBelow)
                        .cornerRadius(3)
                        .accessibilityLabel(bucket.date.formatted(period == .yearly ? .dateTime.month(.wide).year() : .dateTime.year()))
                        .accessibilityValue(String(format: "%.1f hours average, %d recorded nights", hours, bucket.recordedCount))
                } else {
                    PointMark(x: .value("Period", bucket.date, unit: detailComponent), y: .value("Average shortfall", 0))
                        .symbol(bucket.hours == nil ? .cross : .circle)
                        .foregroundStyle(bucket.hours == nil ? Color.secondary : Color.chartBarBelow)
                        .accessibilityLabel(bucket.date.formatted(.dateTime.month().year()))
                        .accessibilityValue(bucket.hours == nil ? "No data" : "No shortfall")
                }
            }
            .chartYScale(domain: 0...max(1, ((detailBuckets.compactMap(\.hours).max() ?? 0) * 1.15).rounded(.up)))
            .chartYAxis { debtAxis }
            .chartXAxis {
                AxisMarks(values: detailDates) { value in
                    AxisValueLabel(format: period == .yearly ? .dateTime.month(.abbreviated).year(.twoDigits) : .dateTime.year())
                }
            }
            .frame(height: 150)
            .accessibilityIdentifier("weekday-debt-history")
        }
    }

    private var detailDates: [Date] {
        let step = max(1, Int(ceil(Double(detailBuckets.count) / 5)))
        return detailBuckets.enumerated().compactMap { $0.offset % step == 0 ? $0.element.date : nil }
    }
}
