import SwiftUI
import Charts

struct WeekdayDebtChart: View {
    let summaries: [WeekdayDebtSummary]
    let period: TimePeriod
    @State private var selectedWeekday = 2
    @State private var selectedDetailDate: Date?

    private var isMonthly: Bool { period == .monthly }
    private var selected: WeekdayDebtSummary? {
        summaries.first { $0.weekday == selectedWeekday }
    }
    private var detailComponent: Calendar.Component { period == .yearly ? .month : .year }
    private var detailBuckets: [WeekdayDebtBucket] {
        guard let selected else { return [] }
        return SleepAnalysisEngine.weekdayDebtBuckets(for: selected, component: detailComponent)
    }
    private var selectedDetailBucket: WeekdayDebtBucket? {
        guard let selectedDetailDate else { return nil }
        return detailBuckets.first { $0.date == selectedDetailDate }
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
                    let isSelected = selectedWeekday == summary.weekday
                    Button {
                        selectedWeekday = summary.weekday
                    } label: {
                        VStack(spacing: 3) {
                            Text(summary.label)
                                .fontWeight(isSelected ? .bold : .medium)
                            Text(summary.recordedCount == 0 ? "—" : "\(summary.recordedCount)")
                                .foregroundStyle(isSelected ? .primary : .secondary)
                        }
                        .font(.caption2)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
                                .padding(.horizontal, 2)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(isSelected ? Color.primary : .secondary)
                    .accessibilityLabel("\(summary.fullLabel) nights, \(summary.recordedCount) recorded")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                Label("<0.5h", systemImage: "circle.fill")
                    .foregroundStyle(Color.shortfallLow)
                Label("0.5–1h", systemImage: "circle.fill")
                    .foregroundStyle(Color.shortfallModerate)
                Label("1h+", systemImage: "circle.fill")
                    .foregroundStyle(Color.shortfallHigh)
                Label("No data", systemImage: "xmark")
                    .foregroundStyle(.secondary)
            }
            .font(.caption2)

            Text("Nights are labelled by their evening: Monday night includes Tuesday morning.\(isMonthly ? " Bars run oldest to newest within each weekday." : " Averages include recorded nights with no shortfall.")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .onChange(of: period) { _, _ in
            selectedDetailDate = nil
        }
        .onChange(of: selectedWeekday) { _, _ in
            selectedDetailDate = nil
        }
        .onChange(of: detailBuckets.map(\.date)) { _, dates in
            if let selectedDetailDate, !dates.contains(selectedDetailDate) {
                self.selectedDetailDate = nil
            }
        }
    }

