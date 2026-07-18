import Foundation

// MARK: - Itzeazy gateway envelope
// Every ULIP call is now routed through the Itzeazy backend's own ULIP gateway
// (authenticated with the user's existing session token, no separate ULIP
// login needed). The gateway wraps the original ULIP response body — unchanged
// — inside `data`.

struct ItzeazyGatewayResponse<T: Decodable>: Decodable {
    let data: T?
    let message: String
    let statusCode: Int

    enum CodingKeys: String, CodingKey {
        case data, message
        case statusCode = "status_code"
    }
}

// MARK: - Generic envelope (original ULIP response shape, now nested under `data`)

struct ULIPResponse<T: Decodable>: Decodable {
    let response: T?
    let error: String
    let code: String
    let message: String
}

// MARK: - Vehicle RC (VAHAN/04)

struct ULIPVehicleRCRequest: Encodable {
    let vehicleNumber: String

    enum CodingKeys: String, CodingKey {
        case vehicleNumber = "vehiclenumber"
    }
}

// MARK: - Chassis RC (VAHAN/05) — response reuses ULIPVehicleRCResponse

struct ULIPChassisRCRequest: Encodable {
    let chassisNumber: String

    // API key is "chasisnumber" (single 's' — API typo, must match exactly)
    enum CodingKeys: String, CodingKey {
        case chassisNumber = "chasisnumber"
    }
}

// MARK: - Engine RC (VAHAN/06) — response reuses ULIPVehicleRCResponse

struct ULIPEngineRCRequest: Encodable {
    let engineNumber: String

    enum CodingKeys: String, CodingKey {
        case engineNumber = "enginenumber"
    }
}

// Actual vehicle data inside the nested "response" object
struct ULIPVehicleRCData: Decodable {
    let rcRegnNo: String?
    let rcRegnDt: String?
    let rcPurchaseDt: String?
    let rcChasiNo: String?
    let rcEngNo: String?
    let rcVhClassDesc: String?
    let rcVhCatg: String?
    let rcVchCatgDesc: String?
    let rcMakerDesc: String?
    let rcMakerModel: String?
    let rcBodyTypeDesc: String?
    let rcFuelDesc: String?
    let rcColor: String?
    let rcOwnerName: String?
    let rcOwnerSr: String?
    let rcOwnerCdDesc: String?
    let rcPermanentAddress: String?
    let rcFitUpto: String?
    let rcRegnUpto: String?
    let rcFinancer: String?
    let rcRegisteredAt: String?
    let rcStatusAsOn: String?
    let rcStatus: String?
    let rcCubicCap: String?
    let rcSeatCap: String?
    let rcNoCyl: String?
    let rcPuccUpto: String?
    let rcPuccNo: String?
    let rcBlacklistStatus: String?
    let rcNocDetails: String?
    let rcInsuranceComp: String?
    let rcInsurancePolicyNo: String?
    let rcInsuranceUpto: String?
    let rcNormsDesc: String?
    let rcManuMonthYr: String?
    let rcSaleAmt: String?
    let stateCd: String?
    let rtoCd: String?
    let stautsMessage: String?
}

// Each element in the outer array wraps the vehicle data in its own "response" key
struct ULIPVehicleRCItem: Decodable {
    let response: ULIPVehicleRCData?
    let responseStatus: String?
    let message: String?
}

// Full envelope: response → [ULIPVehicleRCItem] → response → ULIPVehicleRCData
typealias ULIPVehicleRCResponse = ULIPResponse<[ULIPVehicleRCItem]>

// MARK: - Driving License (SARATHI/01)

struct ULIPDLRequest: Encodable {
    let dlNumber: String
    let dob: String  // YYYY-MM-DD required by API

    enum CodingKeys: String, CodingKey {
        case dlNumber = "dlnumber"
        case dob
    }
}

// dlcovs[] — one entry per vehicle class on the licence
struct ULIPSarathiCOV: Decodable {
    let vecatg: String?    // "NT" or "T"
    let covabbrv: String?  // e.g. "LMV", "MCWG"
    let covdesc: String?   // full description
    let dcIssuedt: String? // issue date
}

struct ULIPSarathiBio: Decodable {
    let bioFullName: String?
    let bioDob: String?
}

struct ULIPSarathiDLObj: Decodable {
    let dlLicno: String?
    let dlStatus: String?
    let dlIssuedt: String?
    let omRtoFullname: String?  // issuing office
    let dlNtValdfrDt: String?
    let dlNtValdtoDt: String?
    let dlTrValdfrDt: String?
    let dlTrValdtoDt: String?
    let dlOldLicno: String?
    let stateName: String?
    let dlIssuedesig: String?
}

