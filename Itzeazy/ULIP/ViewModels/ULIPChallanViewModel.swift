import Foundation
import Combine

class ULIPChallanViewModel: ObservableObject {

    @Published var vehicleNumber: String = "" {
        didSet {
            let u = vehicleNumber.uppercased()
            if vehicleNumber != u { vehicleNumber = u }
        }
    }

    @Published var challans: [Challan] = []
    @Published var ownerName: String   = ""
    @Published var isLoading: Bool     = false
    @Published var errorMessage: String? = nil
    @Published var hasSearched: Bool   = false
    @Published var selectedChallanIDs: Set<String> = []

    var pendingCount: Int { challans.filter { $0.status.lowercased() == "pending" }.count }
    // Total of ALL pending — used in the summary badge
    var totalDue: Int {
        challans
            .filter { $0.status.lowercased() == "pending" }
            .reduce(0) { $0 + $1.amount }
    }
    // Selected-only count and total — used in the bottom pay bar
    var selectedCount: Int { selectedChallanIDs.count }
    var selectedTotal: Int {
        challans
            .filter { selectedChallanIDs.contains($0.id) }
            .reduce(0) { $0 + $1.amount }
    }

    func toggleSelection(_ id: String) {
        if selectedChallanIDs.contains(id) {
            selectedChallanIDs.remove(id)
        } else {
            selectedChallanIDs.insert(id)
        }
    }

    func search() {
        let number = vehicleNumber.trimmingCharacters(in: .whitespaces)
        guard !number.isEmpty else { return }

        Task { @MainActor in
            isLoading     = true
            errorMessage  = nil
            challans      = []
            ownerName     = ""
            hasSearched   = false

            do {
                let envelope = try await ULIPChallanService.shared.getChallanDetails(vehicleNumber: number)

                guard let item = envelope.response?.first,
                      item.responseStatus == "SUCCESS",
                      let innerData = item.response?.data else {
                    // The most specific message (e.g. "No Records Found!") lives on the
                    // doubly-nested inner response, not the outer item or top-level
                    // envelope — those often just say "Success" even when there's no data.
                    let msg = envelope.response?.first?.response?.message
                        ?? envelope.response?.first?.message
                        ?? envelope.message
                    errorMessage = msg.isEmpty ? "No challan data found." : msg
                    isLoading = false
                    return
                }

                let pending  = innerData.pendingData  ?? []
                let disposed = innerData.disposedData ?? []
                challans = pending.compactMap  { mapChallan($0) }
                         + disposed.compactMap { mapChallan($0) }
                ownerName   = nonEmpty(pending.first?.owner_name ?? disposed.first?.owner_name) ?? ""
                hasSearched = true

            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    func reset() {
        vehicleNumber      = ""
        challans           = []
        ownerName          = ""
        errorMessage       = nil
        hasSearched        = false
        selectedChallanIDs = []
    }

    // MARK: - Mapping

    private func mapChallan(_ c: ULIPChallanEntry) -> Challan? {
        guard let no = c.challan_no else { return nil }
        let firstOffence = c.offence_details?.first
        let amount       = Int(c.fine_imposed ?? "0") ?? 0
        let court        = [c.court_name, c.court_address]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
        return Challan(
            id:             no,
            title:          nonEmpty(firstOffence?.name) ?? "Traffic Violation",
            date:           String(c.challan_date_time?.prefix(10) ?? ""),
            amount:         amount,
            status:         nonEmpty(c.challan_status)  ?? "Pending",
            challanNo:      no,
            dateTime:       c.challan_date_time ?? "",
            sentToCourt:    c.sent_to_reg_court?.lowercased() == "yes",
            stateCode:      c.state_code ?? "",
            offenceName:    nonEmpty(firstOffence?.name) ?? "",
            act:            nonEmpty(firstOffence?.act)  ?? "",
            processingDate: c.date_of_proceeding ?? "",
            rtoDistrict:    c.rto_distric_name  ?? "",
            courtDetails:   court,
            totalFine:      amount
        )
    }

    private func nonEmpty(_ s: String?) -> String? {
        guard let s = s, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return s
    }
}
