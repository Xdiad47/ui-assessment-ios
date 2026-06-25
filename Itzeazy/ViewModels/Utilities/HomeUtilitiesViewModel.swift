import Foundation
import Combine

// MARK: - UtilityWebItem
// Describes a single home-screen utility button that opens a WebView.

struct UtilityWebItem: Identifiable {
    let id    = UUID()
    let label: String      // display label (matches HomeUtilitiesGridView tuple)
    let icon : String      // asset image name
    let url  : String      // hard-coded URL to open
}

// MARK: - HomeUtilitiesViewModel
// ViewModel for the "Utilities" section on HomeView.
// Single source of truth for all utility-grid buttons that open a WebView.

final class HomeUtilitiesViewModel: ObservableObject {

    let webItems: [UtilityWebItem] = [
        UtilityWebItem(
            label: "Road Tax",
            icon:  "road_tax",
            url:   "https://itzeazy.in/road-tax/"
        ),
        UtilityWebItem(
            label: "LL QB",
            icon:  "ll_qb",
            url:   "https://itzeazy.in/driving-school/ll-test-questions"
        ),
        UtilityWebItem(
            label: "LL Mock",
            icon:  "llmock",
            url:   "https://itzeazy.in/driving-school/rto-exam"
        ),
    ]
}
