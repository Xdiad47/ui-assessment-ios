import SwiftUI

// MARK: - DummyTicketBothRouteDetailsView
// Figma: "Route Details" (node 3497:8211) — the Both flow's own step 1, reached from
// DummyTicketInitialView's BUY DUMMY TICKET button when BOTH is selected. Unlike Flight's and
// Hotel's own Route Details screens (each an editable recap/form for a single service), this one is
// a read-only combined recap of both: a Flight Selection card, a Stay Preferences card, and a
// Booking Summary card totaling both services' fees. NEXT continues to
// DummyTicketBothPersonalDetailsView (Both's own step 2, node 3497:8738).
//
// Data honesty: the OUTBOUND route (booking.fromLocation/toLocation), TRAVEL DATE
// (booking.departureDateText), hotel location (booking.hotelCity), CHECK-IN/CHECK-OUT dates
// (booking.checkInDate/checkOutDate), and the guests/rooms line (booking.guestsCount/roomsCount —
// whose defaults of 2/1 already match this exact Figma frame's own "2 Adults • 1 Room" sample) all
// read live values already collected on the Initial screen. Airline/flight-number
// ("IndiGo • 6E-2032"), the flight time range ("06:30 — 08:45"), baggage allowance, the hotel's own
// property name ("The Oberoi Waterfront"), and check-in/check-out clock times (2:00 PM/11:00 AM —
// which happens to match booking.estimatedArrivalTime's own already-established 2:00 PM default
// elsewhere in this flow) have no live source anywhere in this app (no flight-search or
// hotel-search step exists), so they stay as Figma's own fixed illustrative values, same treatment
// every other screen in this flow already gives amounts/details with no live data source.
//
// "Edit Preferences" just dismisses back to the Initial screen — that's the only place BOTH's
// hotel City/Check In/Check Out fields are actually editable, since (unlike the Hotel-only flow)
// there's no separate Hotel Route Details screen in this combined flow.
//
// The Booking Summary's total was recomputed (₹499 + ₹499 + ₹180 = ₹1,178) rather than copied
// verbatim — Figma's own printed total ("₹1,11,78") doesn't parse as any real amount, almost
// certainly a copy/paste artifact in the design file. The ₹499-per-service fee matches the Hero
// heading's own "Get Your Dummy Ticket At ₹499" pricing — a different, shallower number than the
// Base Fare/GST amounts Flight's/Hotel's own Review Booking screens show further into the flow
// (those represent the fake underlying booking cost printed on the ticket for visa proof; this is
// Itzeazy's own service fee for generating it).

struct DummyTicketBothRouteDetailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let mutedGray = Color(red: 0.373, green: 0.369, blue: 0.369)
    private let dimText = Color(red: 0.714, green: 0.714, blue: 0.722)
    private let lightFill = Color(red: 0.953, green: 0.957, blue: 0.961)
    private let confirmedGreen = Color(red: 0.086, green: 0.502, blue: 0.239)

    // Fixed placeholder fees — see top comment for why these differ from Flight's/Hotel's own
    // deeper Base Fare/GST amounts.
    private let flightFee = "₹499"
    private let hotelFee = "₹499"
    private let taxesText = "₹180"
    private let totalText = "₹1,178"

    private static let cardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private var checkInDisplayText: String {
        guard let checkInDate = booking.checkInDate else { return "—" }
        return "\(Self.cardDateFormatter.string(from: checkInDate)), 2:00 PM"
    }

    private var checkOutDisplayText: String {
        guard let checkOutDate = booking.checkOutDate else { return "—" }
        return "\(Self.cardDateFormatter.string(from: checkOutDate)), 11:00 AM"
    }

    private var guestsRoomsText: String {
        "\(booking.guestsCount) Adult\(booking.guestsCount == 1 ? "" : "s") • \(booking.roomsCount) Room\(booking.roomsCount == 1 ? "" : "s")"
    }

    private var routeOriginText: String {
        booking.fromLocation.isEmpty ? "—" : booking.fromLocation
    }

    private var routeDestinationText: String {
        booking.toLocation.isEmpty ? "—" : booking.toLocation
    }

    // Airport-code style for the Flight Selection card's own OUTBOUND line only ("DEL → BOM" in
    // Figma) — matches the same deterministic first-three-letters-uppercased derivation
    // DummyTicketPersonalDetailsView's own Flight Summary card already uses (no real IATA lookup
    // exists upstream). The Booking Summary card below keeps the full city name via
    // routeOriginText/routeDestinationText — that card isn't "Flight Selection," so it's out of
    // scope for this.
    private static func airportCode(for city: String) -> String {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "—" }
        return String(trimmed.prefix(3)).uppercased()
    }

    private var outboundRouteCodeText: String {
        "\(Self.airportCode(for: booking.fromLocation)) → \(Self.airportCode(for: booking.toLocation))"
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    header(safeAreaTop: proxy.safeAreaInsets.top)

                    ScrollView(showsIndicators: false) {
                        content
                    }
                    .frame(maxHeight: .infinity)
                }

                NavigationLink(
                    destination: DummyTicketBothPersonalDetailsView().environmentObject(booking),
                    isActive: $booking.showPersonalDetails
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .ignoresSafeArea(edges: .vertical)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header (back row + 5-step progress)

    private func header(safeAreaTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            darkCard.frame(height: safeAreaTop)

            HStack(spacing: 6) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Back")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .tracking(-0.9)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .frame(height: 50)

            flowStepper
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .background(darkCard)
        .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
    }

    // Labeled "Passenger Details" for step 2, not "Guest Details" — matches this specific Figma
    // frame, and Flight's wording is the more natural fit for a combined flight+hotel booking.
    private var flowStepper: some View {
        let currentStep = 1
        let steps: [(number: Int, label: String)] = [
            (1, "Route\nDetails"),
            (2, "Passenger\nDetails"),
            (3, "Additional\nDetails"),
            (4, "Review\nBooking"),
            (5, "Payment")
        ]

        return HStack(alignment: .top, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(step.number <= currentStep ? brandRed : Color(red: 0.906, green: 0.910, blue: 0.914))
                            .frame(width: 28, height: 28)
                        if step.number <= currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step.number)")
                                .font(Font.custom("PlusJakartaSans-Bold", size: 12))
                                .foregroundColor(Color(red: 0.373, green: 0.369, blue: 0.369))
                        }
                    }
                    Text(step.label)
                        .font(Font.custom("PlusJakartaSans-Bold", size: 9))
                        .foregroundColor(step.number <= currentStep ? .white : Color(red: 0.792, green: 0.792, blue: 0.792))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize()
                }
                .frame(maxWidth: .infinity)

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(step.number < currentStep ? brandRed : Color(red: 0.929, green: 0.933, blue: 0.937))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                }
            }
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Route Details")
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .tracking(-0.75)
                .foregroundColor(darkText)

            flightSelectionCard
            stayPreferencesCard
            bookingSummaryCard
            nextButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(24, tabBarState.height + 16))
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Flight Selection card

    private var flightSelectionCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "airplane")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text("Flight Selection")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 45)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(darkCard)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OUTBOUND")
                            .font(Font.custom("Inter-Bold", size: 10))
                            .tracking(1)
                            .foregroundColor(mutedGray)
                        Text(outboundRouteCodeText)
                            .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                            .foregroundColor(darkText)
                        Text("IndiGo • 6E-2032")
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(mutedGray)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(booking.departureDateText)
                            .font(Font.custom("Inter-Bold", size: 14))
                            .foregroundColor(darkText)
                        Text("06:30 — 08:45")
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(mutedGray)
                    }
                }

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(lightFill)
                            .frame(width: 32, height: 32)
                        Image(systemName: "bag.fill")
                            .font(.system(size: 13))
                            .foregroundColor(darkText)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Checked-in Baggage")
                            .font(Font.custom("Inter-Bold", size: 12))
                            .foregroundColor(darkText)
                        Text("15kg included")
                            .font(Font.custom("Inter", size: 10))
                            .foregroundColor(mutedGray)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundColor(confirmedGreen)
                }
                .padding(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor.opacity(0.6), lineWidth: 0.6))
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stay Preferences card

    private var stayPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text("Stay Preferences")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 45)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(darkCard)

            ZStack(alignment: .topLeading) {
                Image("hotel_review_photo")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 160)
                    .clipped()

                Text("HIGHLY RATED")
                    .font(Font.custom("Inter-Bold", size: 10))
                    .tracking(-0.5)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(brandRed.opacity(0.92))
                    .clipShape(Capsule())
                    .padding(12)
            }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("The Oberoi Waterfront")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                        .foregroundColor(darkText)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(mutedGray)
                        Text(booking.hotelCity.isEmpty ? "—" : booking.hotelCity)
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(mutedGray)
                    }
                }

                HStack(spacing: 12) {
                    stayDateBox(label: "CHECK-IN", value: checkInDisplayText)
                    stayDateBox(label: "CHECK-OUT", value: checkOutDisplayText)
                }

                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 13))
                            .foregroundColor(darkText)
                        Text(guestsRoomsText)
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(darkText)
                    }
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Edit Preferences")
                            .font(Font.custom("Inter-Bold", size: 12))
                            .foregroundColor(brandRed)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func stayDateBox(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 10))
                .foregroundColor(mutedGray)
            Text(value)
                .font(Font.custom("Inter-Bold", size: 14))
                .foregroundColor(darkText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(lightFill)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Booking Summary card

    private var bookingSummaryCard: some View {
        VStack(spacing: 0) {
            Text("Booking Summary")
                .font(Font.custom("Inter-Bold", size: 16))
                .tracking(-0.4)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .frame(height: 57)
                .background(brandRed)

            VStack(spacing: 16) {
                summaryRow(icon: "airplane", label: "FLIGHT", detail: "\(routeOriginText) → \(routeDestinationText)", price: flightFee)
                summaryRow(icon: "bed.double.fill", label: "HOTEL", detail: booking.hotelCity.isEmpty ? "—" : booking.hotelCity, price: hotelFee)

                HStack {
                    Text("Taxes (GST)")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(dimText)
                    Spacer()
                    Text(taxesText)
                        .font(Font.custom("Inter-Bold", size: 14))
                        .foregroundColor(dimText)
                }
                .padding(.top, 17)
                .overlay(Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1), alignment: .top)

                HStack(alignment: .lastTextBaseline) {
                    Text("TOTAL")
                        .font(Font.custom("Inter-Bold", size: 20))
                        .tracking(1.2)
                        .foregroundColor(.white)
                    Spacer()
                    Text(totalText)
                        .font(Font.custom("Inter-Bold", size: 24))
                        .foregroundColor(brandRed)
                }
                .padding(.top, 18)
                .overlay(Rectangle().fill(Color.white.opacity(0.15)).frame(height: 2), alignment: .top)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func summaryRow(icon: String, label: String, detail: String, price: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.white).frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(darkCard)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Font.custom("Inter-Bold", size: 12))
                    .tracking(0.6)
                    .foregroundColor(.white)
                Text(detail)
                    .font(Font.custom("Inter", size: 14).weight(.semibold))
                    .foregroundColor(dimText)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(price)
                .font(Font.custom("Inter-Bold", size: 14))
                .foregroundColor(dimText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Next button

    private var nextButton: some View {
        Button(action: { booking.showPersonalDetails = true }) {
            HStack(spacing: 8) {
                Text("NEXT")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 16))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(brandRed)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationView {
        DummyTicketBothRouteDetailsView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
