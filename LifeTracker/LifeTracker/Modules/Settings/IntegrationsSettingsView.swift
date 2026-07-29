import SwiftUI

struct IntegrationsSettingsView: View {
    @ObservedObject private var health = HealthKitManager.shared
    @ObservedObject private var calendarManager = CalendarManager.shared
    @EnvironmentObject private var moduleSettings: ModuleSettingsStore

    @State private var apiKey: String = KeychainService.get(KiteCredentialKey.apiKey) ?? ""
    @State private var apiSecret: String = KeychainService.get(KiteCredentialKey.apiSecret) ?? ""
    @State private var isConnected = KeychainService.get(KiteCredentialKey.accessToken) != nil
    @State private var connectionError: String?
    @State private var isConnecting = false

    var body: some View {
        List {
            Section("Health") {
                statusRow(title: "Apple Health", isGranted: health.isAuthorized)
                Button("Allow Health Access") {
                    Task { try? await health.requestAuthorization() }
                }
            }

            Section("Calendar") {
                statusRow(title: "iOS Calendar", isGranted: calendarManager.isAuthorized)
                Button("Allow Calendar Access") {
                    Task { try? await calendarManager.requestAccess() }
                }
            }

            if moduleSettings.isEnabled(.investments) {
                Section {
                    Text("Kite Connect (Zerodha)")
                } footer: {
                    Text("Create a Personal app at developer.kite.trade, set its redirect URL to lifetracker://kite-callback, then paste the API key and secret here. They're stored only in this phone's Keychain — never in source control or iCloud.")
                }

                Section("Credentials") {
                    TextField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("API Secret", text: $apiSecret)
                    Button("Save Credentials") {
                        KeychainService.set(apiKey, for: KiteCredentialKey.apiKey)
                        KeychainService.set(apiSecret, for: KiteCredentialKey.apiSecret)
                    }
                    .disabled(apiKey.isEmpty || apiSecret.isEmpty)
                }

                Section("Connection") {
                    statusRow(title: "Zerodha Account", isGranted: isConnected)
                    if isConnected {
                        Button("Disconnect", role: .destructive) {
                            KeychainService.remove(KiteCredentialKey.accessToken)
                            isConnected = false
                        }
                    } else {
                        Button(isConnecting ? "Connecting…" : "Connect to Zerodha") {
                            connect()
                        }
                        .disabled(apiKey.isEmpty || apiSecret.isEmpty || isConnecting)
                    }
                    if let connectionError {
                        Text(connectionError).foregroundStyle(Theme.ColorToken.negative).font(Theme.Typography.caption)
                    }
                }
            }
        }
        .navigationTitle("Integrations")
    }

    private func statusRow(title: String, isGranted: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            Label(isGranted ? "Connected" : "Not Connected", systemImage: isGranted ? "checkmark.circle.fill" : "circle")
                .labelStyle(.titleAndIcon)
                .foregroundStyle(isGranted ? Theme.ColorToken.positive : Theme.ColorToken.secondaryText)
                .font(Theme.Typography.caption)
        }
    }

    private func connect() {
        isConnecting = true
        connectionError = nil
        Task {
            do {
                KeychainService.set(apiKey, for: KiteCredentialKey.apiKey)
                KeychainService.set(apiSecret, for: KiteCredentialKey.apiSecret)
                _ = try await KiteAuthService.shared.login(apiKey: apiKey, apiSecret: apiSecret)
                isConnected = true
            } catch {
                connectionError = error.localizedDescription
            }
            isConnecting = false
        }
    }
}
