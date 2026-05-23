import Foundation
import Combine

struct HelpSupportIssue: Identifiable, Hashable {
    let id = UUID()
    let title: String
}

final class HelpSupportViewModel: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case raiseTicket = "Raise Ticket"
        case ticketsRaised = "Tickets Raised"

        var id: String { rawValue }
    }

    @Published var selectedTab: Tab = .raiseTicket
    @Published var selectedOrderID: String = ""
    @Published var selectedIssue: HelpSupportIssue?
    @Published var descriptionText: String = ""

    let welcomeTitle: String = "Welcome, amar patil"
    let pageTitle: String = "Help & Support"
    let ticketsSectionTitle: String = "My Tickets"
    let orderLabel: String = "OrderID"
    let issueLabel: String = "Issue"
    let descriptionLabel: String = "Description"
    let descriptionPlaceholder: String = "Let us know about your issue in detail."
    let attachLabel: String = "Click to Attach File"

    let orderIDs: [String] = [
        "Select Order ID",
        "ORDER-10231",
        "ORDER-10245",
        "ORDER-10262"
    ]

    let issues: [HelpSupportIssue] = [
        HelpSupportIssue(title: "-- Choose Issue --"),
        HelpSupportIssue(title: "Sales"),
        HelpSupportIssue(title: "Download Pickup"),
        HelpSupportIssue(title: "Download Dispatch"),
        HelpSupportIssue(title: "Download Return"),
        HelpSupportIssue(title: "Payment"),
        HelpSupportIssue(title: "Refund"),
        HelpSupportIssue(title: "Status Update"),
        HelpSupportIssue(title: "Incomplete Document"),
        HelpSupportIssue(title: "Escalation"),
        HelpSupportIssue(title: "No Response"),
        HelpSupportIssue(title: "Any Other")
    ]
}
