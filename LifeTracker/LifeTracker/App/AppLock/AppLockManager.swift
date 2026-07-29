import Foundation
import LocalAuthentication
import Combine

@MainActor
final class AppLockManager: ObservableObject {
    static let shared = AppLockManager()

    private let defaults = UserDefaults.standard
    private let enabledKey = "com.dushyantsingh.lifetracker.appLockEnabled"

    @Published var isUnlocked = false
    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: enabledKey) }
    }

    init() {
        self.isEnabled = defaults.bool(forKey: enabledKey)
    }

    /// Call when the app becomes active. If lock isn't enabled, unlocks immediately.
    func lockIfNeeded() {
        isUnlocked = !isEnabled
    }

    func authenticate() async {
        guard isEnabled else {
            isUnlocked = true
            return
        }
        let context = LAContext()
        var authError: NSError?
        let policy: LAPolicy = .deviceOwnerAuthentication // Face ID / Touch ID, falls back to passcode

        guard context.canEvaluatePolicy(policy, error: &authError) else {
            // No Face ID/passcode configured on the device; don't lock the user out.
            isUnlocked = true
            return
        }

        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: "Unlock Life Tracker")
            isUnlocked = success
        } catch {
            isUnlocked = false
        }
    }
}
