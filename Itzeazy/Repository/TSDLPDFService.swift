import UIKit

/// Renders a Telangana driving licence lookup (`ulip/tgsarathi/01`) as an A4 PDF, mirroring
/// every section [TSDLInfoScreen] shows — Personal Details, Address, Licence Details, and
/// Class of Vehicle (COV). Values print exactly as the model holds them (including "N/A"),
/// matching what's already on screen.
enum TSDLPDFService {

    private typealias E = PDFReportEngine

    static func generate(data: TSDLData) -> Data {
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

    private static func draw(flow: E.PageFlow, data d: TSDLData) {
        let isActive = d.dlStatus.uppercased() == "ACTIVE"

        flow.startPage()
        flow.header(logo: UIImage(named: "itzeazy_logo"), title: "TS Driving Licence Details")
        flow.identityBlock(
            label: "DL NUMBER",
            value: d.dlNumber,
            statusText: d.dlStatus,
            statusBackground: isActive ? E.Palette.tsdlActiveBg : E.Palette.tsdlInactiveBg,
            statusForeground: isActive ? E.Palette.tsdlActiveFg : E.Palette.tsdlInactiveFg
        )

        flow.section("Personal Details")
        flow.grid([
            ("Full Name", d.fullName),
            ("Date of Birth", d.dateOfBirth),
            ("Gender", d.genderDescription),
            ("Blood Group", d.bloodGroupName),
            ("Qualification", d.qualificationDescription),
            ("Father / Husband", d.swdFullName),
            ("Mobile", d.mobileNumber)
        ])

        flow.section("Address")
        flow.wideRow(label: "Permanent Address", value: d.permanentAddress)
        flow.grid([("Permanent District", d.permanentDistrictName)])
        flow.wideRow(label: "Temporary Address", value: d.temporaryAddress)
        flow.grid([
            ("Temporary District", d.temporaryDistrictName),
            ("State", d.stateName)
        ])

        flow.section("Licence Details")
        flow.grid([
            ("Issue Date", d.dlIssueDate),
            ("RTO Code", d.dlRtoCode),
            ("RTO Name", d.rtoFullName),
            ("Non-Transport Valid From", d.dlNonTransportValidFrom),
            ("Transport Valid From", d.dlTransportValidFrom),
            ("Transport Valid To", d.dlTransportValidTo),
            ("Hazardous From", d.dlHazardousFrom),
            ("Hazardous To", d.dlHazardousTo),
            ("Hill Valid From", d.dlHillFrom),
            ("Hill Valid To", d.dlHillTo),
            ("Endorsement Date", d.dlEndorseDate),
            ("Endorsement Time", d.dlEndorseTime)
        ])

        flow.section("Class Of Vehicle (COV)")
        flow.grid([
            ("COV Code", d.covAbbreviation),
            ("Description", d.covDescription),
            ("Issue Date", d.covIssueDate),
            ("COV Status", d.dlCovStatus),
            ("Objection", d.objectionType)
        ])
    }
}
