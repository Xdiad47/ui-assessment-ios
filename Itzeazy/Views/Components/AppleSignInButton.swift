import SwiftUI
import AuthenticationServices

/// Custom-styled "Sign in with Apple" button. Keeps Apple's required logo + wording
/// but swaps the stock all-black style for the app's charcoal brand color with a
/// premium soft shadow and hairline highlight, matching the red capsule CTAs.
struct AppleSignInButton: View {
    enum Label {
        case signIn
        case signUp
        case `continue`

        var title: String {
            switch self {
            case .signIn: return "Sign in with Apple"
            case .signUp: return "Sign up with Apple"
            case .continue: return "Continue with Apple"
            }
        }
    }

    var label: Label = .continue
    var onCompletion: (Result<ASAuthorization, Error>) -> Void = { _ in }

    var body: some View {
        Button {
            requestAppleSignIn()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .medium))
                Text(label.title)
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#2b2e30"), Color(hex: "#191c1d")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.22), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func requestAppleSignIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInCoordinator(onCompletion: onCompletion)
        AppleSignInCoordinator.retain(delegate)
        controller.delegate = delegate
        controller.performRequests()
    }
}

/// Bridges ASAuthorizationController's delegate callbacks back into `onCompletion`.
/// Retained for the duration of the request since ASAuthorizationController holds
/// only a weak reference to its delegate.
private final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate {
    private static var activeCoordinators: [AppleSignInCoordinator] = []

    private let onCompletion: (Result<ASAuthorization, Error>) -> Void

    init(onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.onCompletion = onCompletion
    }

    static func retain(_ coordinator: AppleSignInCoordinator) {
        activeCoordinators.append(coordinator)
    }

    private func release() {
        AppleSignInCoordinator.activeCoordinators.removeAll { $0 === self }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onCompletion(.success(authorization))
        release()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onCompletion(.failure(error))
        release()
    }
}

#Preview {
    VStack(spacing: 16) {
        AppleSignInButton(label: .signIn)
        AppleSignInButton(label: .signUp)
    }
    .padding(32)
    .background(Color.white)
}
