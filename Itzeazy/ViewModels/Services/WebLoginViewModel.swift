import Foundation
import Combine

@MainActor
final class WebLoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var generatedURL: String? = nil
    @Published var generatedTitle: String = ""

    private let api = ItzeazyAPIService.shared
    private let storage = AuthSessionStorage.shared

    func generateToken(urlString: String, title: String) {
        guard let token = storage.getToken() else {
            errorMessage = "Please log in to access this service."
            return
        }
        guard let path = URL(string: urlString)?.path, !path.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        generatedTitle = title

        Task {
            defer { isLoading = false }
            do {
                let body = WebLoginTokenRequest(redirectPath: path)
                let response: WebLoginTokenResponse = try await api.post(
                    endpoint: "user/generate-web-login-token",
                    body: body,
                    token: token
                )
                if let url = response.data?.url {
                    generatedURL = url
                }
            } catch {
                errorMessage = (error as? ItzeazyAPIError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    func reset() {
        generatedURL = nil
        generatedTitle = ""
    }
}
