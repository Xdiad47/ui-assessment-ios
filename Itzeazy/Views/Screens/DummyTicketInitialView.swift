import SwiftUI
import UIKit

// MARK: - DummyTicketInitialView
// Figma: "dummy ticket home" (node 3470:3471) — entry screen for the Dummy Tickets flow, reached
// from HomeServicesGridView's "Dummy\nTickets" tile. Mirrors the same dark rounded-card header +
// hero-image + floating white card pattern already used by MarriageRegInitialView/
// PassportInitialView/etc. No GovDisclaimerGate here — unlike those screens, Dummy Tickets is a
// private booking convenience (dummy return-flight bookings used as visa proof), not a government
// service portal, so the ULIP/gov-portal disclaimer doesn't apply.
//
// This is the first screen of a multi-screen flow. Tapping BUY DUMMY TICKET pushes
// DummyTicketRouteDetailsView once the form is valid.
//
// Hotel fields (Figma node 3497:6908): selecting the HOTEL tab swaps FROM/TO/DEPARTURE for
// CITY/CHECK IN DATE/CHECK OUT DATE and hides the trip-type row entirely (a hotel stay has no
// one-way/round-trip/multi-trip concept) — see formFields/bookingCard below, both branching on
// booking.selectedServiceType.
//
// BOTH fields (Figma node 3497:8105): selecting the BOTH tab shows Flight's trip-type row +
// FROM/TO/DEPARTURE AND Hotel's CITY/CHECK IN/CHECK OUT stacked in the same card, each group under
// its own "Flight"/"Hotel" section label (sectionLabel below) — unlike FLIGHT/HOTEL alone, which
// have no such label. booking.isRouteDetailsSubmitEnabled requires all six fields for BOTH.
//
// BOTH now has its own Route Details screen too (DummyTicketBothRouteDetailsView, node 3497:8211)
// — a read-only combined recap of both services rather than another editable form. Past that
// screen, BOTH still continues into Flight's own Personal/Additional/Review/Payment screens — no
// combined design exists for those steps yet (see DummyTicketBothRouteDetailsView's own top
// comment).

