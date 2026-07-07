import Foundation
import Combine

@MainActor
final class VisaViewInitialViewModel: ObservableObject {
    @Published var countries: [String] = []
    @Published var searchText: String = ""
    @Published var selectedCountry: String = ""
    @Published var isResultsVisible: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let api = ItzeazyAPIService.shared
    private let storage = AuthSessionStorage.shared
    private let cache = DocumentsListCache.shared
    private static let cacheKey = "countries"

    var filteredCountries: [String] {
        let normalizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return countries }

        return countries.filter { country in
            country.localizedCaseInsensitiveContains(normalizedQuery)
        }
    }

    var buttonEnabled: Bool {
        !selectedCountry.isEmpty
    }

    // MARK: - Fetch countries (GET user/documents/countries, cached on-device for a week)

    func fetchCountries() {
        // Show the cached list instantly — no network wait if we already have one.
        if countries.isEmpty, let cached = cache.cachedList(for: Self.cacheKey) {
            countries = cached
        }

        // Only hit the network once the cache is missing or a week old.
        guard cache.isStale(for: Self.cacheKey), !isLoading else { return }

        // Only show a blocking spinner when there's nothing cached to display yet;
        // a stale-but-present cache refreshes silently in the background.
        isLoading = countries.isEmpty
        errorMessage = nil

        Task {
            defer { isLoading = false }
            do {
                let response: DocumentsListResponse = try await api.get(
                    endpoint: "user/documents/countries",
                    token: storage.getToken()
                )
                let list = response.data ?? []
                countries = list
                cache.save(list, for: Self.cacheKey)
            } catch let error as ItzeazyAPIError {
                if countries.isEmpty {
                    errorMessage = error.errorDescription
                }
            } catch {
                if countries.isEmpty {
                    errorMessage = "Failed to load countries. Please try again."
                }
            }
        }
    }

    func showResults() {
        isResultsVisible = true
    }

    func hideResults() {
        isResultsVisible = false
    }

    func select(country: String) {
        selectedCountry = country
        searchText = country
        isResultsVisible = false
    }
}
