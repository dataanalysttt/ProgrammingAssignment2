import Foundation
import Security

/// Thin wrapper around the iOS Keychain for the handful of secrets Life Tracker
/// ever stores: your Kite Connect API key/secret and the resulting access
/// token. Nothing else in the app touches Keychain directly. Items are stored
/// with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` so they never
/// leave this phone (no iCloud Keychain sync) and are unreadable before the
/// first unlock after a reboot.
enum KeychainService {
    private static let service = "com.dushyantsingh.lifetracker"

    static func set(_ value: String, for key: String) {
        let data = Data(value.utf8)
        var query = baseQuery(for: key)
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(query as CFDictionary, nil)
    }

    static func get(_ key: String) -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func remove(_ key: String) {
        SecItemDelete(baseQuery(for: key) as CFDictionary)
    }

    private static func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}

enum KiteCredentialKey {
    static let apiKey = "kite.apiKey"
    static let apiSecret = "kite.apiSecret"
    static let accessToken = "kite.accessToken"
}
