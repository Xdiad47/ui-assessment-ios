import Foundation
import Combine

struct OrderItem: Identifiable {
    let id = UUID()
    let serviceName: String
    let amountText: String
    let orderId: String
    let statusText: String
    let placedOnText: String
    let iconName: String
}

class MyOrdersViewModel: ObservableObject {
    @Published var welcomeName: String = "amar patil"

    let sectionTitle: String = "All Orders"

    let orders: [OrderItem] = [
        OrderItem(
            serviceName: "Challan",
            amountText: "₹5000",
            orderId: "DELRTCH113",
            statusText: "Submit Documents",
            placedOnText: "Placed on 09 May, 2026 02:16:50",
            iconName: "doc.text"
        ),
        OrderItem(
            serviceName: "Visa",
            amountText: "₹7800",
            orderId: "VISA3921",
            statusText: "Pay Full Payment",
            placedOnText: "Placed on 22 Feb, 2026 11:12:34",
            iconName: "airplane"
        ),
        OrderItem(
            serviceName: "Passport",
            amountText: "₹2399",
            orderId: "INDPPNW6617",
            statusText: "Pay Full Payment",
            placedOnText: "Placed on 22 Feb, 2026 07:43:04",
            iconName: "book"
        ),
        OrderItem(
            serviceName: "Passport",
            amountText: "₹2399",
            orderId: "INDPPNW6616",
            statusText: "Pay Full Payment",
            placedOnText: "Placed on 22 Feb, 2026 07:41:13",
            iconName: "book"
        )
    ]
}
