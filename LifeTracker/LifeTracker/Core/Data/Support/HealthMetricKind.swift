import Foundation
import HealthKit

/// The set of HealthKit-backed metrics Life Tracker knows how to read and surface
/// as trackable data for goals, Today, and Insights. This is the single place that
/// maps "a metric I care about" to the underlying HKQuantityType/HKCategoryType,
/// so adding a new HealthKit metric only touches this file plus HealthKitManager.
enum HealthMetricKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case steps
    case activeEnergy
    case distanceWalkingRunning
    case workoutMinutes
    case sleepHours
    case heartRateAverage
    case restingHeartRate
    case heartRateVariability
    case respiratoryRate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .activeEnergy: return "Active Energy"
        case .distanceWalkingRunning: return "Walking + Running Distance"
        case .workoutMinutes: return "Workout Minutes"
        case .sleepHours: return "Sleep"
        case .heartRateAverage: return "Heart Rate (avg)"
        case .restingHeartRate: return "Resting Heart Rate"
        case .heartRateVariability: return "Heart Rate Variability"
        case .respiratoryRate: return "Respiratory Rate"
        }
    }

    var unit: String {
        switch self {
        case .steps: return "steps"
        case .activeEnergy: return "kcal"
        case .distanceWalkingRunning: return "km"
        case .workoutMinutes: return "min"
        case .sleepHours: return "hr"
        case .heartRateAverage, .restingHeartRate: return "bpm"
        case .heartRateVariability: return "ms"
        case .respiratoryRate: return "br/min"
        }
    }

    var systemImage: String {
        switch self {
        case .steps: return "figure.walk"
        case .activeEnergy: return "flame.fill"
        case .distanceWalkingRunning: return "map.fill"
        case .workoutMinutes: return "figure.run"
        case .sleepHours: return "bed.double.fill"
        case .heartRateAverage, .restingHeartRate: return "heart.fill"
        case .heartRateVariability: return "waveform.path.ecg"
        case .respiratoryRate: return "lungs.fill"
        }
    }

    /// The underlying HealthKit quantity type, for metrics backed by HKQuantitySample.
    /// Sleep and workout minutes are handled specially in HealthKitManager since they
    /// come from HKCategorySample / HKWorkout rather than a simple quantity sum.
    var quantityTypeIdentifier: HKQuantityTypeIdentifier? {
        switch self {
        case .steps: return .stepCount
        case .activeEnergy: return .activeEnergyBurned
        case .distanceWalkingRunning: return .distanceWalkingRunning
        case .heartRateAverage: return .heartRate
        case .restingHeartRate: return .restingHeartRate
        case .heartRateVariability: return .heartRateVariabilitySDNN
        case .respiratoryRate: return .respiratoryRate
        case .workoutMinutes, .sleepHours: return nil
        }
    }

    /// How daily samples should be combined into a single day value.
    var dailyAggregation: HKStatisticsOptions {
        switch self {
        case .steps, .activeEnergy, .distanceWalkingRunning:
            return .cumulativeSum
        case .heartRateAverage, .restingHeartRate, .heartRateVariability, .respiratoryRate:
            return .discreteAverage
        case .workoutMinutes, .sleepHours:
            return []
        }
    }
}
