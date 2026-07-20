import Foundation

enum AppEnvironment {
    case dev
    case test
    case prod

    // Change this single line to switch environments
    static var current: AppEnvironment = .prod

    var baseURL: String {
        switch self {
        // Dev/test backends disabled — production now points at app.itzeazy.in.
        // Uncomment to restore for local/QA testing.
        // case .dev:  return "https://dev.itzeazy.in/api/v1/"
        // case .test: return "https://test.itzeazy.in/api/v1/"
        case .prod: return "https://app.itzeazy.in/api/v1/"
        default:    return "https://app.itzeazy.in/api/v1/"
        }
    }
}
