import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink { ModuleTogglesView() } label: {
                    Label("Modules", systemImage: "square.stack.3d.up")
                }
                NavigationLink { IntegrationsSettingsView() } label: {
                    Label("Integrations & Credentials", systemImage: "link")
                }
                NavigationLink { AppLockSettingsView() } label: {
                    Label("App Lock", systemImage: "lock")
                }
                NavigationLink { ExportImportView() } label: {
                    Label("Export & Import Data", systemImage: "arrow.up.arrow.down.square")
                }
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(Theme.ColorToken.secondaryText)
                }
            } footer: {
                Text("Life Tracker stores everything on this device only. There is no account, no server, and no analytics.")
            }
        }
        .navigationTitle("Settings")
    }
}
