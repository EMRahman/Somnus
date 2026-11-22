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
///
/// Gestures are handled by UIKit recognizers rather than SwiftUI gestures so that a vertical
/// swipe starting on the chart still scrolls the enclosing `ScrollView`: the long press fails
/// as soon as the finger moves before the hold completes, handing the touch to the scroll view.
struct ChartDateSelectionOverlay: View {
    let proxy: ChartProxy
    let dates: [Date]
    let unit: Calendar.Component
    @Binding var selectedDate: Date?
    var sameSelection: (Date, Date) -> Bool = { $0 == $1 }

    var body: some View {
        GeometryReader { geometry in
            ChartGestureCatcher(
                onTap: { location in
                    guard let frame = proxy.plotFrame else { return }
                    let bounds = geometry[frame]
                    guard bounds.contains(location),
                          let snapped = snappedDate(atX: location.x - bounds.minX) else { return }
                    if let current = selectedDate, sameSelection(current, snapped) {
                        selectedDate = nil
                    } else {
                        selectedDate = snapped
                    }
                },
                onScrub: { location in
                    guard let frame = proxy.plotFrame else { return }
                    let bounds = geometry[frame]
                    let clampedX = min(max(0, location.x - bounds.minX), max(0, bounds.width - 0.5))
                    if let snapped = snappedDate(atX: clampedX) {
                        selectedDate = snapped
                    }
                }
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private func snappedDate(atX x: CGFloat) -> Date? {
        guard let rawDate = proxy.value(atX: x, as: Date.self) else { return nil }
        return SleepAnalysisEngine.nearestBucketDate(to: rawDate, in: dates, unit: unit)
    }
}

/// Transparent UIKit view that reports taps and long-press scrubs without blocking
/// the pan gesture of an enclosing scroll view.
private struct ChartGestureCatcher: UIViewRepresentable {
    var onTap: (CGPoint) -> Void
    var onScrub: (CGPoint) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.25
        longPress.allowableMovement = 10

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.require(toFail: longPress)

        view.addGestureRecognizer(longPress)
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.onScrub = onScrub
    }

    final class Coordinator: NSObject {
        var onTap: (CGPoint) -> Void = { _ in }
        var onScrub: (CGPoint) -> Void = { _ in }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            onTap(recognizer.location(in: recognizer.view))
        }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began, .changed:
                onScrub(recognizer.location(in: recognizer.view))
            default:
                break
            }
        }
    }
}
