import Foundation
import Combine

final class VisaViewInitialViewModel: ObservableObject {
    let countries = [
        "Australia",
        "Bahrain",
        "Cambodia",
        "Canada",
        "China",
        "Croatia",
        "Denmark",
        "Egypt",
        "Finland",
        "France",
        "Georgia",
        "Germany",
        "Greece",
        "Hungary",
        "Indonesia",
        "Italy",
        "Japan",
        "Jordan",
        "Kenya",
        "Kuwait",
        "Laos",
        "Malaysia",
        "Maldives",
        "Mexico",
        "Morocco",
        "Myanmar",
        "Nepal",
        "Netherlands",
        "New Zealand",
        "Norway",
        "Oman",
        "Philippines",
        "Portugal",
        "Qatar",
        "Russia",
        "Saudi Arabia",
        "Schengen",
        "Singapore",
        "South Africa",
        "South Korea",
        "Spain",
        "Sri Lanka",
        "Sweden",
        "Switzerland",
        "Taiwan",
        "Thailand",
        "Turkey",
        "UAE",
        "Uganda",
        "UK",
        "USA",
        "Uzbekistan",
        "Vietnam",
        "Zimbabwe"
    ]

    @Published var searchText: String = ""
    @Published var selectedCountry: String = ""
    @Published var isResultsVisible: Bool = false

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
