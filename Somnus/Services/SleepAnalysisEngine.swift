import Foundation

/// Analyzes sleep data and computes scores, metrics, and identifies patterns.
struct SleepAnalysisEngine {

    // MARK: - Target Constants

    static let minimumSleepHours: Double = 7.0
    static let idealSleepHours: Double = 8.0
    static let maximumSleepHours: Double = 9.0
    static let idealDeepSleepPercentage: Double = 0.20 // 20% of total sleep
    static let idealREMPercentage: Double = 0.25        // 25% of total sleep
    static let idealEfficiency: Double = 0.85           // 85%

    /// The user's nightly sleep goal from Settings ("Target Sleep" slider).
    /// Falls back to `idealSleepHours` when unset (UserDefaults returns 0 for a missing key).
    static var targetSleepHours: Double {
        let stored = UserDefaults.standard.double(forKey: "sleepGoalHours")
        return stored > 0 ? stored : idealSleepHours
    }

    /// The user's nightly minimum from Settings ("Minimum Acceptable" slider).
    /// Falls back to `minimumSleepHours` when unset (UserDefaults returns 0 for a missing key).
    static var minimumAcceptableHours: Double {
        let stored = UserDefaults.standard.double(forKey: "sleepGoalMinimum")
        return stored > 0 ? stored : minimumSleepHours
    }

    // MARK: - Score Calculation

    /// Computes a comprehensive sleep score for a set of records.
    /// Records are first collapsed to one per night (`mergedNightlyRecords`): stage-less
    /// "in bed only" records are dropped and fragmented sessions are merged, so every
    /// component scores nights the same way the debt and compliance figures count them —
    /// a night split into two sessions isn't scored as two short, suspiciously efficient
    /// nights, and untracked nights don't drag every component toward zero.
    static func calculateScore(for records: [SleepRecord]) -> SleepScore {
        let nights = mergedNightlyRecords(from: records)
        guard !nights.isEmpty else { return .zero }

        let durationScore = calculateDurationScore(nights)
        let efficiencyScore = calculateEfficiencyScore(nights)
        let consistencyScore = calculateConsistencyScore(nights)
        let stageScore = calculateStageScore(nights)

        // Weighted overall score
        let overall = Int(
            Double(durationScore) * 0.35 +
            Double(efficiencyScore) * 0.25 +
            Double(consistencyScore) * 0.20 +
            Double(stageScore) * 0.20
        )

        return SleepScore(
            overall: min(100, max(0, overall)),
            durationScore: durationScore,
            efficiencyScore: efficiencyScore,
            consistencyScore: consistencyScore,
            stageScore: stageScore
        )
    }

    /// Computes full metrics for a period.
    static func computeMetrics(records: [SleepRecord], period: TimePeriod) -> SleepMetrics {
        let score = calculateScore(for: records)
        return SleepMetrics(period: period, records: records, score: score)
    }

    // MARK: - Individual Score Components

    private static func calculateDurationScore(_ records: [SleepRecord]) -> Int {
        let avgHours = records.map(\.totalSleepHours).reduce(0, +) / Double(records.count)

        if avgHours >= minimumSleepHours && avgHours <= maximumSleepHours {
            // Perfect range: 7-9 hours
            let distanceFromIdeal = abs(avgHours - idealSleepHours)
            return Int(100.0 - distanceFromIdeal * 10.0)
        } else if avgHours < minimumSleepHours {
            // Under-sleeping: penalize proportionally
            let deficit = minimumSleepHours - avgHours
            return max(0, Int(70.0 - deficit * 20.0))
        } else {
            // Over-sleeping (> 9 hours): slight penalty
            let excess = avgHours - maximumSleepHours
            return max(40, Int(80.0 - excess * 15.0))
        }
    }

    private static func calculateEfficiencyScore(_ records: [SleepRecord]) -> Int {
        let avgEfficiency = records.map(\.sleepEfficiency).reduce(0, +) / Double(records.count)
        if avgEfficiency >= idealEfficiency {
            return min(100, Int(avgEfficiency * 100.0 + 10.0))
        }
        return max(0, Int(avgEfficiency * 120.0 - 10.0))
    }

