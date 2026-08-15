import Foundation
import HealthKit

/// The honest, user-facing state of Somnus's connection to Apple Health sleep data.
/// HealthKit never reveals whether *read* access was granted, so we infer it: the only proof
/// that reading works is actually reading a sample. `.connected` therefore means "we've read
/// real sleep data", not merely "the permission sheet was shown" — which stayed true even after
/// the user denied access.
enum SleepDataAccess: Equatable {
    case checking       // initial, before the first probe completes
    case notRequested   // the permission sheet has never been presented
    case noData         // sheet was presented, but no sleep samples are readable (denied, or none recorded)
    case connected      // at least one sleep sample is readable — access definitely works
}

/// Manages all HealthKit interactions for reading Apple Watch sleep data.
@MainActor
final class HealthKitManager: ObservableObject {

    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

    /// Published so any screen can observe the connection state without re-deriving it locally.
    /// Refreshed via `refreshSleepDataAccess()` after a load or when a screen appears.
    @Published private(set) var sleepDataAccess: SleepDataAccess = .checking

    // MARK: - Authorization

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw HealthKitError.notAvailable
        }

        let typesToRead: Set<HKObjectType> = [sleepType]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    /// Whether the user has already been walked through the HealthKit permission flow.
    /// HealthKit never reveals whether *read* access was granted — only whether the request
    /// still needs to be presented — so on its own this can't tell grant from deny.
    func hasCompletedAuthorizationRequest() async -> Bool {
        guard isHealthDataAvailable else { return false }
        let status = try? await healthStore.statusForAuthorizationRequest(toShare: [], read: [sleepType])
        return status == .unnecessary
    }

    /// Recomputes `sleepDataAccess` from the honest signals: whether the sheet has been presented,
    /// and — crucially — whether we can actually read a sleep sample. A user who denied read access
    /// reports `.unnecessary` just like one who granted it, so we only claim `.connected` once a
    /// real sample comes back; otherwise `.noData` (denied, or nothing recorded yet).
    func refreshSleepDataAccess() async {
        guard await hasCompletedAuthorizationRequest() else {
            sleepDataAccess = .notRequested
            return
        }
        sleepDataAccess = await hasReadableSleepData() ? .connected : .noData
    }

    /// Lightweight probe: can we read *any* sleep sample from the last year? A returned sample is
    /// definitive proof of read access (HealthKit offers no direct API for that). `limit: 1`, so
    /// it's cheap; a query error or empty result is treated as "no readable data".
    private func hasReadableSleepData() async -> Bool {
        let end = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -365, to: end) else { return false }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, results, _ in
                continuation.resume(returning: results?.isEmpty == false)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Sleep Data

    /// Fetches sleep records for a given date range.
    func fetchSleepRecords(from startDate: Date, to endDate: Date) async throws -> [SleepRecord] {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: results as? [HKCategorySample] ?? [])
                }
            }
            healthStore.execute(query)
        }

        return groupSamplesIntoRecords(samples)
    }

    /// Fetches sleep records for a specific time period.
    func fetchSleepRecords(for period: TimePeriod) async throws -> [SleepRecord] {
        let range = period.dateRange
        return try await fetchSleepRecords(from: range.start, to: range.end)
    }

    /// Fetches the most recent *tracked* night's sleep as a single record. Fragmented
    /// sessions are merged (first bedtime to last wake, all stages) and stage-less
    /// "in bed only" records are skipped, so the Dashboard's "last night" matches how
    /// every other stat counts nights — no "0.0 hours" header over a healthy score.
    func fetchLatestSleepRecord() async throws -> SleepRecord? {
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .day, value: -2, to: end)!
        let records = try await fetchSleepRecords(from: start, to: end)
        return SleepAnalysisEngine.mergedNightlyRecords(from: records).last
    }

    // MARK: - Sample Grouping

    /// Groups individual HealthKit sleep samples into coherent sleep records (nights).
    /// Apple Watch records individual stage samples; we need to aggregate them into sessions.
    private func groupSamplesIntoRecords(_ samples: [HKCategorySample]) -> [SleepRecord] {
        guard !samples.isEmpty else { return [] }

        // Group samples by sleep session using time gaps
        var sessions: [[HKCategorySample]] = []
        var currentSession: [HKCategorySample] = [samples[0]]

        for i in 1..<samples.count {
            let gap = samples[i].startDate.timeIntervalSince(samples[i-1].endDate)
            // If gap > 2 hours, it's a new sleep session
            if gap > 7200 {
                sessions.append(currentSession)
                currentSession = [samples[i]]
            } else {
                currentSession.append(samples[i])
            }
        }
        sessions.append(currentSession)

        // Convert sessions to SleepRecords
        return sessions.compactMap { session -> SleepRecord? in
            guard let first = session.first, let last = session.last else { return nil }

            let stages = session.map { sample -> SleepStageSample in
                let hkValue = HKCategoryValueSleepAnalysis(rawValue: sample.value) ?? .inBed
                return SleepStageSample(
                    stage: SleepStage(from: hkValue),
                    startDate: sample.startDate,
                    endDate: sample.endDate
                )
            }

            // Use the start of day for the wake date as the record's date
            let calendar = Calendar.current
            let recordDate: Date
            if calendar.component(.hour, from: first.startDate) >= 18 {
                // Sleep started in the evening, date is next day
                recordDate = calendar.startOfDay(for: last.endDate)
            } else {
                recordDate = calendar.startOfDay(for: first.startDate)
            }

            return SleepRecord(
                date: recordDate,
                bedtime: first.startDate,
                wakeTime: last.endDate,
                stages: stages
            )
        }
    }

    // MARK: - Observe Changes

    /// Observes new sleep samples while the app is running, so a watch sync mid-session refreshes
    /// the screens without a manual pull. Somnus doesn't enable HealthKit background delivery —
    /// there's no work to do while backgrounded, and the next launch re-reads Health anyway.
    func startObservingSleepChanges(handler: @escaping () -> Void) {
        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { _, completionHandler, error in
            if error == nil {
                handler()
            }
            completionHandler()
        }
        healthStore.execute(query)
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .notAuthorized:
            return "Sleep data access has not been authorized."
        case .queryFailed(let message):
            return "Failed to query sleep data: \(message)"
        }
    }
}
