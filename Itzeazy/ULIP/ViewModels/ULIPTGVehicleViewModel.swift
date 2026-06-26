import Foundation
import Combine

// MARK: - Parsed data model

struct TSVehicleData {
    let regNo: String
    let ownerName: String
    let fatherName: String
    let presentAddress: String
    let permanentAddress: String
    let mobileNo: String
    let registrationDate: String
    let chassisNo: String
    let engineNo: String
    let vehicleClass: String
    let makerName: String
    let modelDesc: String
    let bodyType: String
    let fuel: String
    let color: String
    let fcValidity: String
    let taxValidity: String
    let financerName: String
    let insuranceCompany: String
    let insuranceNo: String
    let insuranceValidity: String
    let issuePlace: String
    let rcStatus: String
    let makeYear: String
    let cubicCapacity: String
    let seatingCapacity: String
    let vehicleType: String
    let puccValidFrom: String
    let puccValidTo: String
    let permitNo: String
    let permitValidity: String
    let permitType: String
    let classID: String
    let theftStatus: String
    let rcValidUpto: String
    let ownerSerialNo: String
    let wheelBase: String
    let ulw: String
    let gvw: String
}

// MARK: - XML parser

private final class TSVehicleXMLParser: NSObject, XMLParserDelegate {
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
        if elementName != "vehicleDetails" {
            values[elementName] = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        currentElement = ""
        currentValue   = ""
    }
}

// MARK: - ViewModel

class ULIPTGVehicleViewModel: ObservableObject {

    @Published var vehicleNumber: String = "" {
        didSet {
            let u = vehicleNumber.uppercased()
            if vehicleNumber != u { vehicleNumber = u }
        }
    }

    @Published var vehicleData: TSVehicleData? = nil
    @Published var isLoading: Bool    = false
    @Published var errorMessage: String? = nil
    @Published var hasSearched: Bool  = false

    func search() {
        let number = vehicleNumber.trimmingCharacters(in: .whitespaces)
        guard !number.isEmpty else { return }

        Task { @MainActor in
            isLoading    = true
            errorMessage = nil
            vehicleData  = nil
            hasSearched  = false

            do {
                let envelope = try await ULIPTGVehicleService.shared.getTGVehicleDetails(vehicleNumber: number)

                guard let item = envelope.response?.first,
                      item.responseStatus == "SUCCESS",
                      let xmlString = item.response, !xmlString.isEmpty else {
                    let msg = envelope.response?.first?.message ?? envelope.message
                    errorMessage = msg.isEmpty ? "No vehicle data found." : msg
                    isLoading = false
                    return
                }

                let xmlParser = TSVehicleXMLParser()
                guard xmlParser.parse(xmlString: xmlString) else {
                    errorMessage = "Could not parse vehicle data."
                    isLoading = false
                    return
                }

                let v = xmlParser.values
                if v["isError"] == "Y" {
                    let msg = v["errorMessage"] ?? ""
                    errorMessage = msg.isEmpty ? "Vehicle not found." : msg
                    isLoading = false
                    return
                }

                vehicleData = mapToTSVehicleData(v, inputNumber: number)
                hasSearched = true

            } catch {
                errorMessage = error.localizedDescription
            }

            isLoading = false
        }
    }

    func reset() {
        vehicleNumber = ""
        vehicleData   = nil
        errorMessage  = nil
        hasSearched   = false
    }

    // MARK: - Mapping

    private func val(_ dict: [String: String], _ key: String) -> String {
        let v = (dict[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? "N/A" : v
    }

    private func nonEmpty(_ s: String?) -> String? {
        guard let s = s, !s.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return s
    }

    private func mapToTSVehicleData(_ v: [String: String], inputNumber: String) -> TSVehicleData {
        TSVehicleData(
            regNo:             nonEmpty(v["Regn_No"])          ?? inputNumber,
            ownerName:         val(v, "Owner_Name"),
            fatherName:        val(v, "FatherName"),
            presentAddress:    val(v, "PresentAddress"),
            permanentAddress:  val(v, "PermanentAddress"),
            mobileNo:          val(v, "Mobile_No"),
            registrationDate:  val(v, "RegistrationDate"),
            chassisNo:         val(v, "Chassis_No"),
            engineNo:          val(v, "Engine_No"),
            vehicleClass:      val(v, "Vehicle_Classdesc"),
            makerName:         val(v, "Maker_Name"),
            modelDesc:         val(v, "Model_Desc"),
            bodyType:          val(v, "Body_Type"),
            fuel:              val(v, "Fuel"),
            color:             val(v, "Color"),
            fcValidity:        val(v, "FC_Validity"),
            taxValidity:       val(v, "Tax_Validity"),
            financerName:      val(v, "FinancerName"),
            insuranceCompany:  val(v, "Insurance_CmpyName"),
            insuranceNo:       val(v, "Insurance_No"),
            insuranceValidity: val(v, "Insurance_Validity"),
            issuePlace:        val(v, "IssuePlace"),
            rcStatus:          val(v, "RcStatus"),
            makeYear:          val(v, "Make_Yr"),
            cubicCapacity:     val(v, "CubicCapacity"),
            seatingCapacity:   val(v, "SeatingCapacity"),
            vehicleType:       val(v, "VehicleType"),
            puccValidFrom:     val(v, "PUCCVALIDFROM"),
            puccValidTo:       val(v, "PUCCVALIDTO"),
            permitNo:          val(v, "PERMITNO"),
            permitValidity:    val(v, "Permit_Validity"),
            permitType:        val(v, "PERMIT_TYPE"),
            classID:           val(v, "Vehicle_ClassID"),
            theftStatus:       val(v, "TheftStatus"),
            rcValidUpto:       val(v, "RCValid_Upto"),
            ownerSerialNo:     val(v, "OwnerSerialNo"),
            wheelBase:         val(v, "WheelBase"),
            ulw:               val(v, "ULW"),
            gvw:               val(v, "GVW")
        )
    }
}
