import Foundation

struct ServiceItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    var isAsset: Bool = false
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

struct DLInfo {
    let dlNumber: String
    let currentStatus: String
    let holderName: String
    let oldNewDLNumber: String
    let sourceOfData: String

    let initialIssueDate: String
    let initialIssuingOffice: String

    let nonTransportFrom: String
    let nonTransportTo: String
    let transportFrom: String
    let transportTo: String

    let covDetails: [COVDetail]
}

struct COVDetail: Identifiable {
    let id = UUID()
    let category: String
    let classOfVehicle: String
    let issueDate: String
}

// MARK: - HomeHero Data Models

struct CityOption: Identifiable, Equatable {
    let id = UUID()
    let display: String
    let slug: String
}

struct ServiceOption: Identifiable, Equatable {
    let id = UUID()
    let display: String
    let slug: String
}

struct SubServiceOption: Identifiable, Equatable {
    let id = UUID()
    let display: String
    let slug: String
}
