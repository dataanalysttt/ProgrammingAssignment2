import SwiftUI
import SwiftData

@main
struct LifeTrackerApp: App {
    let modelContainer = ModelContainerFactory.makeContainer()
    @StateObject private var moduleSettings = ModuleSettingsStore.shared

    var body: some Scene {
        WindowGroup {
            AppLockGate {
                RootTabView()
                    .environmentObject(moduleSettings)
                    .tint(Theme.ColorToken.accent)
            }
        }
        .modelContainer(modelContainer)
    }
}
