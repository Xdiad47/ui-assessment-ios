import Foundation
import Security

final class AuthSessionStorage {
    static let shared = AuthSessionStorage()

    private let tokenKeychainAccount = "com.itzeazy.auth.token"
    private let userDefaultsKey = "com.itzeazy.auth.user"

    private init() {}

    // MARK: - Token (Keychain)

    func saveToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKeychainAccount,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func getToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKeychainAccount,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func clearToken() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKeychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - User Profile (UserDefaults)

    func saveUser(_ user: UserProfile) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    func getUser() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    func clearUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    // MARK: - Clear All (Logout)

    func clearAll() {
        clearToken()
        clearUser()
    }
}
