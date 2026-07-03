import SwiftUI
import Combine

@MainActor
final class UserSessionViewModel: ObservableObject {
    @Published var user: UserProfile? = nil
    @Published var isDeletingAccount = false
    @Published var deleteError: String? = nil

    private let api = ItzeazyAPIService.shared
    private let storage = AuthSessionStorage.shared

    init() {
        user = storage.getUser()
    }

    // MARK: - Fetch user profile (GET user)

    func fetchUserProfile() {
        // Show cached user immediately while the network call is in flight
        if user == nil {
            user = storage.getUser()
        }

        guard let token = storage.getToken() else { return }

        Task {
            do {
                let response: AuthResponse = try await api.get(endpoint: "user", token: token)
                if let userData = response.data {
                    user = userData
                    storage.saveUser(userData)
                }
            } catch let apiError as ItzeazyAPIError {
                if case .httpError(let code, _) = apiError, (500...599).contains(code) {
                    clearUser()
                    UserDefaults.standard.set(false, forKey: "isLoggedIn")
                }
                // Other API errors (401, network) — silently keep the cached user
            } catch {
                // Network errors — silently keep the cached user
            }
        }
    }

    func clearUser() {
        user = nil
        storage.clearAll()
    }

    func deleteAccount() {
        guard let token = storage.getToken() else { return }
        isDeletingAccount = true
        deleteError = nil
        Task {
            defer { isDeletingAccount = false }
            do {
                let _: AuthResponse = try await api.delete(endpoint: "user", token: token)
                clearUser()
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
            } catch {
                deleteError = (error as? ItzeazyAPIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    // MARK: - Convenience

    var displayName: String {
        user?.name.components(separatedBy: " ").first ?? ""
    }

    var displayFullName: String {
        user?.name ?? ""
    }

    var displayEmail: String {
        user?.email ?? ""
    }

    var displayPhone: String {
        user?.phone ?? ""
    }
}
