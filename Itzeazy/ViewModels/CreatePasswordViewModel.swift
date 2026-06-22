import Foundation
import Combine

final class CreatePasswordViewModel: ObservableObject {
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var newPasswordError: String?
    @Published var confirmPasswordError: String?

    func clearErrors() {
        newPasswordError = nil
        confirmPasswordError = nil
    }

    @discardableResult
    func validatePasswords() -> Bool {
        let trimmedNewPassword = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirmPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        clearErrors()

        guard !trimmedNewPassword.isEmpty else {
            newPasswordError = "Please enter a new password."
            return false
        }

        guard trimmedNewPassword.count >= 8 else {
            newPasswordError = "Password must be at least 8 characters."
            return false
        }

        guard !trimmedConfirmPassword.isEmpty else {
            confirmPasswordError = "Please confirm your password."
            return false
        }

        guard trimmedNewPassword == trimmedConfirmPassword else {
            confirmPasswordError = "Passwords do not match."
            return false
        }

        return true
    }
}
