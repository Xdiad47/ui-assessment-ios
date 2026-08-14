import Foundation
import Combine

@MainActor
final class HomeHeroViewModel: ObservableObject {

    // MARK: - Static Data

    let cities: [CityOption] = [
        CityOption(display: "Bangalore",   slug: "bangalore"),
        CityOption(display: "Chennai",     slug: "chennai"),
        CityOption(display: "Delhi",       slug: "delhi"),
        CityOption(display: "Faridabad",   slug: "faridabad"),
        CityOption(display: "Ghaziabad",   slug: "ghaziabad"),
        CityOption(display: "Gurgaon",     slug: "gurgaon"),
        CityOption(display: "Hyderabad",   slug: "hyderabad"),
        CityOption(display: "Jamshedpur",  slug: "jamshedpur"),
        CityOption(display: "Noida",       slug: "noida"),
        CityOption(display: "Mumbai",      slug: "mumbai"),
        CityOption(display: "Pune",        slug: "pune"),
        CityOption(display: "Ranchi",      slug: "ranchi")
    ]

    let services: [ServiceOption] = [
        ServiceOption(display: "Birth Certificate",    slug: "birth-certificate"),
        ServiceOption(display: "Marriage Certificate", slug: "marriage-registration"),
        ServiceOption(display: "Pan Card",             slug: "pan-card"),
        ServiceOption(display: "Passport",             slug: "passport"),
        ServiceOption(display: "RTO",                  slug: "rto"),
        ServiceOption(display: "Visa",                 slug: "visa")
    ]

    // Some cities use a different slug for the same sub-service.
    // Format: [citySlug: [subServiceSlug: overrideSlug]]
    private let citySlugOverrides: [String: [String: String]] = [
        "bangalore": [
            "passport-renewal-online": "passport-renewal-or-re-issue-under-normal-tatkal-scheme"
        ]
    ]

    private let subServicesMap: [String: [SubServiceOption]] = [
        "birth-certificate": [
            SubServiceOption(display: "New Birth Certificate", slug: "birth-certificate-agents-consultants")
        ],
        "marriage-registration": [
            SubServiceOption(display: "Marriage Registration", slug: "marriage-certificate"),
            SubServiceOption(display: "Court Marriage",        slug: "court-marriage")
        ],
        "pan-card": [
            SubServiceOption(display: "New Pan Card", slug: "pan-card-agent-consultant")
        ],
        "passport": [
            SubServiceOption(display: "New Passport",      slug: "passport-application-online"),
            SubServiceOption(display: "Passport Renewal",  slug: "passport-renewal-online")
        ],
        // Display values here must match RTOServiceDetailViewModel.redirectPath's exact
        // switch cases (and RTOServicesViewModel.rtoServices) — that's the string sent as
        // the `work` API param and used to build the "Get Assistance" redirect URL. This
        // used to be a friendlier, mismatched vocabulary that silently broke every RTO
        // type except "Duplicate RC" when reached via the Home hero shortcut.
        "rto": [
            SubServiceOption(display: "New DL",           slug: "driving-license-agents-consultants"),
            SubServiceOption(display: "DL Renewal",       slug: "driving-license-renewal"),
            SubServiceOption(display: "Vehicle NOC",      slug: "noc-for-car-bike"),
            SubServiceOption(display: "Duplicate RC",     slug: "duplicate-rc-of-vehicle-car-bike"),
            SubServiceOption(display: "Duplicate DL",     slug: "duplicate-driving-license"),
            SubServiceOption(display: "HP Termination",   slug: "hypothecation-deletion-termination-removal-hpt-of-vehicle-car-bike"),
            SubServiceOption(display: "RC Transfer",      slug: "ownership-transfer-change-of-vehicle-car-bike"),
            SubServiceOption(display: "Intl. DL",         slug: "international-driving-license"),
            SubServiceOption(display: "Re-registration",  slug: "re-registration-of-vehicle-car-bike")
        ]
        // Visa's country list is NOT static — it comes from the live /countries API
        // (same call VisaViewInitialViewModel makes, cached for a week), see fetchVisaCountries() below.
    ]

    // MARK: - Visa countries (live API, cached on-device for a week)
    // Shares the "countries" cache key with VisaViewInitialViewModel, so opening either
    // screen first primes the cache for the other — no duplicate network hit within the week.

    @Published var visaCountries: [String] = []
    @Published var isLoadingVisaCountries: Bool = false

    private let api = ItzeazyAPIService.shared
    private let storage = AuthSessionStorage.shared
    private let cache = DocumentsListCache.shared
    private static let countriesCacheKey = "countries"

    func fetchVisaCountries() {
        if visaCountries.isEmpty, let cached = cache.cachedList(for: Self.countriesCacheKey) {
            visaCountries = cached
        }

        guard cache.isStale(for: Self.countriesCacheKey), !isLoadingVisaCountries else { return }

        isLoadingVisaCountries = visaCountries.isEmpty

        Task {
            defer { isLoadingVisaCountries = false }
            do {
                let response: DocumentsListResponse = try await api.get(
                    endpoint: "user/documents/countries",
                    token: storage.getToken()
                )
                let list = response.data ?? []
                visaCountries = list
                cache.save(list, for: Self.countriesCacheKey)
            } catch {
                // Silent failure is fine here — VisaViewInitial's own fetch (with visible
                // error/retry UI) is the primary path; this is just a shortcut widget.
            }
        }
    }

    // Best-effort slug for the redirect-path fallback only; the real Visa flow routes
    // natively using the country's display name directly, so this never needs to be exact.
    private func visaCountrySlug(_ display: String) -> String {
        display.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    // MARK: - Published State

    @Published var selectedCity: CityOption? = nil
    @Published var selectedService: ServiceOption? = nil
    @Published var selectedSubService: SubServiceOption? = nil

    // MARK: - Derived

    var isVisaSelected: Bool {
        selectedService?.slug == "visa"
    }

    var availableSubServices: [SubServiceOption] {
        guard let slug = selectedService?.slug else { return [] }
        if slug == "visa" {
            return visaCountries.map { SubServiceOption(display: $0, slug: visaCountrySlug($0)) }
        }
        return subServicesMap[slug] ?? []
    }

    var isGetStartedEnabled: Bool {
        guard let service = selectedService, selectedSubService != nil else { return false }
        if service.slug == "visa" { return true }
        return selectedCity != nil
    }

    // MARK: - Cancellables

    private var cancellables = Set<AnyCancellable>()

    init() {
        // When service changes → reset sub-service (and city for Visa)
        $selectedService
            .dropFirst()
            .sink { [weak self] newService in
                self?.selectedSubService = nil
                if newService?.slug == "visa" {
                    self?.selectedCity = nil
                    self?.fetchVisaCountries()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - URL Builder

    func buildUrl() -> String? {
        guard let service = selectedService, let subService = selectedSubService else { return nil }

        if service.slug == "visa" {
            return "https://itzeazy.in/visa/\(subService.slug)"
        }

        guard let city = selectedCity else { return nil }
        let finalSlug = citySlugOverrides[city.slug]?[subService.slug] ?? subService.slug
        return "https://itzeazy.in/\(city.slug)/\(service.slug)/\(finalSlug)-in-\(city.slug)"
    }
}
