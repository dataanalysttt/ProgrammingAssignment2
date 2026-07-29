import SwiftUI

/// Wraps the whole app. When App Lock is on in Settings, shows a calm cover
/// screen and blocks content until Face ID / passcode succeeds. When App
/// Lock is off, this is an invisible pass-through.
struct AppLockGate<Content: View>: View {
    @ObservedObject private var lock = AppLockManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            content()
                .opacity(lock.isUnlocked ? 1 : 0)

            if !lock.isUnlocked {
                lockScreen
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                lock.lockIfNeeded()
                if !lock.isUnlocked {
                    Task { await lock.authenticate() }
                }
            } else if newPhase == .background, lock.isEnabled {
                lock.isUnlocked = false
            }
        }
        .task {
            lock.lockIfNeeded()
            if !lock.isUnlocked {
                await lock.authenticate()
            }
        }
    }

    private var lockScreen: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.ColorToken.secondaryText)
            Text("Life Tracker is Locked")
                .font(Theme.Typography.title)
            Button("Unlock") {
                Task { await lock.authenticate() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.ColorToken.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.ColorToken.background)
    }
}
