import SwiftUI

/// A compact card displaying a single metric with label, value, and optional trend.
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    var trend: TrendDirection?
    var accentColor: Color = .purple
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(accentColor)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let trend {
                    Image(systemName: trend.systemImage)
                        .font(.caption2)
                        .foregroundStyle(trendColor(trend))
                }
            }

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func trendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .improving: return .trendImproving
        case .stable: return .trendStable
        case .declining: return .trendDeclining
        }
    }
}

/// A larger metric card for primary stats.
struct PrimaryMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    var color: Color = .purple

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            MetricCard(
                title: "Average",
                value: "7.2h",
                icon: "moon.fill",
                trend: .improving
            )
            MetricCard(
                title: "Efficiency",
                value: "89%",
                icon: "gauge.with.dots.needle.67percent",
                trend: .stable
            )
        }

        HStack(spacing: 12) {
            PrimaryMetricCard(
                title: "Sleep Score",
                value: "82",
                subtitle: "Good",
                icon: "star.circle.fill",
                color: .green
            )
            PrimaryMetricCard(
                title: "Sleep Debt",
                value: "2.5h",
                subtitle: "This Week",
                icon: "exclamationmark.arrow.circlepath",
                color: .orange
            )
        }
    }
    .padding()
    .background(Color(uiColor: .systemBackground))
}
