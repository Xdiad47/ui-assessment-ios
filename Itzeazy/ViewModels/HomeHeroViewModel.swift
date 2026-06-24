import Foundation
import Combine

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
            SubServiceOption(display: "Passport Renewal",  slug: "passport-renewal-agents-consultants")
        ],
        "rto": [
            SubServiceOption(display: "New Driving License",           slug: "driving-license-agents-consultants"),
            SubServiceOption(display: "Driving License Renewal",       slug: "driving-license-renewal-agents-consultants"),
            SubServiceOption(display: "NOC",                           slug: "noc-for-car-bike"),
            SubServiceOption(display: "Duplicate RC",                  slug: "duplicate-rc-agents-consultants"),
            SubServiceOption(display: "Duplicate Driving License",     slug: "duplicate-driving-license-agents-consultants"),
            SubServiceOption(display: "HP Deletion",                   slug: "hypothecation-deletion-termination-removal-hpt-of-vehicle-car-bike"),
            SubServiceOption(display: "Ownership Transfer",            slug: "ownership-transfer-change-of-vehicle-car-bike"),
            SubServiceOption(display: "International Driving License", slug: "international-driving-license-agents-consultants"),
            SubServiceOption(display: "Re Registration",               slug: "re-registration-agents-consultants")
        ],
        "visa": [
            SubServiceOption(display: "Australia",    slug: "australia-visa-for-indians"),
            SubServiceOption(display: "Bahrain",      slug: "bahrain-visa-for-indians"),
            SubServiceOption(display: "Cambodia",     slug: "cambodia-visa-for-indians"),
            SubServiceOption(display: "Canada",       slug: "canada-visa-for-indians"),
            SubServiceOption(display: "China",        slug: "china-visa-for-indians"),
            SubServiceOption(display: "Croatia",      slug: "croatia-visa-for-indians"),
            SubServiceOption(display: "Denmark",      slug: "denmark-visa-for-indians"),
            SubServiceOption(display: "Egypt",        slug: "egypt-visa-for-indians"),
            SubServiceOption(display: "Finland",      slug: "finland-visa-for-indians"),
            SubServiceOption(display: "France",       slug: "france-visa-for-indians"),
            SubServiceOption(display: "Georgia",      slug: "georgia-visa-for-indians"),
            SubServiceOption(display: "Germany",      slug: "germany-visa-for-indians"),
            SubServiceOption(display: "Greece",       slug: "greece-visa-for-indians"),
            SubServiceOption(display: "Hungary",      slug: "hungary-visa-for-indians"),
            SubServiceOption(display: "Indonesia",    slug: "indonesia-visa-for-indians"),
            SubServiceOption(display: "Italy",        slug: "italy-visa-for-indians"),
            SubServiceOption(display: "Japan",        slug: "japan-visa-for-indians"),
            SubServiceOption(display: "Jordan",       slug: "jordan-visa-for-indians"),
            SubServiceOption(display: "Kenya",        slug: "kenya-visa-for-indians"),
            SubServiceOption(display: "Kuwait",       slug: "kuwait-visa-for-indians"),
            SubServiceOption(display: "Laos",         slug: "laos-visa-for-indians"),
            SubServiceOption(display: "Malaysia",     slug: "malaysia-visa-for-indians"),
            SubServiceOption(display: "Maldives",     slug: "maldives-visa-for-indians"),
            SubServiceOption(display: "Mexico",       slug: "mexico-visa-for-indians"),
            SubServiceOption(display: "Morocco",      slug: "morocco-visa-for-indians"),
            SubServiceOption(display: "Myanmar",      slug: "myanmar-visa-for-indians"),
            SubServiceOption(display: "Nepal",        slug: "nepal-visa-for-indians"),
            SubServiceOption(display: "Netherlands",  slug: "netherlands-visa-for-indians"),
            SubServiceOption(display: "New Zealand",  slug: "new-zealand-visa-for-indians"),
            SubServiceOption(display: "Norway",       slug: "norway-visa-for-indians"),
            SubServiceOption(display: "Oman",         slug: "oman-visa-for-indians"),
            SubServiceOption(display: "Philippines",  slug: "philippines-visa-for-indians"),
            SubServiceOption(display: "Portugal",     slug: "portugal-visa-for-indians"),
            SubServiceOption(display: "Qatar",        slug: "qatar-visa-for-indians"),
            SubServiceOption(display: "Russia",       slug: "russia-visa-for-indians"),
            SubServiceOption(display: "Saudi Arabia", slug: "saudi-arabia-visa-for-indians"),
            SubServiceOption(display: "Schengen",     slug: "schengen-visa-for-indians"),
            SubServiceOption(display: "Singapore",    slug: "singapore-visa-for-indians"),
            SubServiceOption(display: "South Africa", slug: "south-africa-visa-for-indians"),
            SubServiceOption(display: "South Korea",  slug: "south-korea-visa-for-indians"),
            SubServiceOption(display: "Spain",        slug: "spain-visa-for-indians"),
            SubServiceOption(display: "Sri Lanka",    slug: "sri-lanka-visa-for-indians"),
            SubServiceOption(display: "Sweden",       slug: "sweden-visa-for-indians"),
            SubServiceOption(display: "Switzerland",  slug: "switzerland-visa-for-indians"),
            SubServiceOption(display: "Taiwan",       slug: "taiwan-visa-for-indians"),
            SubServiceOption(display: "Thailand",     slug: "thailand-visa-for-indians"),
            SubServiceOption(display: "Turkey",       slug: "turkey-visa-for-indians"),
            SubServiceOption(display: "UAE",          slug: "uae-visa-for-indians"),
            SubServiceOption(display: "Uganda",       slug: "uganda-visa-for-indians"),
            SubServiceOption(display: "UK",           slug: "uk-visa-for-indians"),
            SubServiceOption(display: "USA",          slug: "usa-visa-for-indians"),
            SubServiceOption(display: "Uzbekistan",   slug: "uzbekistan-visa-for-indians"),
            SubServiceOption(display: "Vietnam",      slug: "vietnam-visa-for-indians"),
            SubServiceOption(display: "Zimbabwe",     slug: "zimbabwe-visa-for-indians")
        ]
    ]

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
        return "https://itzeazy.in/\(city.slug)/\(service.slug)/\(subService.slug)-in-\(city.slug)"
    }
}