    private var overviewChart: some View {
        Chart {
            if let selectedIndex = summaries.firstIndex(where: { $0.weekday == selectedWeekday }) {
                let x = Double(selectedIndex)
                RectangleMark(
                    xStart: .value("Weekday", x - 0.42),
                    xEnd: .value("Weekday", x + 0.42),
                    yStart: .value("Shortfall", 0.0),
                    yEnd: .value("Shortfall", yMaximum)
                )
                .foregroundStyle(Color.primary.opacity(0.08))
                .cornerRadius(6)
                .accessibilityHidden(true)
            }

            ForEach(Array(summaries.enumerated()), id: \.element.id) { index, summary in
                if isMonthly {
                    ForEach(summary.nights) { night in
                        let x = Double(index) + (Double(night.occurrence) - Double(summary.nights.count - 1) / 2) * 0.15
                        if let hours = night.hours, hours > 0 {
                            BarMark(x: .value("Weekday", x), y: .value("Shortfall", hours), width: .fixed(5))
                                .foregroundStyle(Color.shortfallColor(hours: hours))
                                .cornerRadius(2)
                                .accessibilityLabel(night.date.formatted(.dateTime.weekday(.wide).month().day()))
                                .accessibilityValue(String(format: "%.1f hours shortfall", hours))
                        } else {
                            PointMark(x: .value("Weekday", x), y: .value("Shortfall", 0))
                                .symbol(night.hours == nil ? .cross : .circle)
                                .symbolSize(night.hours == nil ? 18 : 12)
                                .foregroundStyle(night.hours == nil ? Color.secondary : Color.shortfallColor(hours: 0))
                                .accessibilityLabel(night.date.formatted(.dateTime.weekday(.wide).month().day()))
                                .accessibilityValue(night.hours == nil ? "No data" : "No shortfall")
                        }
                    }
                } else if let hours = summary.averageHours, hours > 0 {
                    averageBar(summary, index: index, hours: hours)
                } else {
                    PointMark(x: .value("Weekday", Double(index)), y: .value("Shortfall", 0))
                        .symbol(summary.averageHours == nil ? .cross : .circle)
                        .symbolSize(20)
                        .foregroundStyle(summary.averageHours == nil ? Color.secondary : Color.shortfallColor(hours: 0))
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

    // A numeric x scale has no band step, so `.ratio` widths collapse to zero and only
    // the annotation renders. Give the bar explicit edges, anchored at zero, instead.
    private func averageBar(_ summary: WeekdayDebtSummary, index: Int, hours: Double) -> some ChartContent {
        let x = Double(index)
        let isSelected = summary.weekday == selectedWeekday
        let color: Color = Color.shortfallColor(hours: hours)
        let label: String = String(format: "%.1f", hours)
        let accessibilityLabel: String = "\(summary.fullLabel) nights"
        let accessibilityValue: String = String(
            format: "%.1f hours average, %d recorded nights", hours, summary.recordedCount
        )
        let xStart: PlottableValue<Double> = .value("Weekday", x - 0.325)
        let xEnd: PlottableValue<Double> = .value("Weekday", x + 0.325)
        let yStart: PlottableValue<Double> = .value("Shortfall", 0.0)
        let yEnd: PlottableValue<Double> = .value("Shortfall", hours)
        let bar = RectangleMark(xStart: xStart, xEnd: xEnd, yStart: yStart, yEnd: yEnd)
        return bar
            .foregroundStyle(color)
            .cornerRadius(4)
            .annotation(position: .top) {
                Text(label)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            }
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue)
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
            .fontWeight(summary.severity == .normal ? .regular : .medium)
            .foregroundStyle(summary.severity == .normal ? Color.secondary : Color.shortfallColor(for: summary.severity))
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
                .fontWeight(night.severity == .normal ? .regular : .medium)
                .foregroundStyle(night.hours == nil ? Color.secondary : (night.severity == .normal ? Color.primary : Color.shortfallColor(for: night.severity)))
        }
        .font(.caption2)
        .accessibilityElement(children: .combine)
    }

    private var detailChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(period == .yearly ? "Monthly averages" : "Yearly averages")
                .font(.caption.weight(.medium))

            if let bucket = selectedDetailBucket {
                detailSelectionSummary(bucket)
            }

            Chart {
                if let bucket = selectedDetailBucket {
                    RuleMark(x: .value("Selected", bucket.date, unit: detailComponent))
                        .foregroundStyle(Color.secondary.opacity(0.35))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .accessibilityHidden(true)
                }

                ForEach(detailBuckets) { bucket in
                    let isSelected = selectedDetailBucket == nil || bucket.date == selectedDetailBucket?.date
                    let label = SleepAnalysisEngine.bucketLabel(for: bucket.date, period: period)

                    if let hours = bucket.hours, hours > 0 {
                        BarMark(x: .value("Period", bucket.date, unit: detailComponent), y: .value("Average shortfall", hours))
                            .foregroundStyle(Color.shortfallColor(hours: hours))
                            .opacity(isSelected ? 1.0 : 0.45)
                            .cornerRadius(3)
                            .annotation(position: .top, spacing: 2) {
                                if bucket.date == selectedDetailBucket?.date {
                                    Text(String(format: "%.1fh", hours))
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .accessibilityLabel(label)
                            .accessibilityValue(String(format: "%.1f hours average, %d recorded nights", hours, bucket.recordedCount))
                    } else {
                        PointMark(x: .value("Period", bucket.date, unit: detailComponent), y: .value("Average shortfall", 0))
                            .symbol(bucket.hours == nil ? .cross : .circle)
                            .foregroundStyle(bucket.hours == nil ? Color.secondary : Color.shortfallColor(hours: 0))
                            .opacity(isSelected ? 1.0 : 0.45)
                            .accessibilityLabel(label)
                            .accessibilityValue(bucket.hours == nil ? "No data" : "No shortfall")
                    }
                }
            }
            .chartYScale(domain: 0...max(1, ((detailBuckets.compactMap(\.hours).max() ?? 0) * 1.15).rounded(.up)))
            .chartYAxis { debtAxis }
            .chartXAxis {
                AxisMarks(values: detailDates) { value in
                    AxisValueLabel(format: period == .yearly ? .dateTime.month(.abbreviated).year(.twoDigits) : .dateTime.year())
                }
            }
            .chartOverlay { proxy in
                ChartDateSelectionOverlay(
                    proxy: proxy,
                    dates: detailBuckets.map(\.date),
                    unit: detailComponent,
                    selectedDate: $selectedDetailDate
                )
            }
            .frame(height: 150)
            .accessibilityIdentifier("weekday-debt-history")
        }
    }

    private func detailSelectionSummary(_ bucket: WeekdayDebtBucket) -> some View {
        ChartSelectionHeader(
            title: SleepAnalysisEngine.bucketLabel(for: bucket.date, period: period),
            accessibilityIdentifier: "weekday-debt-history-selection-summary",
            onClear: { selectedDetailDate = nil }
        ) {
            if let hours = bucket.hours {
                let nightWord = bucket.recordedCount == 1 ? "night" : "nights"
                let detail = hours < 0.05
                    ? "No shortfall · \(bucket.recordedCount) recorded \(nightWord)"
                    : String(format: "%.1fh average shortfall · %d recorded %@", hours, bucket.recordedCount, nightWord)
                Text(detail)
                    .font(.caption)
                    .fontWeight(bucket.severity == .normal ? .regular : .medium)
                    .foregroundStyle(bucket.severity == .normal ? Color.secondary : Color.shortfallColor(for: bucket.severity))
            } else {
                Text("No recorded nights")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var detailDates: [Date] {
        let step = max(1, Int(ceil(Double(detailBuckets.count) / 5)))
        return detailBuckets.enumerated().compactMap { $0.offset % step == 0 ? $0.element.date : nil }
    }
}
