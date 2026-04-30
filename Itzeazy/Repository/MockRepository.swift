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
    
    func getVehicleSearchResult() -> VehicleSearchResult {
        return VehicleSearchResult(
            registrationDetails: VehicleRegistrationDetails(
                vehicleNo: "UP14CQ4004",
                vehicleClass: "LMV",
                maker: "M & M Ltd",
                model: "XUV 500 W8 AWD",
                regDate: "12-Mar-2016",
                fitnessUpto: "11-Mar-2031",
                colour: "Silver",
                registeredAt: "Deoria RTO, Uttar pradesh",
                fuel: "Diesel",
                cc: "2179 CC",
                chassisNo: "MA1T******34",
                engineNo: "D4D*******89",
                status: "ACTIVE"
            ),
            ownerDetails: OwnerDetails(
                name: "AH GA",
                serialNo: "3",
                type: "Individual"
            ),
            insuranceDetail: InsuranceDetail(
                provider: "Bajaj General",
                expiryDate: "28-Jun-2026"
            ),
            pucDetail: PUCDetail(
                validStatus: "Val: 09-Jan-2026"
            ),
            financeDetail: FinanceDetail(
                financeStatus: "N/A",
                blacklistStatus: "NONE",
                nocDetails: "Not Available"
            ),
            pendingChallans: [
                Challan(
                    id: "CH8829102", title: "Over Speeding", date: "12 Oct, 2023", amount: 1000, status: "PENDING",
                    challanNo: "UP04231523804092235", dateTime: "11.02.2023 13:26:31",
                    sentToCourt: true, stateCode: "UP",
                    offenceName: "Contravention of the speed limits (In the light motor vehicle)",
                    act: "MV Act 1988 s 112", processingDate: "2023-07-22",
                    rtoDistrict: "Noida, GBN", courtDetails: "CJM GBN, GAUTAMBUDHNAGAR", totalFine: 2000
                ),
                Challan(
                    id: "CH8829103", title: "Signal Jumping", date: "5 Oct, 2023", amount: 1000, status: "PENDING",
                    challanNo: "UP04231523804092236", dateTime: "05.10.2023 09:14:22",
                    sentToCourt: false, stateCode: "UP",
                    offenceName: "Driving without observing traffic signals",
                    act: "MV Act 1988 s 119", processingDate: "2023-10-10",
                    rtoDistrict: "Deoria, UP", courtDetails: "CJM Deoria, UTTAR PRADESH", totalFine: 1000
                ),
                Challan(
                    id: "CH8829104", title: "Wrong Parking", date: "28 Sep, 2023", amount: 1000, status: "PENDING",
                    challanNo: "UP04231523804092237", dateTime: "28.09.2023 17:45:10",
                    sentToCourt: false, stateCode: "UP",
                    offenceName: "Parking in a no-parking zone causing obstruction",
                    act: "MV Act 1988 s 122", processingDate: "2023-10-05",
                    rtoDistrict: "Deoria, UP", courtDetails: "CJM Deoria, UTTAR PRADESH", totalFine: 1000
                )
            ]
        )
    }
}
