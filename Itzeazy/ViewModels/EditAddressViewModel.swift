import Foundation
import Combine

enum EditAddressMode {
    case create
    case edit(id: Int)
}

@MainActor
final class EditAddressViewModel: ObservableObject {

    // MARK: - Form fields
    @Published var userName   = ""
    @Published var mobile     = ""
    @Published var email      = ""
    @Published var flatHouse  = ""
    @Published var area       = ""
    @Published var landmark   = ""
    @Published var city       = ""
    @Published var state      = ""
    @Published var country    = ""
    @Published var pinCode    = ""

    // MARK: - State
    @Published var isLoading  = false
    @Published var isSaving   = false
    @Published var errorMessage: String? = nil
    @Published var didSaveSuccessfully = false

    let mode: EditAddressMode

    var navigationTitle: String {
        switch mode {
        case .create:   return "Add Address"
        case .edit:     return "Edit Address"
        }
    }

    private let api     = ItzeazyAPIService.shared
    private let storage = AuthSessionStorage.shared

    init(mode: EditAddressMode) {
        self.mode = mode
        if case .edit(let id) = mode {
            fetchAddress(id: id)
        }
    }

    // MARK: - Fetch by ID (edit mode)

    private func fetchAddress(id: Int) {
        guard let token = storage.getToken() else { return }
        isLoading = true
        errorMessage = nil
        Task {
            defer { isLoading = false }
            do {
                let response: AddressResponse = try await api.get(
                    endpoint: "user/address/id?id=\(id)",
                    token: token
                )
                if let addr = response.data {
                    populateFields(from: addr)
                }
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Failed to load address details."
            }
        }
    }

    private func populateFields(from addr: UserAddress) {
        userName  = addr.userName
        mobile    = addr.mobile
        email     = addr.email
        flatHouse = addr.flatHouse
        area      = addr.area
        landmark  = addr.landmark
        city      = addr.city
        state     = addr.state
        country   = addr.country.isEmpty ? "India" : addr.country
        pinCode   = addr.pinCode > 0 ? String(addr.pinCode) : ""
    }

    // MARK: - Save (create or update)

    func save() {
        guard let token = storage.getToken() else { return }
        guard validateFields() else { return }

        isSaving = true
        errorMessage = nil

        let uid  = storage.getUser()?.id
        let pin  = Int(pinCode) ?? 0
        let body = AddressRequest(
            address:     area.isEmpty ? city : area,
            addressType: "Home",
            area:        area,
            city:        city,
            country:     country,
            defaultSet:  0,
            email:       email,
            flatHouse:   flatHouse,
            landmark:    landmark,
            mobile:      mobile,
            pinCode:     pin,
            state:       state,
            status:      1,
            userName:    userName,
            uid:         uid
        )

        Task {
            defer { isSaving = false }
            do {
                switch mode {
                case .create:
                    let _: AddressResponse = try await api.post(
                        endpoint: "user/address",
                        body: body,
                        token: token
                    )
                case .edit(let id):
                    let _: AddressResponse = try await api.put(
                        endpoint: "user/address?id=\(id)",
                        body: body,
                        token: token
                    )
                }
                didSaveSuccessfully = true
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Failed to save address. Please try again."
            }
        }
    }

    // MARK: - Validation

    private func validateFields() -> Bool {
        if userName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your name."
            return false
        }
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your email."
            return false
        }
        if city.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter a city."
            return false
        }
        if state.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter a state."
            return false
        }
        if pinCode.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter a pin code."
            return false
        }
        return true
    }
}
