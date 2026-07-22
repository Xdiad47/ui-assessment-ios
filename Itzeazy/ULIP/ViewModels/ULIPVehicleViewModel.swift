import Foundation
import Combine

class ULIPVehicleViewModel: ObservableObject {

    // Which search tab is active (Vehicle / Chassis / Engine)
    @Published var searchType: VehicleSearchType = .vehicle

    // Input — forced to uppercase as the user types
    @Published var vehicleNumber: String = "" {
        didSet {
            let uppercased = vehicleNumber.uppercased()
            if vehicleNumber != uppercased { vehicleNumber = uppercased }
        }
    }

    // Output states
    @Published var searchResult: VehicleSearchResult? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedChallanIDs: Set<String> = []
    // Non-blocking note from the challan lookup (e.g. "No Records Found!") — the
    // vehicle lookup itself still succeeds, this is just shown alongside it.
    @Published var challanInfoMessage: String? = nil

    // pendingChallans stores ALL challans (pending + disposed); filter for counts/sums
    var pendingChallanCount: Int {
        searchResult?.pendingChallans.filter { $0.status.lowercased() == "pending" }.count ?? 0
    }
    // Total of ALL pending — used in the summary header badge
    var totalDue: Int {
        searchResult?.pendingChallans
            .filter { $0.status.lowercased() == "pending" }
            .reduce(0) { $0 + $1.amount } ?? 0
    }
    // Selected-only count and total — used in the bottom pay bar
    var selectedChallansCount: Int { selectedChallanIDs.count }
    var selectedTotal: Int {
        searchResult?.pendingChallans
            .filter { selectedChallanIDs.contains($0.id) }
            .reduce(0) { $0 + $1.amount } ?? 0
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
            isLoading          = true
            errorMessage       = nil
            searchResult       = nil
            challanInfoMessage = nil

            do {
                let envelope = try await fetchBySearchType(number: number)

                if let item = envelope.response?.first,
                   item.responseStatus == "SUCCESS",
                   let data = item.response {

                    var result = mapToVehicleSearchResult(data)

                    // Use registration number from response for challan lookup
                    // (needed when searching by chassis/engine — the reg no differs from input)
                    let regNo = nonEmpty(data.rcRegnNo) ?? number
                    if let challans = try? await fetchChallans(vehicleNumber: regNo) {
                        result = VehicleSearchResult(
                            registrationDetails: result.registrationDetails,
                            ownerDetails:        result.ownerDetails,
                            insuranceDetail:     result.insuranceDetail,
                            pucDetail:           result.pucDetail,
                            financeDetail:       result.financeDetail,
                            pendingChallans:     challans
                        )
                    }

                    searchResult = result
                } else {
                    let msg = envelope.response?.first?.message ?? envelope.message
                    errorMessage = (msg.isEmpty == false) ? msg : "No vehicle data found."
                }
            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    private func fetchBySearchType(number: String) async throws -> ULIPVehicleRCResponse {
        switch searchType {
        case .vehicle: return try await ULIPVehicleService.shared.getVehicleDetails(vehicleNumber: number)
        case .chassis: return try await ULIPChassisService.shared.getChassisDetails(chassisNumber: number)
        case .engine:  return try await ULIPEngineService.shared.getEngineDetails(engineNumber: number)
        }
    }

    func reset() {
        vehicleNumber      = ""
        searchResult       = nil
        errorMessage       = nil
        selectedChallanIDs = []
        challanInfoMessage = nil
    }

    // MARK: - Challan fetch + mapping

    private func fetchChallans(vehicleNumber: String) async throws -> [Challan] {
        let envelope = try await ULIPChallanService.shared.getChallanDetails(vehicleNumber: vehicleNumber)
        guard let item = envelope.response?.first,
              item.responseStatus == "SUCCESS",
              let innerData = item.response?.data else {
            // Same doubly-nested message shape as the standalone Challan screen —
            // e.g. "No Records Found!" lives on the inner response, not the outer
            // item or envelope. Non-blocking: the vehicle lookup itself still
            // succeeded, so surface this as an informational note, not an error.
            challanInfoMessage = envelope.response?.first?.response?.message
                ?? envelope.response?.first?.message
            return []
        }
        challanInfoMessage = nil
        var challans: [Challan] = []
        challans += (innerData.pendingData  ?? []).compactMap { mapChallan($0) }
        challans += (innerData.disposedData ?? []).compactMap { mapChallan($0) }
        return challans
    }

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

    // MARK: - Vehicle RC mapping

    private func mapToVehicleSearchResult(_ d: ULIPVehicleRCData) -> VehicleSearchResult {
        let vehicleClass    = nonEmpty(d.rcVhClassDesc)    ?? nonEmpty(d.rcVchCatgDesc) ?? nonEmpty(d.rcVhCatg) ?? "N/A"
        let ccDisplay: String = {
            if let cap = nonEmpty(d.rcCubicCap) { return "\(cap) CC" }
            return "N/A"
        }()
        let fitnessUpto     = nonEmpty(d.rcFitUpto)         ?? nonEmpty(d.rcRegnUpto) ?? "N/A"
        let financeStatus   = nonEmpty(d.rcFinancer)        ?? "N/A"
        let blacklistStatus = nonEmpty(d.rcBlacklistStatus) ?? "NONE"
        let nocDetails      = nonEmpty(d.rcNocDetails)      ?? "Not Available"

        return VehicleSearchResult(
            registrationDetails: VehicleRegistrationDetails(
                vehicleNo:    nonEmpty(d.rcRegnNo)       ?? vehicleNumber,
                vehicleClass: vehicleClass,
                maker:        nonEmpty(d.rcMakerDesc)    ?? "N/A",
                model:        nonEmpty(d.rcMakerModel)   ?? "N/A",
                regDate:      nonEmpty(d.rcRegnDt)       ?? "N/A",
                fitnessUpto:  fitnessUpto,
                colour:       nonEmpty(d.rcColor)        ?? "N/A",
                registeredAt: nonEmpty(d.rcRegisteredAt) ?? "N/A",
                fuel:         nonEmpty(d.rcFuelDesc)     ?? "N/A",
                cc:           ccDisplay,
                chassisNo:    nonEmpty(d.rcChasiNo)      ?? "N/A",
                engineNo:     nonEmpty(d.rcEngNo)        ?? "N/A",
                status:       nonEmpty(d.rcStatus)       ?? "N/A"
            ),
            ownerDetails: OwnerDetails(
                name:     nonEmpty(d.rcOwnerName)   ?? "N/A",
                serialNo: nonEmpty(d.rcOwnerSr)     ?? "1",
                type:     nonEmpty(d.rcOwnerCdDesc) ?? "Individual"
            ),
            insuranceDetail: InsuranceDetail(
                provider:   nonEmpty(d.rcInsuranceComp) ?? "N/A",
                expiryDate: nonEmpty(d.rcInsuranceUpto) ?? "N/A"
            ),
            pucDetail: PUCDetail(
                validStatus: nonEmpty(d.rcPuccUpto) ?? "N/A"
            ),
            financeDetail: FinanceDetail(
                financeStatus:   financeStatus,
                blacklistStatus: blacklistStatus,
                nocDetails:      nocDetails
            ),
            pendingChallans: []
        )
    }

    private func nonEmpty(_ s: String?) -> String? {
        guard let s = s, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return s
    }
}
