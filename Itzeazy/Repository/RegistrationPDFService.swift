import UIKit

/// Renders a vehicle lookup (`ulip/vahan`) as an A4 "Certificate of Registration" PDF, covering
/// every profile section the Vehicle info screen shows — registration, owner, insurance/PUC and
/// finance/other details. Pending challans are deliberately excluded: each of those already has
/// its own dedicated PDF from [ChallanPDFService], so repeating them here would be redundant.
enum RegistrationPDFService {

    private typealias E = PDFReportEngine

    static func generate(result: VehicleSearchResult) -> Data {
        let bounds = CGRect(x: 0, y: 0, width: E.pageWidth, height: E.pageHeight)

        var pageCount = 1
        _ = UIGraphicsPDFRenderer(bounds: bounds).pdfData { rendererContext in
            let flow = E.PageFlow(context: rendererContext, bounds: bounds, totalPages: 0)
            draw(flow: flow, result: result)
            flow.finishPage()
            pageCount = flow.pageCount
        }

        return UIGraphicsPDFRenderer(bounds: bounds).pdfData { rendererContext in
            let flow = E.PageFlow(context: rendererContext, bounds: bounds, totalPages: pageCount)
            draw(flow: flow, result: result)
            flow.finishPage()
        }
    }

    private static func draw(flow: E.PageFlow, result: VehicleSearchResult) {
        let vehicle = result.registrationDetails
        let owner = result.ownerDetails
        let insurance = result.insuranceDetail
        let puc = result.pucDetail
        let finance = result.financeDetail

        flow.startPage()
        flow.header(logo: UIImage(named: "itzeazy_logo"), title: "Certificate Of Registration")
        flow.identityBlock(
            label: "VEHICLE NO",
            value: vehicle.vehicleNo,
            statusText: vehicle.status,
            statusBackground: E.Palette.rcStatusBg,
            statusForeground: E.Palette.rcStatusFg
        )

        flow.section("Registration Details")
        flow.grid([
            ("Maker", vehicle.maker),
            ("Model", vehicle.model),
            ("Vehicle Class", vehicle.vehicleClass),
            ("Registration Date", vehicle.regDate),
            ("Fitness Upto", vehicle.fitnessUpto),
            ("Colour", vehicle.colour),
            ("Registered At", vehicle.registeredAt),
            ("Fuel Type", vehicle.fuel),
            ("Engine Capacity", vehicle.cc),
            ("Chassis No.", vehicle.chassisNo),
            ("Engine No.", vehicle.engineNo)
        ])

        flow.section("Owner Details")
        flow.grid([
            ("Owner Name", owner.name),
            ("Serial No.", owner.serialNo),
            ("Owner Type", owner.type)
        ])

        flow.section("Insurance & PUC")
        flow.grid([
            ("Insurance Provider", insurance.provider),
            ("Insurance Expiry", insurance.expiryDate),
            ("PUC Status", puc.validStatus)
        ])

        flow.section("Other Details")
        flow.grid([
            ("Finance Status", finance.financeStatus),
            ("Blacklist Status", finance.blacklistStatus),
            ("NOC Details", finance.nocDetails)
        ])
    }
}
