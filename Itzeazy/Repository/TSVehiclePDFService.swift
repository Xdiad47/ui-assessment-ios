import UIKit

/// Renders a Telangana vehicle lookup (`ulip/tgvahan/01`) as an A4 PDF, mirroring every section
/// [TSVehicleScreen] actually shows on iOS — Vehicle/Header, Registration, Owner, Insurance,
/// PUC always; Permit Details only when the screen would show it too (`permitNo != "N/A"`).
/// Values print exactly as the model holds them (including "N/A"), matching what's already on
/// screen rather than hiding fields — the same convention DLPDFService uses.
enum TSVehiclePDFService {

    private typealias E = PDFReportEngine

    static func generate(data: TSVehicleData) -> Data {
        let bounds = CGRect(x: 0, y: 0, width: E.pageWidth, height: E.pageHeight)

        var pageCount = 1
        _ = UIGraphicsPDFRenderer(bounds: bounds).pdfData { rendererContext in
            let flow = E.PageFlow(context: rendererContext, bounds: bounds, totalPages: 0)
            draw(flow: flow, data: data)
            flow.finishPage()
            pageCount = flow.pageCount
        }

        return UIGraphicsPDFRenderer(bounds: bounds).pdfData { rendererContext in
            let flow = E.PageFlow(context: rendererContext, bounds: bounds, totalPages: pageCount)
            draw(flow: flow, data: data)
            flow.finishPage()
        }
    }

    private static func draw(flow: E.PageFlow, data d: TSVehicleData) {
        flow.startPage()
        flow.header(logo: UIImage(named: "itzeazy_logo"), title: "TS Vehicle Details")
        flow.identityBlock(
            label: "REGISTRATION NO",
            value: d.regNo,
            statusText: d.rcStatus,
            statusBackground: E.Palette.rcStatusBg,
            statusForeground: E.Palette.rcStatusFg
        )

        flow.section("Registration Details")
        flow.grid([
            ("Vehicle Class", d.vehicleClass),
            ("Maker", d.makerName),
            ("Model", d.modelDesc),
            ("Registration Date", d.registrationDate),
            ("RC Valid Upto", d.rcValidUpto),
            ("Colour", d.color),
            ("Issue Place", d.issuePlace),
            ("Fuel", d.fuel),
            ("Cubic Capacity", d.cubicCapacity),
            ("Body Type", d.bodyType),
            ("Make Year", d.makeYear),
            ("Vehicle Type", d.vehicleType),
            ("Seating Capacity", d.seatingCapacity),
            ("Chassis No.", d.chassisNo),
            ("Engine No.", d.engineNo),
            ("FC Validity", d.fcValidity),
            ("Tax Validity", d.taxValidity)
        ])

        flow.section("Owner Details")
        flow.grid([
            ("Owner Name", d.ownerName),
            ("Owner Serial No.", d.ownerSerialNo),
            ("Father Name", d.fatherName),
            ("Present Address", d.presentAddress),
            ("Permanent Address", d.permanentAddress),
            ("Mobile No.", d.mobileNo)
        ])

        flow.section("Insurance")
        flow.grid([
            ("Insurance Company", d.insuranceCompany),
            ("Policy No.", d.insuranceNo),
            ("Expiry", d.insuranceValidity)
        ])

        flow.section("PUC Detail")
        flow.grid([
            ("Valid From", d.puccValidFrom),
            ("Valid To", d.puccValidTo)
        ])

        if d.permitNo != "N/A" {
            let vehicleTypeDisplay: String
            switch d.vehicleType {
            case "T": vehicleTypeDisplay = "T (Transport)"
            case "N": vehicleTypeDisplay = "N (Non-Transport)"
            default: vehicleTypeDisplay = d.vehicleType
            }

            flow.section("Permit Details")
            flow.grid([
                ("Permit No.", d.permitNo),
                ("Permit Type", d.permitType),
                ("Permit Valid Upto", d.permitValidity),
                ("Vehicle Type", vehicleTypeDisplay),
                ("Class ID", d.classID)
            ])
        }
    }
}
