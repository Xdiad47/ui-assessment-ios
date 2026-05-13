import Foundation
import Combine
import SwiftUI

class RTOServiceDetailViewModel: ObservableObject {
    @Published var serviceDetail: RTOServiceDetail

    init(serviceTitle: String, city: String = "Bengaluru") {
        self.serviceDetail = RTOServiceDetailViewModel.detail(for: serviceTitle, city: city)
    }

    // MARK: - Static data catalogue (replace with API call later)
    static func detail(for title: String, city: String) -> RTOServiceDetail {
        switch title {
        case "Duplicate RC":
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "3-5 days",
                documentCollection: "Yes",
                visitRequired: "Yes",
                requiredDocuments: [
                    "Original RC (if partially damaged/mutilated)",
                    "FIR copy from police station (if RC is lost)",
                    "Form 26 – Application for issue of duplicate RC",
                    "Valid insurance certificate",
                    "Valid PUC certificate",
                    "Address proof",
                    "Identity proof",
                    "Applicable fee payment receipt"
                ]
            )
        case "HP Termination":
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "7-10 days",
                documentCollection: "Yes",
                visitRequired: "Yes",
                requiredDocuments: [
                    "Form 35 – Application for termination of HP",
                    "Original RC book",
                    "NOC from the financier",
                    "Valid insurance certificate",
                    "Valid PUC certificate",
                    "Address proof",
                    "Identity proof",
                    "Applicable fee payment receipt"
                ]
            )
        case "RC Transfer":
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "15-20 days",
                documentCollection: "Yes",
                visitRequired: "Yes",
                requiredDocuments: [
                    "Form 29 – Notice of transfer of ownership",
                    "Form 30 – Report of transfer of ownership",
                    "Original RC book",
                    "Valid insurance certificate",
                    "Valid PUC certificate",
                    "Address proof of new owner",
                    "Identity proof of new owner",
                    "NOC from financier (if under HP)",
                    "Applicable fee payment receipt"
                ]
            )
        case "Vehicle NOC":
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "7-14 days",
                documentCollection: "Yes",
                visitRequired: "Yes",
                requiredDocuments: [
                    "Form 28 – Application for NOC",
                    "Original RC book",
                    "Valid insurance certificate",
                    "Valid PUC certificate",
                    "Address proof",
                    "Identity proof",
                    "Tax clearance certificate",
                    "Applicable fee payment receipt"
                ]
            )
        case "Re-registration":
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "15-30 days",
                documentCollection: "Yes",
                visitRequired: "Yes",
                requiredDocuments: [
                    "Form 27 – Application for re-registration",
                    "Original RC book",
                    "NOC from previous state RTO",
                    "Valid insurance certificate",
                    "Valid PUC certificate",
                    "Road tax payment receipt (new state)",
                    "Address proof",
                    "Identity proof"
                ]
            )
        case "New Reg.":
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "5-7 days",
                documentCollection: "Yes",
                visitRequired: "Yes",
                requiredDocuments: [
                    "Form 20 – Application for registration",
                    "Invoice / sale certificate from dealer",
                    "Valid insurance certificate",
                    "PUC certificate",
                    "Address proof",
                    "Identity proof",
                    "Road tax payment receipt",
                    "Applicable fee payment receipt"
                ]
            )
        case "New DL":
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "30 days",
                documentCollection: "Yes",
                visitRequired: "Yes",
                requiredDocuments: [
                    "Form 4 – Application for learner's licence",
                    "Form 2 – Medical certificate",
                    "Age & address proof",
                    "Passport size photographs",
                    "Learner's Licence (LL) copy",
                    "Applicable fee payment receipt"
                ]
            )
        case "DL Renewal":
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "7-15 days",
                documentCollection: "No",
                visitRequired: "Yes",
                requiredDocuments: [
                    "Form 9 – Application for DL renewal",
                    "Original DL",
                    "Form 1A – Medical certificate (for transport vehicle)",
                    "Address proof",
                    "Passport size photographs",
                    "Applicable fee payment receipt"
                ]
            )
        case "Intl. DL":
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "1-3 days",
                documentCollection: "No",
                visitRequired: "Yes",
                requiredDocuments: [
                    "Form 4A – Application for International DL",
                    "Original valid DL",
                    "Valid passport",
                    "Valid visa (of destination country)",
                    "Passport size photographs",
                    "Applicable fee payment receipt"
                ]
            )
        case "Duplicate DL":
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "3-7 days",
                documentCollection: "No",
                visitRequired: "Yes",
                requiredDocuments: [
                    "Form LLD – Application for duplicate DL",
                    "FIR copy (if DL is lost)",
                    "Original DL (if damaged/mutilated)",
                    "Address proof",
                    "Passport size photographs",
                    "Applicable fee payment receipt"
                ]
            )
        case "DL Extract":
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "2-5 days",
                documentCollection: "No",
                visitRequired: "No",
                requiredDocuments: [
                    "Application letter / Form",
                    "Copy of original DL",
                    "Address proof",
                    "Identity proof",
                    "Applicable fee payment receipt"
                ]
            )
        case "Vehicle Fitness":
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "1-2 days",
                documentCollection: "No",
                visitRequired: "Yes",
                requiredDocuments: [
                    "Original RC book",
                    "Valid insurance certificate",
                    "Valid PUC certificate",
                    "Previous fitness certificate (if renewal)",
                    "Tax payment receipt",
                    "Identity proof of owner",
                    "Applicable fee payment receipt"
                ]
            )
        default:
            return RTOServiceDetail(
                serviceTitle: title, city: city,
                processingTime: "5-7 days",
                documentCollection: "Yes",
                visitRequired: "Yes",
                requiredDocuments: [
                    "Required documents will be listed here",
                    "Please contact the RTO office for details"
                ]
            )
        }
    }
}
