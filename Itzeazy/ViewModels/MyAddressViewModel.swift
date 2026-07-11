import Foundation
import Combine

@MainActor
final class MyAddressViewModel: ObservableObject {
    @Published var addresses: [UserAddress] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var deletingId: Int? = nil

    let pageTitle      = "My Account"
    let addressesTitle = "My Addresses"

    private let api     = ItzeazyAPIService.shared
    private let storage = AuthSessionStorage.shared

    init() {
        fetchAddresses()
    }

    func fetchAddresses() {
        guard let token = storage.getToken() else { return }
        isLoading = true
        errorMessage = nil
        Task {
            defer { isLoading = false }
            do {
                let response: AddressListResponse = try await api.get(
                    endpoint: "user/address",
                    token: token
                )
                addresses = response.data ?? []
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Failed to load addresses. Please try again."
            }
        }
    }

    func deleteAddress(id: Int) {
        guard let token = storage.getToken() else { return }
        deletingId = id
        errorMessage = nil
        Task {
            defer { deletingId = nil }
            do {
                let _: SimpleMessageResponse = try await api.delete(
                    endpoint: "user/address?id=\(id)",
                    token: token
                )
                addresses.removeAll { $0.id == id }
            } catch let error as ItzeazyAPIError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Failed to delete address. Please try again."
            }
        }
    }
}
