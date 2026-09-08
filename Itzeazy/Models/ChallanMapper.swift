import Foundation

/// Shared ULIP eChallan (`ulip/echallan/01`) → UI model mapping.
///
/// Three screens render the same challan data — Vehicle Details, Challan Details and Traffic
/// Challan — fed by two view models (`ULIPChallanViewModel`, `ULIPVehicleViewModel`) that each
/// used to carry their own copy of this mapping, with the same bugs duplicated in both. Keeping
/// it here means a fix lands on every screen at once.
///
/// The gateway is loose about "no value": it returns "" as often as null, uses the literal
/// string "NA" for not-applicable, and only ever mentions the first of a challan's offences in
/// naive mappings. `cleaned` normalises the first; `map` fixes the second by joining every
/// offence rather than taking `.first`.
enum ChallanMapper {

    /// Trimmed value, or nil when the caller meant "nothing": nil, "", the ULIP gateway's
    /// literal "NA", or this app's own "N/A" placeholder used elsewhere for a missing RC
    /// field. Catching both matters for the PDF: a row built from an already-"N/A"-filled
    /// `VehicleRegistrationDetails` field should be dropped, not printed as a literal "N/A".
    static func cleaned(_ s: String?) -> String? {
        guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        let upper = s.uppercased()
        guard upper != "NA", upper != "N/A" else { return nil }
        return s
    }

    /// The rupee amount actually payable. `amount_of_fine_imposed` is the court-compounded
    /// amount and is nil on the large majority of records, so fall back to the statutory
    /// `fine_imposed`. This is the figure the challan cards and the dialog's "FINE AMOUNT"
    /// row show — kept separate from `totalFine`, which is always the statutory amount.
    static func payableAmount(_ e: ULIPChallanEntry) -> Int {
        if let raw = e.amount_of_fine_imposed, let value = Double(raw) { return Int(value) }
        if let raw = e.fine_imposed, let value = Int(raw) { return value }
        return 0
    }

    /// Maps one raw entry to the UI's `Challan`. Returns nil only when the entry has no
    /// challan number at all, since that's the id the rest of the app keys off of.
    static func map(_ e: ULIPChallanEntry, isPending: Bool) -> Challan? {
        guard let no = cleaned(e.challan_no) else { return nil }

        // A challan can carry more than one offence — using only offence_details.first hid
        // every offence after the first. Joined so the popup's single-line fields still show
        // something sensible for the common one-offence case.
        let offences = e.offence_details ?? []
        let offenceName = offences.compactMap { cleaned($0.name) }.joined(separator: "\n")
        let act = offences.compactMap { cleaned($0.act) }.joined(separator: "\n")

        let court = [cleaned(e.court_name), cleaned(e.court_address)]
            .compactMap { $0 }
            .joined(separator: ", ")

        let payable = payableAmount(e)
        let statutory = e.fine_imposed.flatMap { Int($0) } ?? payable

        return Challan(
            id: no,
            title: cleaned(offences.first?.name) ?? "Traffic Violation",
            date: String((cleaned(e.challan_date_time) ?? "").prefix(10)),
            amount: payable,
            // Fall back by which list the entry came from, not a fixed "Pending" — an empty
            // challan_status on a disposed entry was otherwise mislabelled as pending.
            status: cleaned(e.challan_status) ?? (isPending ? "Pending" : "Disposed"),
            challanNo: no,
            dateTime: cleaned(e.challan_date_time) ?? "",
            sentToCourt: cleaned(e.sent_to_reg_court)?.lowercased() == "yes",
            stateCode: cleaned(e.state_code) ?? "",
            offenceName: offenceName,
            act: act,
            processingDate: cleaned(e.date_of_proceeding).map { String($0.prefix(10)) } ?? "",
            rtoDistrict: cleaned(e.rto_distric_name) ?? "",
            courtDetails: court,
            totalFine: statutory
        )
    }
}
