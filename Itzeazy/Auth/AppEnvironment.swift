import Foundation

enum AppEnvironment {
    case dev
    case test
    case prod

    // Change this single line to switch environments
    static var current: AppEnvironment = .dev

    var baseURL: String {
        switch self {
        case .dev:  return "https://dev.itzeazy.in/api/v1/"
        case .test: return "https://test.itzeazy.in/api/v1/"
        case .prod: return "https://itzeazy.in/api/v1/"
        }
    }
}
