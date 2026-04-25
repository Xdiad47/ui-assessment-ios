import Foundation

class MockRepository {
    static let shared = MockRepository()
    
    private init() {}
    
    func getServices() -> [ServiceItem] {
        return [
            ServiceItem(title: "RTO Services", iconName: "car.fill"),
            ServiceItem(title: "Passport", iconName: "book.pages.fill"),
            ServiceItem(title: "PAN Card", iconName: "person.text.rectangle.fill"),
            ServiceItem(title: "Birth Certificate", iconName: "face.smiling.fill"),
            ServiceItem(title: "Marriage Reg.", iconName: "heart.fill"),
            ServiceItem(title: "Visa", iconName: "airplane"),
            ServiceItem(title: "Income Tax", iconName: "banknote.fill"),
            ServiceItem(title: "Attestation", iconName: "doc.text.fill")
        ]
    }
    
    func getPopularItems() -> [PopularItem] {
        return [
            PopularItem(type: .banner(
                tag: "HOTTEST CHOICE",
                title: "Driving License\nRenewal",
                subtitle: "Skip the queues at the RTO. 100% online process with doorstep delivery.",
                buttonText: "Start Now",
                backgroundImage: "banner_bg" // This will fall back to a colored background if image is missing
            )),
            PopularItem(type: .info(
                title: "International Driving\nPermit",
                description: "Planning a road trip abroad? Get your IDP processed in just 48 hours.",
                price: "₹2,499",
                iconName: "medal.fill"
            ))
        ]
    }
}
