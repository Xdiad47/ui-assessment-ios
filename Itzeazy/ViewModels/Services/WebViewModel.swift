import Foundation
import Combine

// MARK: - WebViewModel
// Manages state for the common CitizenServicesWebView when launched from
// service/utility buttons on the Home screen. Follows MVVM pattern.

final class WebViewModel: ObservableObject {

    // MARK: - Published State
    @Published var isLoading: Bool = true
    @Published var hasError: Bool = false
    @Published var errorMessage: String = ""

    // MARK: - Immutable Config
    let title: String
    let urlString: String

    // MARK: - Init
    init(title: String, urlString: String) {
        self.title     = title
        self.urlString = urlString
    }

    // MARK: - Computed
    var validURL: URL? {
        URL(string: urlString)
    }

    // MARK: - Actions
    func didFinishLoading() {
        isLoading = false
    }

    func didFail(with message: String) {
        isLoading    = false
        hasError     = true
        errorMessage = message
    }

    func reload() {
        hasError  = false
        isLoading = true
    }
}
