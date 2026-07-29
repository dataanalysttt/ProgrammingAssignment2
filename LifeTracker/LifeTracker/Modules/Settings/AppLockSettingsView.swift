import SwiftUI

struct AppLockSettingsView: View {
    @ObservedObject private var lock = AppLockManager.shared

    var body: some View {
        List {
            Section {
                Toggle("Require Face ID / Passcode", isOn: $lock.isEnabled)
            } footer: {
                Text("When on, Life Tracker locks whenever it leaves the foreground and asks for Face ID or your device passcode to reopen.")
            }
        }
        .navigationTitle("App Lock")
    }
}
