import Foundation
import Combine

// MARK: - Parsed data model

struct TSDLData {
    let dlNumber: String
    let fullName: String
    let dateOfBirth: String
    let genderDescription: String
    let bloodGroupName: String
    let qualificationDescription: String
    let swdFullName: String
    let permanentAddress: String
    let temporaryAddress: String
    let mobileNumber: String
    let permanentDistrictName: String
    let temporaryDistrictName: String
    let stateName: String
    let dlStatus: String
    let dlIssueDate: String
    let dlRtoCode: String
    let rtoFullName: String
    let dlTransportValidFrom: String
    let dlTransportValidTo: String
    let dlNonTransportValidFrom: String
    let dlHazardousFrom: String
    let dlHazardousTo: String
    let dlHillFrom: String
    let dlHillTo: String
    let dlEndorseDate: String
    let dlEndorseTime: String
    let covDescription: String
    let covAbbreviation: String
    let covIssueDate: String
    let dlCovStatus: String
    let objectionType: String
}

// MARK: - XML parser

private final class TSDLXMLParser: NSObject, XMLParserDelegate {
    private static let containerElements: Set<String> = ["NewDataSet", "errors", "data"]
    private(set) var values: [String: String] = [:]
    private var currentElement = ""
    private var currentValue   = ""

    func parse(xmlString: String) -> Bool {
        guard let data = xmlString.data(using: .utf8) else { return false }
        let parser = XMLParser(data: data)
        parser.delegate = self
        return parser.parse()
    }

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName _: String?,
                attributes _: [String: String]) {
        currentElement = elementName
        currentValue   = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName _: String?) {
        if !TSDLXMLParser.containerElements.contains(elementName) {
            values[elementName] = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        currentElement = ""
        currentValue   = ""
    }
}

// MARK: - ViewModel

class ULIPTGDLViewModel: ObservableObject {

    @Published var dlNumber: String = "" {
        didSet {
            let u = dlNumber.uppercased()
            if dlNumber != u { dlNumber = u }
        }
    }

    @Published var dlData: TSDLData?      = nil
    @Published var isLoading: Bool        = false
    @Published var errorMessage: String?  = nil
    @Published var hasSearched: Bool      = false

    func search() {
        let number = dlNumber.trimmingCharacters(in: .whitespaces)
        guard !number.isEmpty else { return }

        Task { @MainActor in
            isLoading    = true
            errorMessage = nil
            dlData       = nil
            hasSearched  = false

            do {
                let envelope = try await ULIPTGDLService.shared.getTGDLDetails(dlNumber: number)

                guard let item = envelope.response?.first,
                      item.responseStatus == "SUCCESS",
                      let xmlString = item.response, !xmlString.isEmpty else {
                    let msg = envelope.response?.first?.message ?? envelope.message
                    errorMessage = msg.isEmpty ? "No DL data found." : msg
                    isLoading = false
                    return
                }

                let xmlParser = TSDLXMLParser()
                guard xmlParser.parse(xmlString: xmlString) else {
                    errorMessage = "Could not parse DL data."
                    isLoading = false
                    return
                }

                let v = xmlParser.values
                if v["isError"] == "Y" {
                    let msg = v["errorMessage"] ?? ""
                    errorMessage = msg.isEmpty ? "DL not found." : msg
                    isLoading = false
                    return
                }

                dlData = mapToTSDLData(v, inputNumber: number)
                hasSearched = true

            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    func reset() {
        dlNumber     = ""
        dlData       = nil
        errorMessage = nil
        hasSearched  = false
    }

    // MARK: - Mapping

    private func val(_ dict: [String: String], _ key: String) -> String {
        let v = (dict[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? "N/A" : v
    }

    private func mapToTSDLData(_ v: [String: String], inputNumber: String) -> TSDLData {
        let rawDL = (v["DLNumber"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return TSDLData(
            dlNumber:                rawDL.isEmpty ? inputNumber : rawDL,
            fullName:                val(v, "FullName"),
            dateOfBirth:             val(v, "DateOfBirth"),
            genderDescription:       val(v, "GenderDescription"),
            bloodGroupName:          val(v, "BloodGroupName"),
            qualificationDescription: val(v, "QualificationDescription"),
            swdFullName:             val(v, "SwdFullName"),
            permanentAddress:        val(v, "PermanentAddress"),
            temporaryAddress:        val(v, "TemporaryAddress"),
            mobileNumber:            val(v, "MobileNumber"),
            permanentDistrictName:   val(v, "PermanentDistrictName"),
            temporaryDistrictName:   val(v, "TemporaryDistictName"),
            stateName:               val(v, "StateName"),
            dlStatus:                val(v, "DLStatus"),
            dlIssueDate:             val(v, "DLIssueDate"),
            dlRtoCode:               val(v, "DLRtoCode"),
            rtoFullName:             val(v, "RtoFullName"),
            dlTransportValidFrom:    val(v, "DLTransportValidityfromDate"),
            dlTransportValidTo:      val(v, "DLTransportValidityToDate"),
            dlNonTransportValidFrom: val(v, "DLNonTransportValidityFromDate"),
            dlHazardousFrom:         val(v, "DLHazardasValidityFromDate"),
            dlHazardousTo:           val(v, "DLHazardasValidityToDate"),
            dlHillFrom:              val(v, "DLHillValifityFromDate"),
            dlHillTo:                val(v, "DLHillValidityToDate"),
            dlEndorseDate:           val(v, "DLEndorseDate"),
            dlEndorseTime:           val(v, "DLEndorseTime"),
            covDescription:          val(v, "covDescription"),
            covAbbreviation:         val(v, "covAbbreviation"),
            covIssueDate:            val(v, "covIssueDate"),
            dlCovStatus:             val(v, "DLCovStatus"),
            objectionType:           val(v, "objectionType")
        )
    }
}
