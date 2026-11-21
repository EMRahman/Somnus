import SwiftUI
import Charts

/// Compact inspection header displayed above a chart while a bucket or night is selected.
struct ChartSelectionHeader<Details: View>: View {
    let title: String
    let accessibilityIdentifier: String
    let onClear: () -> Void
    @ViewBuilder let details: () -> Details

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                details()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(accessibilityIdentifier)

            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear selection")
        }
    }
}

/// Interactive tap-to-toggle and long-press-to-scrub date selection overlay for Swift Charts.
struct ChartDateSelectionOverlay: View {
    let proxy: ChartProxy
    let dates: [Date]
    let unit: Calendar.Component
    @Binding var selectedDate: Date?
    var sameSelection: (Date, Date) -> Bool = { $0 == $1 }

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    guard let frame = proxy.plotFrame else { return }
                    let bounds = geometry[frame]
                    guard bounds.contains(location),
                          let snapped = snappedDate(atX: location.x - bounds.minX) else { return }
                    if let current = selectedDate, sameSelection(current, snapped) {
                        selectedDate = nil
                    } else {
                        selectedDate = snapped
                    }
                }
                .gesture(
                    LongPressGesture(minimumDuration: 0.25)
                        .sequenced(before: DragGesture(minimumDistance: 0))
                        .onChanged { value in
                            guard case .second(true, let drag?) = value,
                                  let frame = proxy.plotFrame else { return }
                            let bounds = geometry[frame]
                            let clampedX = min(max(0, drag.location.x - bounds.minX), max(0, bounds.width - 0.5))
                            if let snapped = snappedDate(atX: clampedX) {
                                selectedDate = snapped
                            }
                        }
                )
        }
    }

    private func snappedDate(atX x: CGFloat) -> Date? {
        guard let rawDate = proxy.value(atX: x, as: Date.self) else { return nil }
        return SleepAnalysisEngine.nearestBucketDate(to: rawDate, in: dates, unit: unit)
    }
}
