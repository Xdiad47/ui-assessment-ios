import UIKit

/// Renders a driving licence lookup (`ulip/sarathi/01`) as an A4 PDF, mirroring every field
/// [DLInfoView] already shows — nothing here is hardcoded beyond Itzeazy's own branding, same
/// as the challan PDF this shares its rendering engine with.
enum DLPDFService {

    private typealias E = PDFReportEngine

    static func generate(dl: DLInfo) -> Data {
        let bounds = CGRect(x: 0, y: 0, width: E.pageWidth, height: E.pageHeight)

        var pageCount = 1
        _ = UIGraphicsPDFRenderer(bounds: bounds).pdfData { rendererContext in
            let flow = E.PageFlow(context: rendererContext, bounds: bounds, totalPages: 0)
            draw(flow: flow, dl: dl)
            flow.finishPage()
            pageCount = flow.pageCount
        }

        return UIGraphicsPDFRenderer(bounds: bounds).pdfData { rendererContext in
            let flow = E.PageFlow(context: rendererContext, bounds: bounds, totalPages: pageCount)
            draw(flow: flow, dl: dl)
            flow.finishPage()
        }
    }

    private static func draw(flow: E.PageFlow, dl: DLInfo) {
        flow.startPage()
        flow.header(logo: UIImage(named: "itzeazy_logo"), title: "Driving Licence Details")
        flow.identityBlock(
            label: "DL NUMBER",
            value: dl.dlNumber,
            statusText: dl.currentStatus,
            statusBackground: E.Palette.dlStatusBg,
            statusForeground: E.Palette.dlStatusFg
        )

        flow.section("Licence Details")
        flow.grid([
            ("Holder Name", dl.holderName),
            ("Old / New DL No.", dl.oldNewDLNumber),
            ("Source Of Data", dl.sourceOfData)
        ])

        flow.section("Initial Details")
        flow.grid([
            ("Initial Issue Date", dl.initialIssueDate),
            ("Initial Issuing Office", dl.initialIssuingOffice)
        ])

        flow.section("Validity Details")
        flow.grid([
            ("Non-Transport From", dl.nonTransportFrom),
            ("Non-Transport To", dl.nonTransportTo),
            ("Transport From", dl.transportFrom),
            ("Transport To", dl.transportTo)
        ])

        if !dl.covDetails.isEmpty {
            flow.section("Class Of Vehicle Details")
            flow.table(
                dl.covDetails.map { ($0.category, $0.classOfVehicle, $0.issueDate) },
                headers: ("COV CATEGORY", "CLASS OF VEHICLE", "COV ISSUE DATE"),
                col2Width: 160,
                col3Width: 160
            )
        }
    }
}
