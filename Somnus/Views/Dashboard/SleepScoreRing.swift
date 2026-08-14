import SwiftUI

/// Animated circular ring displaying the overall sleep score.
struct SleepScoreRing: View {
    let score: SleepScore
    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [ringColor.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 50,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)

            // Background track
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 12)
                .frame(width: 140, height: 140)

            // Score arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: gradientColors,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))

            // Inner content
            VStack(spacing: 4) {
                Text("\(score.overall)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(score.grade.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ringColor)

                Image(systemName: score.grade.systemImage)
                    .font(.caption)
                    .foregroundStyle(ringColor)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animatedProgress = Double(score.overall) / 100.0
            }
        }
        .onChange(of: score.overall) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = Double(newValue) / 100.0
            }
        }
    }

    private var ringColor: Color {
        Color.scoreColor(for: score.overall)
    }

    private var gradientColors: [Color] {
        let base = ringColor
        return [base.opacity(0.6), base, base.opacity(0.8)]
    }
}

/// Compact score breakdown showing individual score components.
struct ScoreBreakdown: View {
    let score: SleepScore

    var body: some View {
        VStack(spacing: 12) {
            Text("Score Breakdown")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                ScoreRow(label: "Duration", score: score.durationScore, icon: "clock.fill")
                ScoreRow(label: "Efficiency", score: score.efficiencyScore, icon: "gauge.with.dots.needle.67percent")
                ScoreRow(label: "Consistency", score: score.consistencyScore, icon: "calendar.badge.clock")
                ScoreRow(label: "Sleep Stages", score: score.stageScore, icon: "chart.bar.fill")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ScoreRow: View {
    let label: String
    let score: Int
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.scoreColor(for: score))
                        .frame(width: geometry.size.width * CGFloat(score) / 100.0)
                }
            }
            .frame(width: 80, height: 8)

            Text("\(score)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.scoreColor(for: score))
                .frame(width: 30, alignment: .trailing)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SleepScoreRing(score: SleepScore(
            overall: 72,
            durationScore: 65,
            efficiencyScore: 80,
            consistencyScore: 70,
            stageScore: 75
        ))

        ScoreBreakdown(score: SleepScore(
            overall: 72,
            durationScore: 65,
            efficiencyScore: 80,
            consistencyScore: 70,
            stageScore: 75
        ))
    }
    .padding()
}
