import Foundation

struct ServiceItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
}

struct PopularItem: Identifiable {
    let id = UUID()
    let type: PopularItemType
}

enum PopularItemType {
    case banner(tag: String, title: String, subtitle: String, buttonText: String, backgroundImage: String)
    case info(title: String, description: String, price: String, iconName: String)
}

struct VehicleRegistrationDetails: Equatable {
    let vehicleNo: String
    let vehicleClass: String
    let maker: String
    let model: String
    let regDate: String
    let fitnessUpto: String
    let colour: String
    let registeredAt: String
    let fuel: String
    let cc: String
    let chassisNo: String
    let engineNo: String
    let status: String
}

struct OwnerDetails: Equatable {
    let name: String
    let serialNo: String
    let type: String
}

struct PUCDetail: Equatable {
    let validStatus: String
}

struct InsuranceDetail: Equatable {
    let provider: String
    let expiryDate: String
}

struct FinanceDetail: Equatable {
    let financeStatus: String
    let blacklistStatus: String
    let nocDetails: String
}

struct Challan: Identifiable, Equatable {
    let id: String
    let title: String
    let date: String
    let amount: Int
    let status: String
    // Detail popup fields
    let challanNo: String
    let dateTime: String
    let sentToCourt: Bool
    let stateCode: String
    let offenceName: String
    let act: String
    let processingDate: String
    let rtoDistrict: String
    let courtDetails: String
    let totalFine: Int
}

struct VehicleSearchResult {
    let registrationDetails: VehicleRegistrationDetails
    let ownerDetails: OwnerDetails
    let insuranceDetail: InsuranceDetail
    let pucDetail: PUCDetail
    let financeDetail: FinanceDetail
    let pendingChallans: [Challan]
}
