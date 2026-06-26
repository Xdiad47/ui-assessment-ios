import SwiftUI
import Combine

@MainActor
final class RegisterViewModel: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var otpSent = false

    // Form data stored here so create-user can access them after OTP verify
    var name: String = ""
    var email: String = ""
    var mobile: String = ""
    var password: String = ""

    private let api = ItzeazyAPIService.shared
    private let storage = AuthSessionStorage.shared

    // MARK: - Step 1: Send OTP

    func sendMobileOTP() {
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

    func sendEmailOTP() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        otpSent = false

        Task {
            defer { isLoading = false }
            do {
                let _: SendOTPResponse = try await api.post(
                    endpoint: "user/email/send-otp",
                    body: SendEmailOTPRequest(email: email, name: name)
                )
                otpSent = true
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Failed to send OTP. Please try again."
            }
        }
    }

    // MARK: - Step 2 + 3: Verify OTP then Create User

    func verifyMobileOTP(otp: String) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                let _: SendOTPResponse = try await api.post(
                    endpoint: "user/mobile/verify-otp",
                    body: VerifyMobileOTPRequest(mobile: mobile, otp: otp)
                )
                await createUser()
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "OTP verification failed. Please try again."
            }
        }
    }

    func verifyEmailOTP(otp: String) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                let _: SendOTPResponse = try await api.post(
                    endpoint: "user/email/verify-otp",
                    body: VerifyEmailOTPRequest(email: email, otp: otp)
                )
                await createUser()
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "OTP verification failed. Please try again."
            }
        }
    }

    // MARK: - Step 3: Create User (called automatically after verify)

    private func createUser() async {
        do {
            let response: AuthResponse = try await api.post(
                endpoint: "user",
                body: CreateUserRequest(name: name, email: email, phone: mobile, pass: password)
            )
            if let token = response.token {
                storage.saveToken(token)
            }
            if let user = response.data {
                storage.saveUser(user)
            }
            isLoggedIn = true
        } catch let error as ItzeazyAPIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Account creation failed. Please try again."
        }
    }

    // MARK: - Helpers

    func resetOTPState() {
        otpSent = false
        errorMessage = nil
    }
}
