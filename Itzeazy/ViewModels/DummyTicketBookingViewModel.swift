import Foundation
import Combine

enum DummyTicketServiceType: String, CaseIterable, Identifiable {
    case flight = "FLIGHT"
    case hotel = "HOTEL"
    case both = "BOTH"

    var id: String { rawValue }
}

enum DummyTicketTripType: String, CaseIterable, Identifiable {
    case oneWay = "ONE WAY"
    case roundTrip = "ROUND TRIP"
    case multiTrip = "MULTI TRIP"

    var id: String { rawValue }
}

/// Hotel's own "Select Trip Type" equivalent (Figma node 3497:6972) — a hotel stay has no
/// one-way/round-trip/multi-trip concept, so this is a separate enum from DummyTicketTripType
/// rather than a repurposing of it.
enum DummyTicketStayType: String, CaseIterable, Identifiable {
    case single = "Single Stay"
    case couple = "Couple Stay"
    case family = "Family Stay"

    var id: String { rawValue }
}

/// Hotel Personal Details' own "Stay Preferences" section (Figma node 3497:7146) — has no Flight
/// equivalent.
enum DummyTicketSmokingPreference: String, CaseIterable, Identifiable {
    case nonSmoking = "Non-Smoking"
    case smoking = "Smoking"

    var id: String { rawValue }
}

enum DummyTicketBedConfiguration: String, CaseIterable, Identifiable {
    case kingBed = "King Bed"
    case twinBeds = "Twin Beds"

    var id: String { rawValue }
}

/// Hotel Additional Details' own "Delivery Method" section (Figma node 3497:7346) — has no Flight
/// equivalent (Flight has separate WhatsApp/Email PDF copy toggles instead of one exclusive choice).
enum DummyTicketDeliveryMethod: String, CaseIterable, Identifiable {
    case email = "Email"
    case whatsapp = "WhatsApp"

    var id: String { rawValue }
}

/// One passenger added via Personal Details' "+ Add Passenger" — Passenger 1's own fields stay
/// as separate top-level @Published properties on DummyTicketBookingViewModel (unchanged, so
/// Review Booking / editPersonal() / passengerName / phoneNumber all keep working exactly as
/// before); this only models passengers 2+.
struct DummyTicketPassenger: Identifiable {
    let id = UUID()
    var title: String = "Mr."
    var firstName: String = ""
    var lastName: String = ""
    var dateOfBirth: Date? = nil
    var gender: String = "Male"
    var passportNumber: String = ""
    var nationality: CountryInfo = countries.first(where: { $0.isoCode == "IN" }) ?? countries[0]
}

/// One guest added via Hotel Personal Details' "Add Guest +" — same idea as DummyTicketPassenger,
/// but without `gender`: Figma's Guest card has no gender field (Nationality shares DOB's row
/// instead), so this is its own struct rather than reusing DummyTicketPassenger with an unused field.
struct DummyTicketGuest: Identifiable {
    let id = UUID()
    var title: String = "Mr."
    var firstName: String = ""
    var lastName: String = ""
    var dateOfBirth: Date? = nil
    var passportNumber: String = ""
    var nationality: CountryInfo = countries.first(where: { $0.isoCode == "IN" }) ?? countries[0]
}

// MARK: - DummyTicketBookingViewModel
// Single shared source of truth for the whole 5-step Dummy Tickets flow (Initial -> Route Details
// -> Personal Details -> Additional Details -> Review Booking -> Payment), created once in
// DummyTicketInitialView and handed down via .environmentObject() so every pushed screen reads
// and writes the SAME fields instead of a private copy.
//
// This replaces the old approach of each screen owning local @State and passing a snapshot of it
// forward as init parameters to the next screen — that worked for a linear "keep going forward"
// flow, but it meant an edit made after going back could never be reflected on a screen further
// along, and "Edit" had nowhere real to send the user. Also owns the flow's own navigation state
// (the showXxx flags below) for the same reason: with every NavigationLink's isActive bound to a
// flag on this one shared object, "Edit" can collapse the whole stack back to a specific earlier
// screen in one synchronous change, instead of needing a chain of dismiss() calls threaded through
// every intermediate screen (which the legacy NavigationLink(isActive:) API can't do on its own).
@MainActor
final class DummyTicketBookingViewModel: ObservableObject {
    // MARK: Navigation (drives every screen's NavigationLink(isActive:) in the flow)
    @Published var showRouteDetails = false
    @Published var showPersonalDetails = false
    @Published var showAdditionalDetails = false
    @Published var showReviewBooking = false
    @Published var showPayment = false
    @Published var showConfirmation = false

    /// Set true once, right before DummyTicketInitialView is asked to dismiss itself — see
    /// returnHome() below.
    @Published var returnHomeRequested = false

    /// The Flight confirmation screen's "Booking ID: #DT-XXXXX" — generated once when payment
    /// succeeds (not per-render) so it stays the same if the user navigates away and back.
    @Published var bookingReference: String? = nil

