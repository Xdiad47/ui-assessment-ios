import SwiftUI
import Combine

struct OnboardingPage {
    let image: String
    let titleLine1: String
    let titleLine2: String
    let titleLine2Color: Color
    let titleFontSize: CGFloat
    let titleLineSpacing: CGFloat
    let subtitle: String
    let subtitleFontSize: CGFloat
    let subtitleLineSpacing: CGFloat
    let showLegalLinks: Bool

    init(
        image: String,
        titleLine1: String,
        titleLine2: String,
        titleLine2Color: Color,
        titleFontSize: CGFloat = 32,
        titleLineSpacing: CGFloat = 8,
        subtitle: String,
        subtitleFontSize: CGFloat = 18,
        subtitleLineSpacing: CGFloat = 5.25,
        showLegalLinks: Bool = false
    ) {
        self.image = image
        self.titleLine1 = titleLine1
        self.titleLine2 = titleLine2
        self.titleLine2Color = titleLine2Color
        self.titleFontSize = titleFontSize
        self.titleLineSpacing = titleLineSpacing
        self.subtitle = subtitle
        self.subtitleFontSize = subtitleFontSize
        self.subtitleLineSpacing = subtitleLineSpacing
        self.showLegalLinks = showLegalLinks
    }
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
        ),
        OnboardingPage(
            image: "citizen_services",
            titleLine1: "Before You Get Started",
            titleLine2: "",
            titleLine2Color: Color(hex: "#191c1d"),
            titleFontSize: 28,
            titleLineSpacing: 6,
            subtitle: "Itzeazy is a private service platform and is not affiliated with any government department. Vehicle, RC, DL and challan information is sourced via ULIP (DPIIT, Government of India). We assist users with documentation and application support; we do not issue government documents.",
            subtitleFontSize: 14,
            subtitleLineSpacing: 8.75,
            showLegalLinks: true
        )
    ]

    var isLastPage: Bool { currentPage == pages.count - 1 }
    var buttonTitle: String { isLastPage ? "Get Started" : "Next" }

    func goToNext() {
        guard !isLastPage else { return }
        withAnimation { currentPage += 1 }
    }

    // Skip jumps straight to the final disclaimer page rather than completing
    // onboarding outright — that page's legal notice must always be shown.
    func skipToDisclaimer() {
        withAnimation { currentPage = pages.count - 1 }
    }
}
