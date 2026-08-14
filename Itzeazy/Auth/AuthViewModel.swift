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

    // MARK: - Apple Sign-In
    // Apple's response never tells the app whether this person already has
    // an account — so this tries the login endpoint first, and only if THAT
    // fails with an HTTP error (no account for this token yet) does it fall
    // back to create-account, reusing the same identityToken. Both endpoints
    // take the identical body (see AppleAuthRequest) — confirmed by backend,
    // no name/email needed for either. As of 2026-08-10, backend confirmed
    // create-account works; login (user/login) is still work in progress on
    // their end, so it may keep 400-ing and always falling through to
    // create-account until they finish it — that's expected for now, not a
    // client bug.
    func loginWithApple(identityToken: String) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                let response: AuthResponse = try await api.post(
                    endpoint: "user/login",
                    body: AppleAuthRequest(token: identityToken)
                )
                persistSession(from: response)
                isLoggedIn = true
            } catch let error as ItzeazyAPIError {
                if case .httpError = error {
                    await createAccountWithApple(identityToken: identityToken)
                } else {
                    errorMessage = error.errorDescription
                }
            } catch {
                errorMessage = "Something went wrong. Please try again."
            }
        }
    }

    private func createAccountWithApple(identityToken: String) async {
        do {
            let response: AuthResponse = try await api.post(
                endpoint: "user",
                body: AppleAuthRequest(token: identityToken)
            )
            persistSession(from: response)
            isLoggedIn = true
        } catch let error as ItzeazyAPIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
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