    /// The Hotel confirmation screen's "BOOKING ID #ITZ-HXXX-XXX" (Figma node 3497:7780) — a
    /// distinct format from Flight's, kept as its own field rather than reusing bookingReference.
    @Published var hotelBookingReference: String? = nil

    private static func generateBookingReference() -> String {
        "DT-\(Int.random(in: 10000...99999))"
    }

    private static func generateHotelBookingReference() -> String {
        "ITZ-H\(Int.random(in: 100...999))-\(Int.random(in: 100...999))"
    }

    /// Called by Payment's "Make Payment" button — generates the booking reference (once, in
    /// whichever format this booking's service type uses) and pushes the confirmation screen.
    func confirmBooking() {
        switch selectedServiceType {
        case .hotel:
            if hotelBookingReference == nil {
                hotelBookingReference = Self.generateHotelBookingReference()
            }
        case .flight, .both:
            if bookingReference == nil {
                bookingReference = Self.generateBookingReference()
            }
        }
        showConfirmation = true
    }

    /// Collapses the stack back to Route Details — used by Review Booking's "Route Information" Edit.
    func editRoute() {
        popStack([\.showPayment, \.showReviewBooking, \.showAdditionalDetails, \.showPersonalDetails])
    }

    /// Collapses the stack back to Personal Details — used by Review Booking's "Passenger
    /// Information" and "Contact Details" Edit links (both live on that same screen).
    func editPersonal() {
        popStack([\.showPayment, \.showReviewBooking, \.showAdditionalDetails])
    }

    /// Collapses the stack back to Additional Details — used by Review Booking's "Preferences" Edit links.
    func editAdditional() {
        popStack([\.showPayment, \.showReviewBooking])
    }

