import Foundation
import Combine

final class ForgotPasswordViewModel: ObservableObject {
    @Published var emailOrMobile: String = ""
    @Published var selectedCountry: CountryInfo = countries.first(where: { $0.isoCode == "IN" }) ?? countries[0]
    @Published var emailOrMobileError: String?

    var trimmedInput: String {
        emailOrMobile.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmailInput: Bool {
        let value = trimmedInput
        return value.contains("@") || value.rangeOfCharacter(from: .letters) != nil
    }

    var shouldShowCountrySelector: Bool {
        !isEmailInput
    }

    var formattedContactInfo: String {
        shouldShowCountrySelector ? "\(selectedCountry.phoneCode) \(trimmedInput)" : trimmedInput
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
        let value = trimmedInput

        guard !value.isEmpty else {
            emailOrMobileError = "Please enter your Email or Mobile number."
            return false
        }

        if shouldShowCountrySelector {
            let isPhoneValid = (6...15).contains(value.count)
            emailOrMobileError = isPhoneValid ? nil : "Please enter a valid Mobile number."
            return isPhoneValid
        } else {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            let isEmailValid = emailPredicate.evaluate(with: value)
            emailOrMobileError = isEmailValid ? nil : "Please enter a valid Email address."
            return isEmailValid
        }
    }
}
