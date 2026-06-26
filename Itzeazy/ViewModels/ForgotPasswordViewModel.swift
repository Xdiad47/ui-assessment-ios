import SwiftUI
import Combine

@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    // Contact input state (bound directly from ForgotPasswordView)
    @Published var emailOrMobile: String = ""
    @Published var selectedCountry: CountryInfo = countries.first(where: { $0.isoCode == "IN" }) ?? countries[0]
    @Published var emailOrMobileError: String? = nil

    // API state
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var otpSent = false
    @Published var otpVerified = false
    @Published var passwordUpdated = false

    // Temp token from Step 2 verify — required for Step 3 update-password
    private var verifyToken: String? = nil

    private let api = ItzeazyAPIService.shared
    private let storage = AuthSessionStorage.shared

    // MARK: - Contact input helpers

    var shouldShowCountrySelector: Bool {
        !emailOrMobile.contains("@") && emailOrMobile.rangeOfCharacter(from: .letters) == nil
    }

    var formattedContactInfo: String {
        shouldShowCountrySelector
            ? "\(selectedCountry.phoneCode) \(emailOrMobile)"
            : emailOrMobile
    }

    func handleContactInputChange(_ newValue: String) {
        if newValue.rangeOfCharacter(from: .letters) == nil && !newValue.contains("@") {
            let digitsOnly = newValue.filter(\.isNumber)
            if digitsOnly != newValue {
                emailOrMobile = String(digitsOnly.prefix(15))
                return
            }
            if digitsOnly.count > 15 {
                emailOrMobile = String(digitsOnly.prefix(15))
                return
            }
        }
        emailOrMobileError = nil
    }

    func validateContactInput() -> Bool {
        let value = emailOrMobile.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            withAnimation(.easeInOut(duration: 0.2)) {
                emailOrMobileError = "Please enter your Email or Mobile number."
            }
            return false
        }
        if shouldShowCountrySelector {
            let isValid = (6...15).contains(value.count)
            withAnimation(.easeInOut(duration: 0.2)) {
                emailOrMobileError = isValid ? nil : "Please enter a valid Mobile number."
            }
            return isValid
        } else {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let isValid = NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: value)
            withAnimation(.easeInOut(duration: 0.2)) {
                emailOrMobileError = isValid ? nil : "Please enter a valid Email address."
            }
            return isValid
        }
    }

    // MARK: - Step 1: Send OTP (type: forgot_password)

    func sendOTP() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        otpSent = false

        let contact = emailOrMobile.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            defer { isLoading = false }
            do {
                if shouldShowCountrySelector {
                    let _: SendOTPResponse = try await api.post(
                        endpoint: "user/mobile/send-otp",
                        body: ForgotPasswordMobileOTPRequest(mobile: contact)
                    )
                } else {
                    let _: SendOTPResponse = try await api.post(
                        endpoint: "user/email/send-otp",
                        body: ForgotPasswordEmailOTPRequest(email: contact)
                    )
                }
                otpSent = true
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Failed to send OTP. Please try again."
            }
        }
    }

    // MARK: - Step 2: Verify OTP — saves temp token for Step 3

    func verifyOTP(otp: String) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        let contact = emailOrMobile.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            defer { isLoading = false }
            do {
                let response: AuthResponse
                if shouldShowCountrySelector {
                    response = try await api.post(
                        endpoint: "user/mobile/verify-otp",
                        body: ForgotPasswordVerifyMobileRequest(mobile: contact, otp: otp)
                    )
                } else {
                    response = try await api.post(
                        endpoint: "user/email/verify-otp",
                        body: ForgotPasswordVerifyEmailRequest(email: contact, otp: otp)
                    )
                }
                verifyToken = response.token
                otpVerified = true
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "OTP verification failed. Please try again."
            }
        }
    }

    // MARK: - Step 3: Update Password (PATCH, uses temp token from Step 2)

    func updatePassword(newPassword: String, confirmPassword: String) {
        guard !isLoading else { return }
        guard let token = verifyToken else {
            errorMessage = "Session expired. Please start over."
            return
        }
        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                let _: AuthResponse = try await api.patch(
                    endpoint: "user/update-password",
                    body: UpdatePasswordRequest(new_password: newPassword, confirm_password: confirmPassword),
                    token: token
                )
                passwordUpdated = true
                NotificationCenter.default.post(name: .passwordUpdated, object: nil)
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Failed to update password. Please try again."
            }
        }
    }

    // MARK: - Helpers

    func resetOTPState() {
        otpSent = false
        errorMessage = nil
    }
}

extension Notification.Name {
    static let passwordUpdated = Notification.Name("com.itzeazy.passwordUpdated")
}
