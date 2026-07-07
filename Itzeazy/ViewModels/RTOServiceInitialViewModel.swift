import Foundation
import Combine

@MainActor
final class RTOServiceInitialViewModel: ObservableObject {
    @Published var locations: [String] = []
    @Published var selectedLocation: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let api = ItzeazyAPIService.shared
    private let storage = AuthSessionStorage.shared
    private let cache = DocumentsListCache.shared
    private static let cacheKey = "cities"

    var hasSelectedLocation: Bool {
        !selectedLocation.isEmpty
    }

    // MARK: - Fetch cities (GET user/documents/cities, cached on-device for a week)

    func fetchCities() {
        // Show the cached list instantly — no network wait if we already have one.
        if locations.isEmpty, let cached = cache.cachedList(for: Self.cacheKey) {
            locations = cached
        }

        // Only hit the network once the cache is missing or a week old.
        guard cache.isStale(for: Self.cacheKey), !isLoading else { return }

        // Only show a blocking spinner when there's nothing cached to display yet;
        // a stale-but-present cache refreshes silently in the background.
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
