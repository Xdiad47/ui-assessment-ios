import Foundation

// MARK: - Login Requests

struct LoginRequest: Encodable {
    let username: String
    let password: String
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
