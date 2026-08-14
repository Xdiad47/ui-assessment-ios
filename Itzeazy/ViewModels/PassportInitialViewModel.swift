import Foundation
import Combine

@MainActor
final class PassportInitialViewModel: ObservableObject {
    @Published var locations: [String] = []
    @Published var selectedLocation: String = ""
    @Published var selectedService: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    let serviceOptions = ["New Passport", "Passport Renewal"]

    private let api = ItzeazyAPIService.shared
    private let storage = AuthSessionStorage.shared
    private let cache = DocumentsListCache.shared
    private static let cacheKey = "cities"

    var hasSelectedLocationAndService: Bool {
        !selectedLocation.isEmpty && !selectedService.isEmpty
    }

    // MARK: - Fetch cities (GET user/documents/cities, cached on-device for a week)
    // Same endpoint/cache key RTOServiceInitialViewModel uses — cities are shared across services.

    func fetchCities() {
        if locations.isEmpty, let cached = cache.cachedList(for: Self.cacheKey) {
            locations = cached
        }

        guard cache.isStale(for: Self.cacheKey), !isLoading else { return }

        isLoading = locations.isEmpty
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                let response: DocumentsListResponse = try await api.get(
                    endpoint: "user/documents/cities",
                    token: storage.getToken()
                )
                let list = response.data ?? []
                locations = list
                cache.save(list, for: Self.cacheKey)
            } catch let error as ItzeazyAPIError {
                if locations.isEmpty {
                    errorMessage = error.errorDescription
                }
            } catch {
                if locations.isEmpty {
                    errorMessage = "Failed to load cities. Please try again."
                }
            }
        }
    }
}
