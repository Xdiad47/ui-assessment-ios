import Foundation
import Combine

class DLInfoViewModel: ObservableObject {
    private static let inputDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.isLenient = false
        return formatter
    }()

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }()

    @Published var dlNumber: String = "" {
        didSet {
            let u = dlNumber.uppercased()
            if dlNumber != u { dlNumber = u }
        }
    }
    @Published var dob: String = "" // user enters DD-MM-YYYY

    @Published var isLoading: Bool = false
    @Published var dlInfo: DLInfo? = nil
    @Published var errorMessage: String? = nil
    @Published var hasSearched: Bool = false

    func getDetails() {
        let number = dlNumber.trimmingCharacters(in: .whitespaces)
        let dobStr = dob.trimmingCharacters(in: .whitespaces)
        guard !number.isEmpty, !dobStr.isEmpty else { return }
        guard let apiDob = convertDobToAPIFormat(dobStr) else {
            errorMessage = "Please enter DOB in DD-MM-YYYY format."
            hasSearched = false
            return
        }

        Task { @MainActor in
            isLoading    = true
            errorMessage = nil
            dlInfo       = nil
            hasSearched  = false

            do {
                let envelope = try await ULIPDLService.shared.getDLDetails(dlNumber: number, dob: apiDob)

                guard let item = envelope.response?.first,
                      item.responseStatus == "SUCCESS",
                      let detObj = item.response?.dldetobj?.first else {
                    let msg = envelope.response?.first?.message ?? envelope.message
                    errorMessage = (msg.isEmpty == false) ? msg : "No DL data found."
                    isLoading = false
                    return
                }

                dlInfo      = mapToDLInfo(detObj: detObj, inputDL: number)
                hasSearched = true

            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    func reset() {
        dlNumber    = ""
        dob         = ""
        dlInfo      = nil
        errorMessage = nil
        hasSearched = false
    }

    // MARK: - Helpers

    static func formatDOBInput(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        var remaining = String(digits.prefix(8))
        guard !remaining.isEmpty else { return "" }

        func consumeSegment(maxFirstDigit: Int) -> String {
            guard let first = remaining.first else { return "" }

            if let value = first.wholeNumberValue, value > maxFirstDigit {
                remaining.removeFirst()
                return "0\(first)"
            }

            guard remaining.count >= 2 else {
                let partial = String(remaining.prefix(1))
                remaining.removeAll()
                return partial
            }

            let segment = String(remaining.prefix(2))
            remaining.removeFirst(2)
            return segment
        }

        let day = consumeSegment(maxFirstDigit: 3)
        let month = remaining.isEmpty ? "" : consumeSegment(maxFirstDigit: 1)
        let year = String(remaining.prefix(4))

        var result = day
        if day.count == 2 {
            result += "-"
        }

        result += month
        if month.count == 2 {
            result += "-"
        }

        result += year
        return result
    }

    // Accepts DD-MM-YYYY from the UI and converts it to the API's YYYY-MM-DD format.
    private func convertDobToAPIFormat(_ dob: String) -> String? {
        guard let date = Self.inputDateFormatter.date(from: dob) else {
            return nil
        }
        return Self.apiDateFormatter.string(from: date)
    }

    private func nonEmpty(_ s: String?) -> String? {
        guard let s = s, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return s
    }

    private func mapToDLInfo(detObj: ULIPSarathiDLDetObj, inputDL: String) -> DLInfo {
        let bio = detObj.bioObj
        let dl  = detObj.dlobj

        let covDetails: [COVDetail] = (detObj.dlcovs ?? []).map { cov in
            COVDetail(
                category:       nonEmpty(cov.vecatg)    ?? "N/A",
                classOfVehicle: nonEmpty(cov.covdesc)   ?? nonEmpty(cov.covabbrv) ?? "N/A",
                issueDate:      nonEmpty(cov.dcIssuedt) ?? "N/A"
            )
        }

        return DLInfo(
            dlNumber:             nonEmpty(dl?.dlLicno)?.trimmingCharacters(in: .whitespaces) ?? inputDL,
            currentStatus:        nonEmpty(dl?.dlStatus)      ?? "N/A",
            holderName:           nonEmpty(bio?.bioFullName)  ?? "N/A",
            oldNewDLNumber:       nonEmpty(dl?.dlOldLicno)    ?? "NA",
            sourceOfData:         "ULIP Sarathi",
            initialIssueDate:     nonEmpty(dl?.dlIssuedt)     ?? "N/A",
            initialIssuingOffice: nonEmpty(dl?.omRtoFullname) ?? "N/A",
            nonTransportFrom:     nonEmpty(dl?.dlNtValdfrDt)  ?? "N/A",
            nonTransportTo:       nonEmpty(dl?.dlNtValdtoDt)  ?? "N/A",
            transportFrom:        nonEmpty(dl?.dlTrValdfrDt)  ?? "NA",
            transportTo:          nonEmpty(dl?.dlTrValdtoDt)  ?? "NA",
            covDetails:           covDetails
        )
    }
}
