import Foundation

/// Static metadata about a module, used to render the Settings toggle list and
/// to decide what shows up on Today/Insights. This is intentionally *not* a
/// protocol with associated views — for a single-person SwiftUI app, a plain
/// registry of descriptors plus normal `if ModuleSettingsStore.shared.isEnabled(.x)`
/// checks in each view is far easier to read and modify than a dynamic
/// plugin-loading system would be, while still giving every module one
/// well-defined place to declare itself.
struct ModuleDescriptor: Identifiable {
    var id: ModuleID
    var name: String
    var summary: String
    var systemImage: String
    /// Enabled by default on first launch.
    var defaultEnabled: Bool
}
