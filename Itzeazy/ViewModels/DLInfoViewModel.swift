import Foundation
import Combine

class DLInfoViewModel: ObservableObject {
    @Published var dlNumber: String = ""
    @Published var dob: String = ""

    @Published var isLoading: Bool = false
    @Published var dlInfo: DLInfo? = DLInfo(
        dlNumber: "HR-2620120142433",
        currentStatus: "ACTIVE",
        holderName: "MTL* TYL",
        oldNewDLNumber: "NA",
        sourceOfData: "Sarathi",
        initialIssueDate: "05-Dec-2012",
        initialIssuingOffice: "05-Dec-2012",
        nonTransportFrom: "05Dec-2012",
        nonTransportTo: "05-Sep-2026",
        transportFrom: "NA",
        transportTo: "NA",
        covDetails: [
            COVDetail(category: "NT", classOfVehicle: "LMV", issueDate: "05-DEC-2012"),
            COVDetail(category: "NT", classOfVehicle: "MCWOG", issueDate: "05-DEC-2012")
        ]
    )

    func getDetails() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            self.dlInfo = DLInfo(
                dlNumber: self.dlNumber.isEmpty ? "HR-2620120142433" : self.dlNumber,
                currentStatus: "ACTIVE",
                holderName: "MTL* TYL",
                oldNewDLNumber: "NA",
                sourceOfData: "Sarathi",
                initialIssueDate: "05-Dec-2012",
                initialIssuingOffice: "05-Dec-2012",
                nonTransportFrom: "05Dec-2012",
                nonTransportTo: "05-Sep-2026",
                transportFrom: "NA",
                transportTo: "NA",
                covDetails: [
                    COVDetail(category: "NT", classOfVehicle: "LMV", issueDate: "05-DEC-2012"),
                    COVDetail(category: "NT", classOfVehicle: "MCWOG", issueDate: "05-DEC-2012")
                ]
            )
        }
    }
}