    private static func calculateConsistencyScore(_ records: [SleepRecord]) -> Int {
        guard records.count >= 2 else { return 70 } // Default for single night

        let calendar = Calendar.current

        // Bedtime consistency (standard deviation in minutes)
        let bedtimeMinutes = records.map { record -> Double in
            let components = calendar.dateComponents([.hour, .minute], from: record.bedtime)
            var minutes = Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
            if minutes < 720 { minutes += 1440 } // Normalize past-midnight times
            return minutes
        }

        let bedtimeMean = bedtimeMinutes.reduce(0, +) / Double(bedtimeMinutes.count)
        let bedtimeVariance = bedtimeMinutes.map { pow($0 - bedtimeMean, 2) }.reduce(0, +) / Double(bedtimeMinutes.count)
        let bedtimeStdDev = sqrt(bedtimeVariance)

        // Score: 0 std dev = 100, 120+ min std dev = 0
        let consistencyScore = max(0, 100.0 - (bedtimeStdDev / 120.0) * 100.0)

        return Int(consistencyScore)
    }

    private static func calculateStageScore(_ records: [SleepRecord]) -> Int {
        let recordsWithStages = records.filter { !$0.stages.isEmpty }
        guard !recordsWithStages.isEmpty else { return 60 } // Default if no stage data

        var totalScore = 0.0

        for record in recordsWithStages {
            let totalSleep = record.totalSleepDuration
            guard totalSleep > 0 else { continue }

            let deepPercent = record.deepSleepDuration / totalSleep
            let remPercent = record.remSleepDuration / totalSleep

            // Score deep sleep (ideal ~20%)
            let deepScore = 100.0 - min(100.0, abs(deepPercent - idealDeepSleepPercentage) * 500.0)

            // Score REM sleep (ideal ~25%)
            let remScore = 100.0 - min(100.0, abs(remPercent - idealREMPercentage) * 400.0)

            totalScore += (deepScore * 0.5 + remScore * 0.5)
        }

        return max(0, min(100, Int(totalScore / Double(recordsWithStages.count))))
    }

    // MARK: - Trend Analysis

