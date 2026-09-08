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
    @Published var isGeneratingPDF: Bool = false

    // Keyed by challan number — the PDF needs raw fields (department, dl_no, driver_name,
    // court/offence detail, etc.) that the slimmer `Challan` UI model doesn't carry.
    private var rawEntries: [String: ULIPChallanEntry] = [:]

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
                challans = pending.compactMap  { ChallanMapper.map($0, isPending: true) }
                         + disposed.compactMap { ChallanMapper.map($0, isPending: false) }
                rawEntries = Dictionary(
                    (pending + disposed).compactMap { entry -> (String, ULIPChallanEntry)? in
                        guard let no = ChallanMapper.cleaned(entry.challan_no) else { return nil }
                        return (no, entry)
                    },
                    uniquingKeysWith: { first, _ in first }
                )
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

    // MARK: - PDF

    /// Renders the challan identified by [id] and hands it to the system share sheet —
    /// `presentShareSheet` finds the top-most presented controller itself, so this needs no
    /// view reference passed in.
    func downloadPDF(for id: String) {
        guard !isGeneratingPDF, let entry = rawEntries[id] else { return }
        let vehicle = ChallanPDFVehicleContext(
            vehicleNumber: ChallanMapper.cleaned(vehicleNumber),
            ownerName: ChallanMapper.cleaned(ownerName)
        )
        isGeneratingPDF = true
        Task { @MainActor in
            defer { isGeneratingPDF = false }
            let data = ChallanPDFService.generate(challan: entry, vehicle: vehicle)
            let fileName = "Itzeazy_Challan_\(id.filter { $0.isLetter || $0.isNumber }).pdf"
            guard let url = createTemporaryFileURL(fileName: fileName, data: data) else { return }
            presentShareSheet(items: [url])
        }
    }

    private func nonEmpty(_ s: String?) -> String? {
        guard let s = s, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return s
    }
}
