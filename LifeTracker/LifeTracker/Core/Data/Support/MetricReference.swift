import Foundation

/// What a Goal's progress bar is driven by. SwiftData stores Codable enums like this
/// transparently, so a Goal can point at a custom tracker, a HealthKit metric, the
/// investments module's portfolio value, or nothing (manual progress / simple checkoff).
enum MetricReference: Codable, Equatable {
    case none
    case tracker(UUID)
    case health(HealthMetricKind)
    case investmentValue

    var displayName: String {
        switch self {
        case .none: return "None (manual progress)"
        case .tracker: return "Custom tracker"
        case .health(let kind): return kind.displayName
        case .investmentValue: return "Portfolio value"
        }
    }
}