    /// Unwinds the ENTIRE flow back to HomeView — used by Confirmation's "Back Home" button.
    /// Collapses every pushed screen's isActive flag back to Route Details (same staged mechanism
    /// as editRoute()), then, once that settles, flips returnHomeRequested — DummyTicketInitialView
    /// observes that flag and calls its own presentationMode.dismiss() at that point, which is the
    /// one dismiss() call that's actually well-defined (it's the current top of the stack by then).
    func returnHome() {
        let flags: [ReferenceWritableKeyPath<DummyTicketBookingViewModel, Bool>] = [
            \.showConfirmation, \.showPayment, \.showReviewBooking, \.showAdditionalDetails, \.showPersonalDetails, \.showRouteDetails
        ]
        popStack(flags)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(flags.count) * 0.45) { [weak self] in
            self?.returnHomeRequested = true
        }
    }

    /// Flips each flag to false one at a time, current screen first, with a short delay between
    /// steps — not all at once. The legacy `NavigationLink(isActive:)` pop mechanism this whole
    /// flow relies on turned out to only reliably pop ONE level when several isActive bindings
    /// flip to false in the same instant: editPersonal()'s 2-level unwind (Additional Details +
    /// Review Booking) worked, but editRoute()'s 3-level unwind (+ Personal Details) silently
    /// stalled after the first pop. Staggering each flip gives the previous pop's transition time
    /// to actually settle before the next one is triggered, which is the standard workaround for
    /// this exact limitation. The delay roughly matches a standard push/pop transition duration.
    private func popStack(_ flags: [ReferenceWritableKeyPath<DummyTicketBookingViewModel, Bool>]) {
        for (index, flag) in flags.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.45) { [weak self] in
                self?[keyPath: flag] = false
            }
        }
    }

    // MARK: Route Details (step 1) — Flight fields
    @Published var fromLocation: String = ""
    @Published var toLocation: String = ""
    @Published var departureDate: Date? = nil
    @Published var selectedServiceType: DummyTicketServiceType = .flight
    @Published var selectedTripType: DummyTicketTripType = .oneWay

    // MARK: Route Details (step 1) — Hotel fields (Figma nodes 3497:6908, 3497:6972)
    @Published var hotelCity: String = ""
    @Published var checkInDate: Date? = nil
    @Published var checkOutDate: Date? = nil
    @Published var selectedStayType: DummyTicketStayType = .single
    @Published var hotelCategory: String = "5 Star"
    @Published var roomsCount: Int = 1
    @Published var guestsCount: Int = 2

    // MARK: Personal Details (step 2)
    @Published var mobileCountry: CountryInfo = countries.first(where: { $0.isoCode == "IN" }) ?? countries[0]
    @Published var mobileNumber: String = ""
    @Published var emailAddress: String = ""
    @Published var title: String = "Mr."
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var dateOfBirth: Date? = nil
    @Published var gender: String = "Male"
    @Published var passportNumber: String = ""
    @Published var nationality: CountryInfo = countries.first(where: { $0.isoCode == "IN" }) ?? countries[0]

    /// Passengers 2+, added via Personal Details' "+ Add Passenger". Each renders as its own
    /// "Passenger N" card below the main Passenger 1 card.
    @Published var additionalPassengers: [DummyTicketPassenger] = []

    func addPassenger() {
        additionalPassengers.append(DummyTicketPassenger())
    }

    func removePassenger(_ id: DummyTicketPassenger.ID) {
        additionalPassengers.removeAll { $0.id == id }
    }

    // MARK: Personal Details (step 2) — Hotel fields (Figma node 3497:7146)
    // "Guest 1 (Primary)" reuses the Flight fields directly above (title/firstName/lastName/
    // dateOfBirth/nationality/passportNumber) — this screen just doesn't show `gender` for it,
    // since Figma's Guest card has no gender field. Guests 2+ use their own DummyTicketGuest
    // (below), not DummyTicketPassenger, for the same reason.
    @Published var smokingPreference: DummyTicketSmokingPreference = .nonSmoking
    @Published var bedConfiguration: DummyTicketBedConfiguration = .kingBed
    @Published var additionalGuests: [DummyTicketGuest] = []

    func addGuest() {
        additionalGuests.append(DummyTicketGuest())
    }

    func removeGuest(_ id: DummyTicketGuest.ID) {
        additionalGuests.removeAll { $0.id == id }
    }

    // MARK: Additional Details (step 3)
    @Published var travelPurpose: String? = nil
    @Published var specialInstructions: String = ""
    @Published var sendWhatsAppCopy: Bool = false
    @Published var sendEmailPDFCopy: Bool = true
    @Published var isUrgentProcessing: Bool = true

    // MARK: Additional Details (step 3) — Hotel fields (Figma node 3497:7346)
    @Published var hotelWantsFreeBreakfast: Bool = true
    @Published var hotelWantsHighSpeedWiFi: Bool = true
    @Published var hotelWantsRefundable: Bool = false
    @Published var hotelWantsNearCenter: Bool = false
    @Published var estimatedArrivalTime: Date = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var deliveryMethod: DummyTicketDeliveryMethod = .email
    @Published var hotelSpecialRequests: String = ""
    @Published var agreedToHotelTerms: Bool = false

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var estimatedArrivalTimeText: String {
        Self.timeFormatter.string(from: estimatedArrivalTime)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    var departureDateText: String {
        guard let departureDate else { return "Departure Date" }
        return Self.dateFormatter.string(from: departureDate)
    }

    var checkInDateText: String {
        guard let checkInDate else { return "Check In Date" }
        return Self.dateFormatter.string(from: checkInDate)
    }

    var checkOutDateText: String {
        guard let checkOutDate else { return "Check Out Date" }
        return Self.dateFormatter.string(from: checkOutDate)
    }

    private static let stayRangeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let stayRangeYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    /// "May 22 - May 26, 2026" — used by the Hotel Summary card.
    var stayDateRangeText: String {
        guard let checkInDate, let checkOutDate else { return "—" }
        let year = Self.stayRangeYearFormatter.string(from: checkOutDate)
        return "\(Self.stayRangeFormatter.string(from: checkInDate)) - \(Self.stayRangeFormatter.string(from: checkOutDate)), \(year)"
    }

    /// "May 22 - May 26" — same as stayDateRangeText but without the year, for the Hotel Review
    /// Booking card, which shows dates without a year (matching Route Details' own shorter style).
    var stayDateRangeShortText: String {
        guard let checkInDate, let checkOutDate else { return "—" }
        return "\(Self.stayRangeFormatter.string(from: checkInDate)) - \(Self.stayRangeFormatter.string(from: checkOutDate))"
    }

    /// Nights between check-in and check-out — used by Review Booking's "Base Fare (N Nights)" line.
    var stayNights: Int {
        guard let checkInDate, let checkOutDate else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: checkInDate, to: checkOutDate).day ?? 0)
    }

    /// "2 adults" — used by the Hotel Details card's Guests field and the Hotel Summary card.
    var guestsText: String {
        "\(guestsCount) adult\(guestsCount == 1 ? "" : "s")"
    }

    var isRouteDetailsSubmitEnabled: Bool {
        switch selectedServiceType {
        case .flight:
            return !fromLocation.trimmingCharacters(in: .whitespaces).isEmpty
                && !toLocation.trimmingCharacters(in: .whitespaces).isEmpty
                && departureDate != nil
        case .hotel:
            return !hotelCity.trimmingCharacters(in: .whitespaces).isEmpty
                && checkInDate != nil
                && checkOutDate != nil
        case .both:
            // BOTH's initial-screen card (Figma node 3497:8105) collects Flight's FROM/TO/
            // DEPARTURE and Hotel's CITY/CHECK IN/CHECK OUT together, so submit needs all six.
            return !fromLocation.trimmingCharacters(in: .whitespaces).isEmpty
                && !toLocation.trimmingCharacters(in: .whitespaces).isEmpty
                && departureDate != nil
                && !hotelCity.trimmingCharacters(in: .whitespaces).isEmpty
                && checkInDate != nil
                && checkOutDate != nil
        }
    }

    var passengerName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var phoneNumber: String {
        "\(mobileCountry.phoneCode) \(mobileNumber)"
    }
}