    /// Computes chart data points for sleep duration over time.
    static func durationChartData(from records: [SleepRecord]) -> [SleepChartDataPoint] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return records.map { record in
            SleepChartDataPoint(
                date: record.date,
                hours: record.totalSleepHours,
                label: formatter.string(from: record.date)
            )
        }
    }

    /// Collapses each night's sessions into a single record — first bedtime to last wake,
    /// stages concatenated in time order — and drops stage-less "in bed only" records
    /// (0h asleep). The full-record counterpart to `nightlyTotals` for callers that need
    /// per-night efficiency, stage minutes, or bed/wake times rather than just hour totals.
    /// Note a merged night's `sleepEfficiency` counts the awake gap between fragments as
    /// time in bed, which is the honest reading of an interrupted night.
    static func mergedNightlyRecords(from records: [SleepRecord]) -> [SleepRecord] {
        let calendar = Calendar.current
        let tracked = records.filter { $0.totalSleepHours > 0 }
        return Dictionary(grouping: tracked) { calendar.startOfDay(for: $0.date) }
            .map { night, sessions -> SleepRecord in
                let sorted = sessions.sorted { $0.bedtime < $1.bedtime }
                guard sorted.count > 1 else { return sorted[0] }
                return SleepRecord(
                    date: night,
                    bedtime: sorted[0].bedtime,
                    wakeTime: sorted.map(\.wakeTime).max() ?? sorted[0].wakeTime,
                    stages: sorted.flatMap(\.stages).sorted { $0.startDate < $1.startDate }
                )
            }
            .sorted { $0.date < $1.date }
    }

    /// Collapses multiple sleep sessions recorded on the same calendar night into a single
    /// total per night, sorted by date. `groupSamplesIntoRecords` splits sessions more than
    /// 2h apart into separate records (a fragmented night, or a nap), so nightly debt math
    /// must recombine them before applying one nightly target.
    static func nightlyTotals(from records: [SleepRecord]) -> [(date: Date, hours: Double)] {
        let calendar = Calendar.current
        return Dictionary(grouping: records) { calendar.startOfDay(for: $0.date) }
            .map { (date: $0.key, hours: $0.value.reduce(0) { $0 + $1.totalSleepHours }) }
            .sorted { $0.date < $1.date }
    }

    /// Builds one timeline bar per night for the sleep timeline chart. Sessions recorded on
    /// the same night (split by `groupSamplesIntoRecords` when >2h apart) are merged so a
    /// fragmented night renders as a single bar spanning its first bedtime to its last wake.
    /// Nights without recorded sleep (e.g. pre-2022 "in bed only" records) are skipped rather
    /// than shown as time-in-bed, matching how the metrics and debt treat them as untracked.
    static func nightlyTimeline(from records: [SleepRecord]) -> [NightTimelinePoint] {
        let calendar = Calendar.current
        return Dictionary(grouping: records) { calendar.startOfDay(for: $0.date) }
            .compactMap { night, recs -> NightTimelinePoint? in
                let sleepHours = recs.reduce(0) { $0 + $1.totalSleepHours }
                guard sleepHours > 0 else { return nil }

                let bedtime = recs.map(\.bedtime).min() ?? night
                let wakeTime = recs.map(\.wakeTime).max() ?? night

                // Merge stage samples across the night's sessions, ordered by start time so
                // fragmented nights render consistently.
                let segments = recs
                    .flatMap { record in
                        record.stages
                            .filter { $0.stage != .inBed }   // "in bed" is the container, not a stage
                            .map { StageSegment(stage: $0.stage, start: $0.startDate, end: $0.endDate) }
                    }
                    .sorted { $0.start < $1.start }

                return NightTimelinePoint(
                    date: night,
                    bedtime: bedtime,
                    wakeTime: wakeTime,
                    sleepHours: sleepHours,
                    segments: segments
                )
            }
            .sorted { $0.date < $1.date }
    }

    /// Total sleep debt per chart bucket: each night's shortfall `max(0, target - hours)` summed
    /// within the bucket. Daily/weekly buckets are single nights; monthly and longer sum every
    /// night in the week/month/year, so the cumulative line reflects real accumulated debt
    /// rather than the shortfall of an average night.
    static func debtByBucket(from records: [SleepRecord], target: Double, period: TimePeriod) -> [SleepChartDataPoint] {
        let calendar = Calendar.current
        let component: Calendar.Component
        switch period {
        case .daily, .weekly: component = .day
        case .monthly: component = .weekOfYear
        case .yearly: component = .month
        case .fiveYears, .tenYears: component = .year
        }

        let nightlyDebts = nightlyTotals(from: records).map {
            (date: $0.date, debt: max(0, target - $0.hours))
        }

        return Dictionary(grouping: nightlyDebts) { night in
            calendar.dateInterval(of: component, for: night.date)?.start ?? night.date
        }
        .map { start, items in
            SleepChartDataPoint(date: start, hours: items.reduce(0) { $0 + $1.debt }, label: "")
        }
        .sorted { $0.date < $1.date }
    }

    /// Computes sleep stage breakdown for a record.
    static func stageBreakdown(for record: SleepRecord) -> [StageChartDataPoint] {
        let total = record.totalSleepDuration + record.awakeDuration
        guard total > 0 else { return [] }

        let stages: [(SleepStage, TimeInterval)] = [
            (.deepSleep, record.deepSleepDuration),
            (.remSleep, record.remSleepDuration),
            (.coreSleep, record.coreSleepDuration),
            (.awake, record.awakeDuration)
        ]

        return stages.map { stage, duration in
            StageChartDataPoint(
                stage: stage,
                minutes: duration / 60.0,
                percentage: duration / total
            )
        }
    }

    /// Computes weekly averages from a collection of records.
    static func weeklyAverages(from records: [SleepRecord]) -> [SleepChartDataPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            calendar.component(.weekOfYear, from: record.date)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        // Sort by the bucket's actual date, not the group key: keys can order non-chronologically
        // (e.g. week-of-year repeats across a year boundary).
        return grouped.map { _, weekRecords in
            let avgHours = weekRecords.map(\.totalSleepHours).reduce(0, +) / Double(weekRecords.count)
            let anyDate = weekRecords.map(\.date).min() ?? Date()
            // Anchor to the start of the week (not the first record in it) so a partial first week
            // sits a full week from the next on the date axis instead of bunching against it.
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: anyDate)?.start ?? anyDate
            return SleepChartDataPoint(
                date: weekStart,
                hours: avgHours,
                label: formatter.string(from: weekStart)
            )
        }
        .sorted { $0.date < $1.date }
    }

    /// Computes monthly averages from a collection of records.
    static func monthlyAverages(from records: [SleepRecord]) -> [SleepChartDataPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            let components = calendar.dateComponents([.year, .month], from: record.date)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        // Sort by the bucket's actual date, not the group key: the "year-month" string sorts
        // lexically (e.g. "2025-10" before "2025-7"), which scrambles the chronological order.
        return grouped.map { _, monthRecords in
            let avgHours = monthRecords.map(\.totalSleepHours).reduce(0, +) / Double(monthRecords.count)
            let anyDate = monthRecords.map(\.date).min() ?? Date()
            // Anchor to the first of the month (not the first record in it) so a partial first month
            // sits a full month from the next on the date axis instead of bunching against it.
            let monthStart = calendar.dateInterval(of: .month, for: anyDate)?.start ?? anyDate
            return SleepChartDataPoint(
                date: monthStart,
                hours: avgHours,
                label: formatter.string(from: monthStart)
            )
        }
        .sorted { $0.date < $1.date }
    }

    /// Computes yearly averages from a collection of records.
    static func yearlyAverages(from records: [SleepRecord]) -> [SleepChartDataPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            calendar.component(.year, from: record.date)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"

        return grouped.map { year, yearRecords in
            let avgHours = yearRecords.reduce(0.0) { $0 + $1.totalSleepHours } / Double(yearRecords.count)
            // Anchor to the start of the year (not the first record in it) so a partial first year
            // sits a full year from the next on the date axis instead of bunching against it.
            let yearStart = calendar.date(from: DateComponents(year: year)) ?? Date()
            return SleepChartDataPoint(
                date: yearStart,
                hours: avgHours,
                label: formatter.string(from: yearStart)
            )
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Pattern Detection

    /// Detects if there's a weekend vs weekday sleep pattern difference.
    static func weekendEffect(from records: [SleepRecord]) -> (weekdayAvg: Double, weekendAvg: Double)? {
        let calendar = Calendar.current
        let weekday = records.filter { !calendar.isDateInWeekend($0.date) }
        let weekend = records.filter { calendar.isDateInWeekend($0.date) }

        guard !weekday.isEmpty, !weekend.isEmpty else { return nil }

        let weekdayAvg = weekday.map(\.totalSleepHours).reduce(0, +) / Double(weekday.count)
        let weekendAvg = weekend.map(\.totalSleepHours).reduce(0, +) / Double(weekend.count)

        return (weekdayAvg, weekendAvg)
    }

    // MARK: - Severity

    /// Debt severity in hours (gross shortfall, e.g. `SleepMetrics.totalSleepDebt`).
    static func debtSeverity(hours: Double) -> StatSeverity {
        if hours > 5.0 { return .critical }
        if hours > 2.0 { return .concerning }
        return .normal
    }

    /// Detects the handful of sleep patterns not already visible as a chart, score, or metric
    /// card elsewhere in the app: weekend/social-jet-lag gap, frequent late bedtimes, and which
    /// specific stage (deep or REM) is running low. Requires at least 5 tracked nights, same
    /// threshold used for trend detection, so a single day's data doesn't trigger noisy flags.
    static func detectPatterns(from records: [SleepRecord]) -> [SleepPatternFlag] {
        // Stage-less "in bed only" records (0h asleep, common before Apple Watch sleep stages
        // arrived in ~2022) would otherwise skew every average/ratio below.
        let records = records.filter { $0.totalSleepHours > 0 }
        guard records.count >= 5 else { return [] }
        var flags: [SleepPatternFlag] = []

        if let effect = weekendEffect(from: records) {
            let diff = effect.weekendAvg - effect.weekdayAvg
            if diff > 1.5 {
                flags.append(SleepPatternFlag(
                    title: "Social Jet Lag",
                    message: "Sleeping \(String(format: "%.1f", diff))h more on weekends than weekdays",
                    systemImage: "arrow.triangle.2.circlepath"
                ))
            }
        }

        let calendar = Calendar.current
        let lateNights = records.filter { record in
            let hour = calendar.component(.hour, from: record.bedtime)
            return hour >= 0 && hour < 5
        }
        if lateNights.count > records.count / 3 {
            flags.append(SleepPatternFlag(
                title: "Late Bedtimes",
                message: "\(lateNights.count)/\(records.count) nights with bedtime after midnight",
                systemImage: "moon.zzz.fill"
            ))
        }

        let recordsWithStages = records.filter { !$0.stages.isEmpty }
        if !recordsWithStages.isEmpty {
            let avgDeepPercent = recordsWithStages.map { record -> Double in
                let total = record.totalSleepDuration
                guard total > 0 else { return 0 }
                return record.deepSleepDuration / total
            }.reduce(0, +) / Double(recordsWithStages.count)

            let avgREMPercent = recordsWithStages.map { record -> Double in
                let total = record.totalSleepDuration
                guard total > 0 else { return 0 }
                return record.remSleepDuration / total
            }.reduce(0, +) / Double(recordsWithStages.count)

            if avgDeepPercent < 0.10 {
                flags.append(SleepPatternFlag(
                    title: "Low Deep Sleep",
                    message: "Deep sleep is \(String(format: "%.0f%%", avgDeepPercent * 100)) of total (ideal 15–25%)",
                    systemImage: "waveform.path"
                ))
            }
            if avgREMPercent < 0.15 {
                flags.append(SleepPatternFlag(
                    title: "Low REM Sleep",
                    message: "REM sleep is \(String(format: "%.0f%%", avgREMPercent * 100)) of total (ideal 20–25%)",
                    systemImage: "eye.fill"
                ))
            }
        }

        return flags
    }
}
