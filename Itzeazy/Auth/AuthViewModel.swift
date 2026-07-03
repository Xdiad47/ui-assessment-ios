import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    // Becomes true when send-OTP succeeds; PasswordEntryView uses this to navigate
    @Published var otpSent = false

    private let api = ItzeazyAPIService.shared
    private let storage = AuthSessionStorage.shared

    // MARK: - Traditional Login

    func loginWithPassword(username: String, password: String) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                let response: AuthResponse = try await api.post(
                    endpoint: "user/login",
                    body: LoginRequest(username: username, password: password)
                )
                persistSession(from: response)
                isLoggedIn = true
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Something went wrong. Please try again."
            }
        }
    }

    // MARK: - OTP Login Step 1: Send OTP

    func sendOTP(mobile: String) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        otpSent = false

        Task {
            defer { isLoading = false }
            do {
                let _: SendOTPResponse = try await api.post(
                    endpoint: "user/mobile/send-otp",
                    body: SendOTPRequest(mobile: mobile)
                )
                otpSent = true
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Failed to send OTP. Please try again."
            }
        }
    }

    // MARK: - OTP Login Step 2: Verify OTP

    func verifyOTP(mobile: String, otp: String) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                let response: AuthResponse = try await api.post(
                    endpoint: "user/mobile/verify-otp",
                    body: VerifyOTPRequest(mobile: mobile, otp: otp, type: "login")
                )
                persistSession(from: response)
                isLoggedIn = true
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "OTP verification failed. Please try again."
            }
        }
    }

    // MARK: - Helpers

    func resetOTPState() {
        otpSent = false
        errorMessage = nil
    }

    private func persistSession(from response: AuthResponse) {
        if let token = response.token {
            storage.saveToken(token)
        }
        if let user = response.data {
            storage.saveUser(user)
        }
    }
}