// Each element inside dldetobj[]
struct ULIPSarathiDLDetObj: Decodable {
    let bioObj: ULIPSarathiBio?
    let dlobj: ULIPSarathiDLObj?
    let dlcovs: [ULIPSarathiCOV]?
}

// Inner "response" object inside each array item
struct ULIPSarathiInnerResponse: Decodable {
    let dldetobj: [ULIPSarathiDLDetObj]?
}

// Each element in the outer response[]
struct ULIPSarathiRCItem: Decodable {
    let response: ULIPSarathiInnerResponse?
    let responseStatus: String?
    let message: String?
}

typealias ULIPDLResponse = ULIPResponse<[ULIPSarathiRCItem]>

// MARK: - Challan (ECHALLAN/01)

struct ULIPChallanRequest: Encodable {
    let vehicleNumber: String
}

struct ULIPChallanOffenceDetail: Decodable {
    let act: String?
    let name: String?
}

// snake_case names match JSON keys exactly — no CodingKeys needed for these
struct ULIPChallanEntry: Decodable {
    let challan_no: String?
    let challan_date_time: String?
    let challan_place: String?
    let challan_status: String?
    let sent_to_reg_court: String?
    let remark: String?
    let fine_imposed: String?
    let dl_no: String?
    let driver_name: String?
    let owner_name: String?
    let name_of_violator: String?
    let department: String?
    let state_code: String?
    let document_impounded: String?
    let offence_details: [ULIPChallanOffenceDetail]?
    let amount_of_fine_imposed: String?
    let court_address: String?
    let court_name: String?
    let date_of_proceeding: String?
    let sent_to_court_on: String?
    let sent_to_virtual_court: String?
    let rto_distric_name: String?
    let receipt_no: String?
    let received_amount: Int?
}

// JSON uses capital-prefixed keys "Pending_data"/"Disposed_data" — CodingKeys required
struct ULIPChallanData: Decodable {
    let pendingData: [ULIPChallanEntry]?
    let disposedData: [ULIPChallanEntry]?

    enum CodingKeys: String, CodingKey {
        case pendingData  = "Pending_data"
        case disposedData = "Disposed_data"
    }
}

struct ULIPChallanInnerResponse: Decodable {
    let data: ULIPChallanData?
    let status: String?
    let message: String?
}

// Same double-nesting pattern as VAHAN/04: outer array → item.response → actual data
struct ULIPChallanRCItem: Decodable {
    let response: ULIPChallanInnerResponse?
    let responseStatus: String?
    let message: String?
}

typealias ULIPChallanResponse = ULIPResponse<[ULIPChallanRCItem]>

// MARK: - Telangana Vehicle (TGVAHAN/01)
// The outer "response" array item carries the XML payload as a raw String — not a JSON object.

struct ULIPTGVehicleRequest: Encodable {
    let vehicleNumber: String
    enum CodingKeys: String, CodingKey {
        case vehicleNumber = "vehiclenumber"
    }
}

struct ULIPTGVehicleRCItem: Decodable {
    let response: String?       // raw XML string
    let responseStatus: String?
    let message: String?
}

typealias ULIPTGVehicleResponse = ULIPResponse<[ULIPTGVehicleRCItem]>

// MARK: - Telangana DL (TGSARATHI/01)
// Same pattern as TGVAHAN/01 — response field is a raw XML string.

struct ULIPTGDLRequest: Encodable {
    let dlNumber: String
    enum CodingKeys: String, CodingKey {
        case dlNumber = "dlnumber"
    }
}

struct ULIPTGDLRCItem: Decodable {
    let response: String?       // raw XML string
    let responseStatus: String?
    let message: String?
}

typealias ULIPTGDLResponse = ULIPResponse<[ULIPTGDLRCItem]>

// MARK: - EV Charging Stations (EVYATRA/01)

struct ULIPEVChargeRequest: Encodable {
    let stateId: String
    let lat: String
    let long: String
}

struct ULIPEVStationItem: Decodable {
    let id: Int?
    let cpoId: Int?
    let stateId: Int?
    let cityId: Int?
    let stationName: String?
    let address: String?
    let pincode: String?
    let lat: Double?
    let lng: Double?

    enum CodingKeys: String, CodingKey {
        case id, address, pincode, lat, lng
        case cpoId        = "cpo_id"
        case stateId      = "state_id"
        case cityId       = "city_id"
        case stationName  = "station_name"
    }
}

struct ULIPEVChargeRCItem: Decodable {
    let response: [ULIPEVStationItem]?
    let responseStatus: String?
    let message: String?
}

typealias ULIPEVChargeResponse = ULIPResponse<[ULIPEVChargeRCItem]>
