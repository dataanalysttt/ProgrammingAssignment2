import Foundation
import Combine

/// Which modules are enabled, persisted to UserDefaults (this is app
/// configuration, not personal data, so it deliberately lives outside
/// SwiftData/the export file). Read via `.shared` from anywhere; views that
/// need to react to changes should hold it as an `@ObservedObject` /
/// `@EnvironmentObject`.
final class ModuleSettingsStore: ObservableObject {
    static let shared = ModuleSettingsStore()

    private let defaults: UserDefaults
    private let key = "com.dushyantsingh.lifetracker.enabledModules"

    @Published private var enabledModules: Set<ModuleID>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let stored = defaults.array(forKey: key) as? [String] {
            self.enabledModules = Set(stored.compactMap(ModuleID.init(rawValue:)))
        } else {
            self.enabledModules = Set(ModuleRegistry.all.filter(\.defaultEnabled).map(\.id))
        }
    }

    func isEnabled(_ id: ModuleID) -> Bool {
        enabledModules.contains(id)
    }

    func setEnabled(_ enabled: Bool, for id: ModuleID) {
        if enabled {
            enabledModules.insert(id)
        } else {
            enabledModules.remove(id)
        }
        persist()
    }

    private func persist() {
        defaults.set(enabledModules.map(\.rawValue), forKey: key)
    }
}
