import Foundation

// MARK: - Login Requests

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

// Apple Sign-In — same endpoints as normal login (POST user/login) and
// create-account (POST user), just with this body shape instead of
// username/password or name/email/phone/pass. Identical shape for both
// login and create-account, confirmed by backend — no name/email needed.
// `loginType` is always the literal string "ios" (lowercase, confirmed by
// backend team — case-sensitive, do not capitalize). `token` is the
// identityToken JWT from ASAuthorizationAppleIDCredential, never the
// authorizationCode.
struct AppleAuthRequest: Encodable {
    let loginType: String = "ios"
    let token: String

    // No memberwise init for loginType — it's hardcoded, not a caller-supplied
    // value, so a future call site can't accidentally send "iOS"/"IOS" again.
    init(token: String) {
        self.token = token
    }

    enum CodingKeys: String, CodingKey {
        case loginType = "login_type"
        case token
    }
}

// Login OTP send (mobile only)
struct SendOTPRequest: Encodable {
    let mobile: String
}

// Login OTP verify (includes type: "login")
struct VerifyOTPRequest: Encodable {
    let mobile: String
    let otp: String
    let type: String
}

// MARK: - Register Requests

struct SendEmailOTPRequest: Encodable {
    let email: String
    let name: String
}

// Register mobile verify — no type field
struct VerifyMobileOTPRequest: Encodable {
    let mobile: String
    let otp: String
}

struct VerifyEmailOTPRequest: Encodable {
    let email: String
    let otp: String
}

struct CreateUserRequest: Encodable {
    let name: String
    let email: String
    let phone: String
    let pass: String
}

// MARK: - Forgot Password Requests

struct ForgotPasswordMobileOTPRequest: Encodable {
    let mobile: String
    let type: String = "forgot_password"
}

struct ForgotPasswordEmailOTPRequest: Encodable {
    let email: String
    let name: String = " "
    let type: String = "forgot_password"
}

struct ForgotPasswordVerifyMobileRequest: Encodable {
    let mobile: String
    let otp: String
    let type: String = "forgot_password"
}

struct ForgotPasswordVerifyEmailRequest: Encodable {
    let email: String
    let otp: String
    let type: String = "forgot_password"
}

struct UpdatePasswordRequest: Encodable {
    let new_password: String
    let confirm_password: String
}

// MARK: - Web Login Token

struct WebLoginTokenRequest: Encodable {
    let redirectPath: String
    enum CodingKeys: String, CodingKey {
        case redirectPath = "redirect_path"
    }
}

struct WebLoginTokenData: Decodable {
    let token: String?
    let url: String?
}

struct WebLoginTokenResponse: Decodable {
    let statusCode: Int?
    let message: String?
    let data: WebLoginTokenData?
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case message, data
    }
}

// Delete-account response — its `data` is just `{ "id": ... }`, not a full
// UserProfile (no `name`, which UserProfile requires), so it needs its own
// lean type rather than reusing AuthResponse/UserProfile.
struct DeleteAccountResponse: Decodable {
    let statusCode: Int?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case message
    }
}

// MARK: - Shared Response Models

struct UserProfile: Codable {
    let id: Int
    let name: String
    let email: String?
    let phone: String?
    let walletAmt: String?
    let myplan: String?
    let pass: String?
    let check: String?
    let fwr: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone
        case walletAmt = "wallet_amt"
        case myplan, pass, check, fwr
    }
}

// MARK: - Responses

struct AuthResponse: Decodable {
    let statusCode: Int
    let message: String
    let data: UserProfile?
    let token: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case message, data, token, error
    }
}

struct SendOTPData: Decodable {
    let requestId: String?
    let type: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case type, message
    }
}

struct SendOTPResponse: Decodable {
    let statusCode: Int?
    let message: String?
    let data: SendOTPData?
    let token: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case message, data, token, error
    }
}
