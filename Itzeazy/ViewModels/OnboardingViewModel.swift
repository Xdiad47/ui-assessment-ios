import SwiftUI
import Combine

struct OnboardingPage {
    let image: String
    let titleLine1: String
    let titleLine2: String
    let titleLine2Color: Color
    let subtitle: String
}

class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "track_application",
            titleLine1: "Track Applications",
            titleLine2: "Easily",
            titleLine2Color: Color(hex: "#191c1d"),
            subtitle: "Monitor status, upload documents,\nand manage requests seamlessly."
        ),
        OnboardingPage(
            image: "citizen_services",
            titleLine1: "Fast & Hassle-Free",
            titleLine2: "Citizen Services",
            titleLine2Color: .red,
            subtitle: "Apply for government services\neasily from your mobile. No more\nqueues, just seamless digital\napplications."
        ),
        OnboardingPage(
            image: "secure_processing",
            titleLine1: "Doorstep Assistance",
            titleLine2: "& Secure Processing",
            titleLine2Color: .red,
            subtitle: "Safe, verified and trusted services with\nexpert support right at your home. We\nhandle the complexity while you enjoy\nthe results."
        )
    ]

    var isLastPage: Bool { currentPage == pages.count - 1 }
    var buttonTitle: String { isLastPage ? "Get Started" : "Next" }

    func goToNext() {
        guard !isLastPage else { return }
        withAnimation { currentPage += 1 }
    }
}
