import Foundation

/// The shape of value a custom tracker collects. Add a case here (and a matching
/// input control in CustomTrackers/CustomTrackerEditView.swift + Today/TrackerQuickEntryRow.swift)
/// to introduce a brand-new kind of trackable metric app-wide.
enum TrackerValueType: String, Codable, CaseIterable, Identifiable, Hashable {
    case number
    case yesNo
    case scale
    case duration
    case text

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .number: return "Number"
        case .yesNo: return "Yes / No"
        case .scale: return "Scale (1-10)"
        case .duration: return "Duration"
        case .text: return "Text Note"
        }
    }

    var systemImage: String {
        switch self {
        case .number: return "number"
        case .yesNo: return "checkmark.circle"
        case .scale: return "slider.horizontal.3"
        case .duration: return "clock"
        case .text: return "text.alignleft"
        }
    }
}

enum TrackerCadence: String, Codable, CaseIterable, Identifiable, Hashable {
    case daily
    case weekly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}

enum GoalStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case active
    case completed
    case archived

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }
}

enum GoalCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case health
    case finance
    case career
    case learning
    case personal
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .health: return "Health"
        case .finance: return "Finance"
        case .career: return "Career"
        case .learning: return "Learning"
        case .personal: return "Personal"
        case .other: return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .health: return "heart.fill"
        case .finance: return "chart.line.uptrend.xyaxis"
        case .career: return "briefcase.fill"
        case .learning: return "book.fill"
        case .personal: return "person.fill"
        case .other: return "sparkles"
        }
    }
}

/// How a goal's linked metric samples are combined between the goal's
/// creation date (or start of period) and today to produce a progress value.
enum GoalAggregation: String, Codable, CaseIterable, Identifiable, Hashable {
    case sum
    case average
    case latest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sum: return "Total"
        case .average: return "Average"
        case .latest: return "Most Recent"
        }
    }
}
