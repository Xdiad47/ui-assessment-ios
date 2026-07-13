import Foundation

// MARK: - Address Model

struct UserAddress: Identifiable, Decodable {
    let id: Int
    let uid: Int
    let userName: String
    let mobile: String
    let email: String
    let country: String
    let pinCode: Int
    let flatHouse: String
    let area: String
    let landmark: String
    let city: String
    let state: String
    let addressType: String
    let address: String
    let status: Int
    let defaultSet: Int

    enum CodingKeys: String, CodingKey {
        case id, uid
        case userName    = "user_name"
        case mobile, email, country
        case pinCode     = "pin_code"
        case flatHouse   = "flat_house"
        case area, landmark, city, state
        case addressType = "address_type"
        case address, status
        case defaultSet  = "default_set"
    }

    // The backend stores older addresses with several string fields (flat_house,
    // area, landmark, state, etc.) saved as JSON null rather than "". A plain
    // Decodable synthesis would fail the whole list decode on the first null
    // field, so each string is decoded leniently and defaults to "" instead.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id          = try container.decode(Int.self, forKey: .id)
        uid         = try container.decode(Int.self, forKey: .uid)
        userName    = try container.decodeIfPresent(String.self, forKey: .userName) ?? ""
        mobile      = try container.decodeIfPresent(String.self, forKey: .mobile) ?? ""
        email       = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        country     = try container.decodeIfPresent(String.self, forKey: .country) ?? ""
        pinCode     = try container.decode(Int.self, forKey: .pinCode)
        flatHouse   = try container.decodeIfPresent(String.self, forKey: .flatHouse) ?? ""
        area        = try container.decodeIfPresent(String.self, forKey: .area) ?? ""
        landmark    = try container.decodeIfPresent(String.self, forKey: .landmark) ?? ""
        city        = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
        state       = try container.decodeIfPresent(String.self, forKey: .state) ?? ""
        addressType = try container.decodeIfPresent(String.self, forKey: .addressType) ?? ""
        address     = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        status      = try container.decode(Int.self, forKey: .status)
        defaultSet  = try container.decode(Int.self, forKey: .defaultSet)
    }

    var isDefault: Bool { defaultSet == 1 }

    /// Human-readable display line shown on the card
    var displayLine: String {
        [flatHouse, area, city, state]
            .filter { !$0.isEmpty && $0 != "string" }
            .joined(separator: ", ")
    }
}

// MARK: - Request body for POST / PUT

struct AddressRequest: Encodable {
    let address: String
    let addressType: String
    let area: String
    let city: String
    let country: String
    let defaultSet: Int
    let email: String
    let flatHouse: String
    let landmark: String
    let mobile: String
    let pinCode: Int
    let state: String
    let status: Int
    let userName: String
    let uid: Int?

    enum CodingKeys: String, CodingKey {
        case address
        case addressType = "address_type"
        case area, city, country
        case defaultSet  = "default_set"
        case email
        case flatHouse   = "flat_house"
        case landmark, mobile
        case pinCode     = "pin_code"
        case state, status
        case userName    = "user_name"
        case uid
    }
}

// MARK: - API Response Wrappers

struct AddressListResponse: Decodable {
    let data: [UserAddress]?
    let message: String?
    let statusCode: Int?

    enum CodingKeys: String, CodingKey {
        case data, message
        case statusCode = "status_code"
    }
}

struct AddressResponse: Decodable {
    let data: UserAddress?
    let message: String?
    let statusCode: Int?

    enum CodingKeys: String, CodingKey {
        case data, message
        case statusCode = "status_code"
    }
}

struct SimpleMessageResponse: Decodable {
    let message: String?
    let statusCode: Int?

    enum CodingKeys: String, CodingKey {
        case message
        case statusCode = "status_code"
    }
}