struct DummyTicketInitialView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    // The one instance for the whole 5-step flow — created here, handed to every pushed screen
    // via .environmentObject() below, so an edit made on any screen is visible on every other.
    @StateObject private var booking = DummyTicketBookingViewModel()
    @State private var showDeparturePicker = false
    @State private var showCheckInPicker = false
    @State private var showCheckOutPicker = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case from, to, city
    }

    // Figma calls this screen's accent "primary red: #FF0000" — a literal `bg-[red]` in the
    // reference, not a HIG/token path, so it's kept as the exact value rather than remapped to
    // one of the app's several existing near-red shades (RTOServicesView/HomeHeroCardView/etc.
    // each use a slightly different red already).
    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let mutedGray = Color(red: 0.42, green: 0.447, blue: 0.502)
    private let placeholderGray = Color(red: 0.612, green: 0.639, blue: 0.686)
    private let tabTrackGray = Color(red: 0.953, green: 0.957, blue: 0.965)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    header(safeAreaTop: proxy.safeAreaInsets.top)

                    // ScrollView, not a fixed VStack + Spacer: on a short device (iPhone SE) the
                    // hero heading + booking card together can exceed the available height, and
                    // a fixed layout would silently clip the submit button off-screen with no way
                    // to reach it. Scrolling adapts to any screen size; on a tall device the extra
                    // room just becomes empty space below the card, same as it would otherwise.
                    ScrollView(showsIndicators: false) {
                        heroContent
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                NavigationLink(
                    destination: routeDetailsDestination,
                    isActive: $booking.showRouteDetails
                ) {
                    EmptyView()
                }
                .hidden()
            }
            // Background lives in .background(), not as a ZStack array child. A ZStack child
            // that ignores the safe area can feed the layout system a bigger-than-visible size,
            // which is exactly what was corrupting how much vertical space the GeometryReader ->
            // ZStack -> ScrollView chain thought it had — harmless-looking in portrait since the
            // side insets are near zero there, but landscape inflates the left/right insets
            // (notch/home-indicator move to the long edges), which is why scrolling broke
            // specifically after rotating. Same fix already applied to HomeView.swift for the
            // iPad compatibility-window bleed — .background() paints behind the content without
            // ever being asked to size it.
            .background(backgroundLayer)
            // .container, not the default .all: .all also covers the .keyboard region, which
            // would let this whole screen (ScrollView included) stay full-height and unaware the
            // keyboard is covering part of it — exactly what stopped it scrolling properly while
            // the keyboard was up. Scoping to .container (status bar/home indicator only) lets
            // the keyboard still shrink the available space normally, so the ScrollView knows its
            // real visible bounds and scrolls correctly within them. Same reasoning already
            // applied to CreateAccountView's form card.
            .ignoresSafeArea(.container, edges: .vertical)
        }
        .navigationBarHidden(true)
        // Kept here as a safety net for anything else rendered directly under this view, but
        // NOT relied on to reach pushed destinations: in practice a NavigationLink's destination
        // can be constructed/mounted without reliably inheriting an @EnvironmentObject set higher
        // in the same body's modifier chain, so every push in this flow attaches
        // `.environmentObject(booking)` directly to its own `destination:` view instead (see the
        // NavigationLink just above, and the same pattern repeated on every screen after this one).
        .environmentObject(booking)
        .sheet(isPresented: $showDeparturePicker) {
            departureDatePickerSheet
                .environmentObject(booking)
        }
        .sheet(isPresented: $showCheckInPicker) {
            checkInDatePickerSheet
                .environmentObject(booking)
        }
        .sheet(isPresented: $showCheckOutPicker) {
            checkOutDatePickerSheet
                .environmentObject(booking)
        }
        // The FROM/TO fields sit on MainTabView's persistent tab bar, and ignoring the keyboard
        // safe area on the tab bar's own block (see MainTabView.swift) wasn't enough to stop it
        // rising above the keyboard when a field is focused. Hiding it outright for the duration
        // of the keyboard's presence removes any ambiguity — same tabBarState.isHidden mechanism
        // DocumentScannerView/YoutubePlayerView already use, just driven by keyboard notifications
        // (same NotificationCenter pattern RegisterOTPView uses) instead of a screen-level toggle.
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            tabBarState.isHidden = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            tabBarState.isHidden = false
        }
        .onDisappear {
            tabBarState.isHidden = false
        }
        // Confirmation's "Back Home" button (booking.returnHome()) collapses every pushed screen's
        // isActive flag back down to this one, then flips this flag once that's settled — at that
        // point this view genuinely is back at the top of the stack, so calling dismiss() here (and
        // only here) is well-defined and sends the user back to HomeView.
        .onChange(of: booking.returnHomeRequested) { _, requested in
            guard requested else { return }
            booking.returnHomeRequested = false
            presentationMode.wrappedValue.dismiss()
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Image("dummy_bg")
                .resizable()
                .scaledToFill()

            Color.black.opacity(0.6)
        }
    }

    // MARK: - Header

    private func header(safeAreaTop: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(strokeColor)
                .frame(maxWidth: .infinity)
                .frame(height: safeAreaTop + 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            Color(red: 0.10, green: 0.11, blue: 0.11)
                .frame(maxWidth: .infinity)
                .frame(height: safeAreaTop + 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 12) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image("back_arrow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }

                Text("Dummy Tickets")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
            .padding(.top, safeAreaTop)
        }
    }

    // MARK: - Hero content

    private var heroContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            (
                Text("Get Your Dummy\nTicket At ")
                    .foregroundColor(.white)
                + Text("₹499")
                    .foregroundColor(brandRed)
            )
            .font(Font.custom("PlusJakartaSans-ExtraBold", size: 24))
            .lineSpacing(3)
            .padding(.top, 24)

            // 28pt, not the 68pt this originally had: that number came from transliterating
            // Figma's absolute pixel offsets (top: 141 for the heading, top: 225 for the card,
            // both measured against one fixed 393×852 canvas) instead of the actual visual gap
            // between the two — which the design shows as much tighter than that math implied.
            bookingCard
                .padding(.top, 28)
        }
        .padding(.horizontal, 16)
        // max(24, tabBarState.height + 16), not a fixed 24: BOTH's card is tall enough (6 fields
        // instead of 3) that a fixed bottom padding left the submit button scrolled only as far as
        // the tab bar's top edge, not past it — same fix already applied to every screen after
        // this one in the flow (DummyTicketHotelPersonalDetailsView etc.).
        .padding(.bottom, max(24, tabBarState.height + 16))
        // Caps width on iPad's compatibility window rather than letting the card stretch
        // edge-to-edge at iPad width — same treatment already applied to LoginView/CreateAccountView.
        // No explicit alignment on the outer frame: its default (.center) centers the capped
        // block on a wide screen. .leading here would pin it flush left with empty space on the
        // right instead — the text/card's own internal .leading alignment is unaffected either way.
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
        // contentShape(Rectangle()), not just .onTapGesture: a VStack is normally only tappable
        // where its children actually paint, so the blank padding between the heading and the
        // card wouldn't register a tap at all without this. A plain (non-simultaneous, non-high-
        // priority) .onTapGesture here coexists with the ScrollView's own drag-to-scroll gesture
        // and doesn't shadow the TextFields/Buttons inside — SwiftUI gives the more specific,
        // deeper view priority for a tap that lands directly on it. Same established pattern as
        // CreateAccountView's form card.
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
    }

    // MARK: - Booking card

    private var bookingCard: some View {
        VStack(spacing: 16) {
            serviceTabs
            // BOTH's own frame labels this group "Flight" above the trip-type row — FLIGHT alone
            // has no such label, so this is BOTH-only.
            if booking.selectedServiceType == .both {
                sectionLabel("Flight")
            }
            // Figma's Hotel frame (node 3497:6908) drops this row entirely — a hotel stay has no
            // one-way/round-trip/multi-trip concept. FLIGHT and BOTH keep showing it unchanged.
            if booking.selectedServiceType != .hotel {
                tripTypeSelectors
            }
            formFields
            submitButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 36)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: 20)
        .colorScheme(.light)
    }

    private var serviceTabs: some View {
        HStack(spacing: 0) {
            ForEach(DummyTicketServiceType.allCases) { type in
                Button(action: { booking.selectedServiceType = type }) {
                    Text(type.rawValue)
                        .font(Font.custom("Inter-Bold", size: 12))
                        .foregroundColor(booking.selectedServiceType == type ? .white : mutedGray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(booking.selectedServiceType == type ? brandRed : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(tabTrackGray)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var tripTypeSelectors: some View {
        HStack(spacing: 24) {
            ForEach(DummyTicketTripType.allCases) { type in
                Button(action: { booking.selectedTripType = type }) {
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .stroke(booking.selectedTripType == type ? brandRed : mutedGray, lineWidth: 1)
                                .frame(width: 16, height: 16)
                            if booking.selectedTripType == type {
                                Circle()
                                    .fill(brandRed)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        Text(type.rawValue)
                            .font(Font.custom("Inter-Bold", size: 10))
                            .tracking(-0.25)
                            .foregroundColor(booking.selectedTripType == type ? brandRed : placeholderGray)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private var formFields: some View {
        VStack(spacing: 16) {
            switch booking.selectedServiceType {
            case .hotel:
                hotelFields
            case .flight:
                flightFields
            case .both:
                flightFields
                sectionLabel("Hotel")
                hotelFields
            }
        }
    }

    @ViewBuilder
    private var flightFields: some View {
        fieldBlock(label: "FROM") {
            TextField("Enter City or Airport", text: $booking.fromLocation)
                .font(Font.custom("Inter", size: 14))
                .focused($focusedField, equals: .from)
        }
        fieldBlock(label: "TO") {
            TextField("Enter Destination City", text: $booking.toLocation)
                .font(Font.custom("Inter", size: 14))
                .focused($focusedField, equals: .to)
        }
        fieldBlock(label: "DEPARTURE") {
            dateButton(text: booking.departureDateText, isPlaceholder: booking.departureDate == nil) {
                showDeparturePicker = true
            }
        }
    }

    @ViewBuilder
    private var hotelFields: some View {
        fieldBlock(label: "CITY") {
            TextField("Enter City", text: $booking.hotelCity)
                .font(Font.custom("Inter", size: 14))
                .focused($focusedField, equals: .city)
        }
        fieldBlock(label: "CHECK IN DATE") {
            dateButton(text: booking.checkInDateText, isPlaceholder: booking.checkInDate == nil) {
                showCheckInPicker = true
            }
        }
        fieldBlock(label: "CHECK OUT DATE") {
            dateButton(text: booking.checkOutDateText, isPlaceholder: booking.checkOutDate == nil) {
                showCheckOutPicker = true
            }
        }
    }

    // BOTH's own frame (node 3497:8105) is the only place these appear — plain FLIGHT/HOTEL
    // selection has no such label above their fields.
    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Font.custom("Inter-Bold", size: 10))
            .tracking(0.5)
            .foregroundColor(Color(red: 0.098, green: 0.110, blue: 0.114))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dateButton(text: String, isPlaceholder: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(Font.custom("Inter", size: 14))
                    .foregroundColor(isPlaceholder ? placeholderGray : Color(red: 0.10, green: 0.11, blue: 0.11))
                Spacer()
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(mutedGray)
            }
        }
        .buttonStyle(.plain)
    }

    private func fieldBlock<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(0.5)
                .foregroundColor(brandRed)

            content()
                .padding(.horizontal, 17)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(strokeColor, lineWidth: 1)
                )
        }
    }

    private var submitButton: some View {
        Button(action: {
            guard booking.isRouteDetailsSubmitEnabled else { return }
            booking.showRouteDetails = true
        }) {
            Text("BUY DUMMY TICKET")
                .font(Font.custom("Inter-Bold", size: 12))
                .tracking(1.2)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(booking.isRouteDetailsSubmitEnabled ? brandRed : brandRed.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: brandRed.opacity(booking.isRouteDetailsSubmitEnabled ? 0.3 : 0), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    // HOTEL and BOTH each get their own Route Details screen — HOTEL's trip-type concept
    // (Single/Couple/Family Stay) and card layout (Hotel Details/Hotel Summary), and BOTH's
    // read-only combined recap (Flight Selection/Stay Preferences/Booking Summary), are different
    // enough from Flight's editable form that branching inside one shared view would mean three
    // largely unrelated layouts interleaved with ifs, so each is a whole separate destination.
    @ViewBuilder
    private var routeDetailsDestination: some View {
        switch booking.selectedServiceType {
        case .hotel:
            DummyTicketHotelRouteDetailsView().environmentObject(booking)
        case .both:
            DummyTicketBothRouteDetailsView().environmentObject(booking)
        case .flight:
            DummyTicketRouteDetailsView().environmentObject(booking)
        }
    }

    // MARK: - Departure date sheet

    private var departureDatePickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { showDeparturePicker = false }
                    .foregroundColor(.secondary)
                Spacer()
                Text("Departure Date")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                Spacer()
                Button("Done") { showDeparturePicker = false }
                    .font(.body.bold())
                    .foregroundColor(brandRed)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            DatePicker(
                "Departure Date",
                selection: Binding(
                    get: { booking.departureDate ?? Date() },
                    set: { booking.departureDate = $0 }
                ),
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(brandRed)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(420)])
    }

    // MARK: - Hotel date sheets

    private var checkInDatePickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { showCheckInPicker = false }
                    .foregroundColor(.secondary)
                Spacer()
                Text("Check In Date")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                Spacer()
                Button("Done") { showCheckInPicker = false }
                    .font(.body.bold())
                    .foregroundColor(brandRed)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            DatePicker(
                "Check In Date",
                selection: Binding(
                    get: { booking.checkInDate ?? Date() },
                    set: { booking.checkInDate = $0 }
                ),
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(brandRed)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(420)])
    }

    private var checkOutDatePickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { showCheckOutPicker = false }
                    .foregroundColor(.secondary)
                Spacer()
                Text("Check Out Date")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                Spacer()
                Button("Done") { showCheckOutPicker = false }
                    .font(.body.bold())
                    .foregroundColor(brandRed)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Can't check out before checking in — the natural lower bound, same reasoning as
            // Departure/Check In already using Date()... to block picking a date in the past.
            DatePicker(
                "Check Out Date",
                selection: Binding(
                    get: { booking.checkOutDate ?? booking.checkInDate ?? Date() },
                    set: { booking.checkOutDate = $0 }
                ),
                in: (booking.checkInDate ?? Date())...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(brandRed)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(420)])
    }
}

#Preview {
    NavigationView {
        DummyTicketInitialView()
    }
    .environmentObject(TabBarState())
}
