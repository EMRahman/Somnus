import Foundation

#if DEBUG
/// Deterministic, synthetic sleep records used only for simulator marketing screenshots.
/// The flag and fixture are compiled out of App Store builds, so production behavior always
/// continues through HealthKit.
enum ScreenshotSupport {
    enum Destination: String {
        case dashboard
        case sleepDebt = "debt"
        case sleepDuration = "duration"
        case monthlyDuration = "monthly-duration"
    }

    private static let modeArgument = "-screenshotMode"
    private static let destinationPrefix = "-screenshotDestination="

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(modeArgument)
    }

    static var destination: Destination {
        guard isEnabled,
              let argument = ProcessInfo.processInfo.arguments.first(where: {
                  $0.hasPrefix(destinationPrefix)
              }),
              let destination = Destination(rawValue: String(argument.dropFirst(destinationPrefix.count)))
        else {
            return .dashboard
        }
        return destination
    }

    static func records(for period: TimePeriod) -> [SleepRecord] {
        let count: Int
        let dayStride: Int

        switch period {
        case .daily:
            count = 1
            dayStride = 1
        case .weekly:
            count = 7
            dayStride = 1
        case .monthly:
            count = 28
            dayStride = 1
        case .yearly:
            count = 52
            dayStride = 7
        case .fiveYears:
            count = 60
            dayStride = 30
        case .tenYears:
            count = 120
            dayStride = 30
        }

        let hours = [7.2, 7.8, 6.5, 8.1, 7.4, 6.9, 7.6]
        let bedtimes = [(23, 5), (22, 55), (23, 20), (22, 50), (23, 10), (23, 25), (22, 58)]
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())

        return (0..<count).map { index in
            let daysAgo = (count - index - 1) * dayStride
            let wakeDay = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            let bedtimeDay = calendar.date(byAdding: .day, value: -1, to: wakeDay) ?? wakeDay
            let bedtimeParts = bedtimes[index % bedtimes.count]
            let bedtime = calendar.date(
                bySettingHour: bedtimeParts.0,
                minute: bedtimeParts.1,
                second: 0,
                of: bedtimeDay
            ) ?? bedtimeDay
            let stages = makeStages(bedtime: bedtime, sleepHours: hours[index % hours.count])

            return SleepRecord(
                date: wakeDay,
                bedtime: bedtime,
                wakeTime: stages.last?.endDate ?? bedtime,
                stages: stages
            )
        }
    }

    private static func makeStages(bedtime: Date, sleepHours: Double) -> [SleepStageSample] {
        let cycleCount = 4
        let awakeSeconds = 4.0 * 60.0
        let sleepPerCycle = sleepHours * 3600.0 / Double(cycleCount)
        var cursor = bedtime
        var samples: [SleepStageSample] = []

        for cycle in 0..<cycleCount {
            // Deep sleep is weighted toward the start of the night; REM toward the morning.
            let deepRatio = 0.27 - Double(cycle) * 0.045
            let remRatio = 0.18 + Double(cycle) * 0.045
            let coreRatio = 1.0 - deepRatio - remRatio

            appendStage(.coreSleep, duration: sleepPerCycle * coreRatio, cursor: &cursor, to: &samples)
            appendStage(.deepSleep, duration: sleepPerCycle * deepRatio, cursor: &cursor, to: &samples)
            appendStage(.remSleep, duration: sleepPerCycle * remRatio, cursor: &cursor, to: &samples)

            if cycle < cycleCount - 1 {
                appendStage(.awake, duration: awakeSeconds, cursor: &cursor, to: &samples)
            }
        }

        return samples
    }

    private static func appendStage(
        _ stage: SleepStage,
        duration: TimeInterval,
        cursor: inout Date,
        to samples: inout [SleepStageSample]
    ) {
        let end = cursor.addingTimeInterval(duration)
        samples.append(SleepStageSample(stage: stage, startDate: cursor, endDate: end))
        cursor = end
    }
}
#endif
