import Foundation
import HealthKit

/// A single point of contact with HealthKit. Life Tracker never writes health
/// data — this is read-only, and every read is preceded by an explicit
/// authorization request. Data is never persisted into SwiftData; it's
/// queried live from Health each time a screen needs it, which keeps this
/// app from ever holding a stale or duplicated copy of your health record.
///
/// This is also the intended single pipe for Whoop data: enable "Apple
/// Health" sync in the Whoop app once, and anything it writes (recovery,
/// strain-adjacent heart metrics, sleep) shows up automatically through the
/// same HealthKit queries below — no separate Whoop integration needed.
@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()
    @Published private(set) var isAuthorized = false

    struct DateValue: Identifiable {
        var id: Date { date }
        var date: Date
        var value: Double
    }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        for kind in HealthMetricKind.allCases {
            if let identifier = kind.quantityTypeIdentifier, let type = HKObjectType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        types.insert(HKObjectType.workoutType())
        if let energy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) { types.insert(energy) }
        if let water = HKObjectType.quantityType(forIdentifier: .dietaryWater) { types.insert(water) }
        return types
    }

    var isHealthDataAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        guard isHealthDataAvailable else { return }
        try await store.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
    }

    // MARK: - Daily series for charts / goal progress

    /// Day-by-day values for `kind` between `start` and `end` (inclusive), one
    /// entry per calendar day. Missing days are simply absent from the array.
    /// Pass `source` (from `resolveWhoopSource()`) to restrict to samples written
    /// by that one app; `nil` includes samples from every source, same as before.
    func dailySeries(for kind: HealthMetricKind, from start: Date, to end: Date, source: HKSource? = nil) async throws -> [DateValue] {
        switch kind {
        case .sleepHours:
            return try await dailySleepHours(from: start, to: end, source: source)
        case .workoutMinutes:
            return try await dailyWorkoutMinutes(from: start, to: end, source: source)
        default:
            return try await dailyQuantitySeries(for: kind, from: start, to: end, source: source)
        }
    }

    private func dailyQuantitySeries(for kind: HealthMetricKind, from start: Date, to end: Date, source: HKSource?) async throws -> [DateValue] {
        guard let identifier = kind.quantityTypeIdentifier,
              let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else { return [] }

        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: start)
        var interval = DateComponents()
        interval.day = 1

        let predicate = datePredicate(from: start, to: end, source: source)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: kind.dailyAggregation,
                anchorDate: anchor,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                var values: [DateValue] = []
                results?.enumerateStatistics(from: start, to: end) { stats, _ in
                    let unit = Self.hkUnit(for: kind)
                    let quantity = kind.dailyAggregation == .discreteAverage ? stats.averageQuantity() : stats.sumQuantity()
                    if let quantity {
                        values.append(DateValue(date: stats.startDate, value: quantity.doubleValue(for: unit)))
                    }
                }
                continuation.resume(returning: values)
            }
            store.execute(query)
        }
    }

    private func dailySleepHours(from start: Date, to end: Date, source: HKSource?) async throws -> [DateValue] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let predicate = datePredicate(from: start, to: end, source: source)

        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
                }
            }
            store.execute(query)
        }

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        ]

        let calendar = Calendar.current
        var hoursByDay: [Date: Double] = [:]
        for sample in samples where asleepValues.contains(sample.value) {
            let day = calendar.startOfDay(for: sample.startDate)
            hoursByDay[day, default: 0] += sample.endDate.timeIntervalSince(sample.startDate) / 3600
        }
        return hoursByDay.map { DateValue(date: $0.key, value: $0.value) }.sorted { $0.date < $1.date }
    }

    private func dailyWorkoutMinutes(from start: Date, to end: Date, source: HKSource?) async throws -> [DateValue] {
        let predicate = datePredicate(from: start, to: end, source: source)
        let workouts: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (results as? [HKWorkout]) ?? [])
                }
            }
            store.execute(query)
        }

        let calendar = Calendar.current
        var minutesByDay: [Date: Double] = [:]
        for workout in workouts {
            let day = calendar.startOfDay(for: workout.startDate)
            minutesByDay[day, default: 0] += workout.duration / 60
        }
        return minutesByDay.map { DateValue(date: $0.key, value: $0.value) }.sorted { $0.date < $1.date }
    }

    // MARK: - Today convenience

    func todayTotal(for kind: HealthMetricKind, source: HKSource? = nil) async -> Double {
        let start = Calendar.current.startOfDay(for: .now)
        let series = try? await dailySeries(for: kind, from: start, to: .now, source: source)
        return series?.first?.value ?? 0
    }

    func recentWorkouts(limit: Int = 5) async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: nil, limit: limit, sortDescriptors: [sort]) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (results as? [HKWorkout]) ?? [])
                }
            }
            store.execute(query)
        }
    }

    /// Calories logged into Health today by other apps (e.g. a food-logging app),
    /// surfaced in the Food module alongside manual entries.
    func todayDietaryEnergy() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) else { return 0 }
        return await todaySum(for: type, unit: .kilocalorie())
    }

    func todayDietaryWaterLiters() async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: .dietaryWater) else { return 0 }
        return await todaySum(for: type, unit: .liter())
    }

    private func todaySum(for type: HKQuantityType, unit: HKUnit) async -> Double {
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
        return (try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }) ?? 0
    }

    private nonisolated static func hkUnit(for kind: HealthMetricKind) -> HKUnit {
        switch kind {
        case .steps: return .count()
        case .activeEnergy: return .kilocalorie()
        case .distanceWalkingRunning: return .meterUnit(with: .kilo)
        case .heartRateAverage, .restingHeartRate, .respiratoryRate: return HKUnit.count().unitDivided(by: .minute())
        case .heartRateVariability: return .secondUnit(with: .milli)
        case .workoutMinutes, .sleepHours: return .count()
        }
    }

    // MARK: - Whoop source filtering

    /// The HKSource representing the Whoop app itself (identified by its bundle id
    /// containing "whoop"), so Today's card can show numbers written specifically
    /// by Whoop rather than whatever else is writing to Health (an Apple Watch,
    /// the iPhone's own sensors, another app). Cached after the first lookup —
    /// `whoopSourceLookupDone` distinguishes "found nothing" from "not looked up yet".
    private var whoopSourceLookupDone = false
    private var cachedWhoopSource: HKSource?

    func resolveWhoopSource() async -> HKSource? {
        if whoopSourceLookupDone { return cachedWhoopSource }
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return nil }

        let sources: Set<HKSource> = (try? await withCheckedThrowingContinuation { continuation in
            let query = HKSourceQuery(sampleType: heartRateType, samplePredicate: nil) { _, sources, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: sources ?? [])
                }
            }
            store.execute(query)
        }) ?? []

        let whoop = sources.first { $0.bundleIdentifier.lowercased().contains("whoop") }
        cachedWhoopSource = whoop
        whoopSourceLookupDone = true
        return whoop
    }

    private func datePredicate(from start: Date, to end: Date, source: HKSource?) -> NSPredicate {
        let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        guard let source else { return datePredicate }
        let sourcePredicate = HKQuery.predicateForObjects(from: [source])
        return NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, sourcePredicate])
    }
}
