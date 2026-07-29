import Foundation

/// Every toggleable feature module gets one case here. This is the only place
/// you must touch to register a brand-new module's identity — see
/// ModuleRegistry.swift for the second (and last) place: its descriptor.
enum ModuleID: String, CaseIterable, Codable, Identifiable, Hashable {
    case goals
    case insights
    case calendar
    case health
    case food
    case investments
    case customTrackers

    var id: String { rawValue }
}
