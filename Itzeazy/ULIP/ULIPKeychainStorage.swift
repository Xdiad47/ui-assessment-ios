import Foundation
import Security

// Token stored in Keychain (encrypted, persists across launches and app kills).
// Save timestamp stored in UserDefaults (non-sensitive, also persists across launches).
// Together they enforce a 24-hour TTL without hitting the login API on every launch.
final class ULIPKeychainStorage {
    static let shared = ULIPKeychainStorage()
    private init() {}

    private let tokenKey        = "com.itzeazy.ulip.authToken"
    private let timestampKey    = "com.itzeazy.ulip.tokenSavedAt"
    private let tokenTTL: TimeInterval = 24 * 60 * 60  // 24 hours

    // MARK: - Token (Keychain)

    func saveToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: tokenKey,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        saveTimestamp()
    }

    func getToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: tokenKey,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func clearToken() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
        clearTimestamp()
    }

    // MARK: - Timestamp (UserDefaults — survives app close/relaunch)

    private func saveTimestamp() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: timestampKey)
    }

    private func clearTimestamp() {
        UserDefaults.standard.removeObject(forKey: timestampKey)
    }

    // MARK: - Validity checks

    var hasToken: Bool { getToken() != nil }

    // True if the token was saved more than 24 hours ago
    var isTokenExpired: Bool {
        guard let savedAt = UserDefaults.standard.object(forKey: timestampKey) as? TimeInterval else {
            return true  // No timestamp means we treat it as expired
        }
        return Date().timeIntervalSince1970 - savedAt >= tokenTTL
    }

    // Token is present AND was saved within the last 24 hours
    var isTokenValid: Bool { hasToken && !isTokenExpired }
}
