import SwiftUI

// MARK: - DummyTicketRouteDetailsView
// Figma: "Route Details" (node 3470:3549) — step 1 of 5 in the Dummy Tickets booking flow,
// reached from DummyTicketInitialView's "BUY DUMMY TICKET" button. Recaps the From/To/Departure
// values already entered there (read-only here) and introduces the flow's 5-step progress header.
// NEXT pushes DummyTicketPersonalDetailsView (step 2). Additional Details / Review Booking /
// Payment (steps 3-5) haven't been designed yet, so "Add More Routes" still shows the same
// "coming soon" toast used everywhere else in this app for a destination that doesn't exist yet.
//
// Reads/writes DummyTicketBookingViewModel (shared across the whole flow via .environmentObject,
// injected once in DummyTicketInitialView) instead of taking its own init parameters or holding a
// local copy of trip type — this is also the screen Review Booking's "Route Information" Edit
// link returns to, so it needs to reflect the live shared values, not a snapshot from whenever it
// was first pushed.

struct DummyTicketRouteDetailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel
    @State private var showComingSoonToast = false

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let mutedGray = Color(red: 0.42, green: 0.447, blue: 0.502)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let dimText = Color(red: 0.635, green: 0.635, blue: 0.635)

    // Base fare / GST / total are fixed placeholder amounts — no live fare engine exists yet for
    // a "dummy ticket." Kept as the Figma mock's own exact numbers rather than deriving GST from
    // the base fare (699 * 0.18 = 125.82), since that rounding is the design's own choice, not a
    // formula this screen should silently recompute differently.
    private let baseFare = "₹699.00"
    private let gst = "₹126.00"
    private let totalAmount = "₹825.00"

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    header(safeAreaTop: proxy.safeAreaInsets.top)

                    // ScrollView, not a fixed VStack: the route recap + fare summary + trust
                    // badge + button together are taller than most screens, and need to adapt to
                    // any device height rather than risk clipping the NEXT button off-screen.
                    ScrollView(showsIndicators: false) {
                        content
                    }
                    .frame(maxHeight: .infinity)
                }

                if showComingSoonToast {
                    VStack {
                        Spacer()
                        ToastView(icon: "hourglass", message: "Coming soon! We're working hard to bring this to you.")
                            .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                NavigationLink(
                    destination: DummyTicketPersonalDetailsView().environmentObject(booking),
                    isActive: $booking.showPersonalDetails
                ) {
                    EmptyView()
                }
                .hidden()
            }
            // .vertical, not a bare .ignoresSafeArea(): see DummyTicketInitialView for why an
            // unscoped call (which defaults to ALL regions, including left/right) risks throwing
            // off the ScrollView's calculated height, particularly in landscape.
            .ignoresSafeArea(edges: .vertical)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showComingSoonToast)
        }
        .navigationBarHidden(true)
    }

    private func showComingSoon() {
        showComingSoonToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { showComingSoonToast = false }
    }

    // MARK: - Header (back row + 5-step progress)

    private func header(safeAreaTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color(red: 0.10, green: 0.11, blue: 0.11)
                .frame(height: safeAreaTop)

            HStack(spacing: 6) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Figma literally labels this "Back", not the screen's own name — unlike every
                // other header in this app, which shows the destination's title here instead.
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
        .background(Color(red: 0.10, green: 0.11, blue: 0.11))
        .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
    }

    private var flowStepper: some View {
        // Step 1 (this screen) is shown completed rather than "in progress" — that's how the
        // Figma mock renders it, confirmed by every later step's own stepper design too.
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
                        // Drops the connector to the circle's vertical center (28pt circle ÷ 2)
                        // rather than the row's overall center, which HStack's default alignment
                        // would otherwise compute against the taller circle+label column.
                        .padding(.top, 14)
                }
            }
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Route Details")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .tracking(-0.75)
                    .foregroundColor(darkText)

                Text("Select Trip Type")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                    .foregroundColor(darkText)

                tripTypeSelector
            }

            routeFormCard
            flightSummaryCard
            trustBadge
            nextButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(24, tabBarState.height + 16))
        // Caps width on iPad's compatibility window — same treatment as DummyTicketInitialView.
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Trip type selector

    private var tripTypeSelector: some View {
        HStack(spacing: 8) {
            tripTypeButton(.oneWay, label: "One Way", icon: "airplane")
            tripTypeButton(.roundTrip, label: "Round Trip", icon: "arrow.left.arrow.right")
            tripTypeButton(.multiTrip, label: "Multi City", icon: "point.3.connected.trianglepath.dotted")
        }
    }

    private func tripTypeButton(_ type: DummyTicketTripType, label: String, icon: String) -> some View {
        let isSelected = booking.selectedTripType == type
        return Button(action: { booking.selectedTripType = type }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? brandRed : darkText)
                Text(label)
                    .font(Font.custom("PlusJakartaSans-Bold", size: 10))
                    .foregroundColor(isSelected ? brandRed : darkText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color(red: 0.984, green: 0.949, blue: 0.953) : Color(red: 0.953, green: 0.957, blue: 0.961))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? brandRed : strokeColor.opacity(0.6), lineWidth: isSelected ? 2 : 0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Route form card (read-only recap)

    private var routeFormCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            recapField(label: "ORIGIN CITY", value: booking.fromLocation, icon: "mappin.circle.fill")
            recapField(label: "DESTINATION CITY", value: booking.toLocation, icon: "paperplane.fill")
            recapField(label: "DEPARTURE DATE", value: booking.departureDateText, icon: "calendar")

            Button(action: showComingSoon) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Add More Routes")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 12))
                }
                .foregroundColor(brandRed)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .background(Color(red: 0.976, green: 0.980, blue: 0.984).opacity(0.5))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func recapField(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Font.custom("PlusJakartaSans-Bold", size: 10))
                .tracking(0.5)
                .foregroundColor(mutedGray)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(mutedGray)
                Text(value.isEmpty ? "—" : value)
                    .font(Font.custom("PlusJakartaSans-Regular", size: 14))
                    .foregroundColor(mutedGray)
                    .lineLimit(1)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor, lineWidth: 0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Flight summary card

    private var flightSummaryCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                Text("Flight Summary")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(brandRed)

            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        Circle().fill(brandRed).frame(width: 8, height: 8)
                        Rectangle()
                            .fill(brandRed.opacity(0.25))
                            .frame(width: 1)
                        Circle()
                            .strokeBorder(brandRed, lineWidth: 1.5)
                            .background(Circle().fill(Color.white))
                            .frame(width: 8, height: 8)
                    }
                    .frame(height: 80)
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 28) {
                        routeSummaryRow(caption: "ORIGIN", value: booking.fromLocation)
                        routeSummaryRow(caption: "DESTINATION", value: booking.toLocation)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TRAVEL DATE")
                            .font(Font.custom("Inter-Bold", size: 10))
                            .tracking(1)
                            .foregroundColor(dimText)
                        Text(booking.departureDateText)
                            .font(Font.custom("PlusJakartaSans-SemiBold", size: 14))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(16)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 14) {
                    fareRow(label: "Base Fare (1 Adult)", value: baseFare)
                    fareRow(label: "GST (18%)", value: gst)

                    HStack {
                        Text("Total Amount")
                            .font(Font.custom("Inter-Bold", size: 18))
                            .foregroundColor(.white)
                        Spacer()
                        Text(totalAmount)
                            .font(Font.custom("Inter-Bold", size: 22))
                            .foregroundColor(brandRed)
                    }
                    .padding(.top, 14)
                    .overlay(Rectangle().fill(Color.white.opacity(0.4)).frame(height: 1), alignment: .top)
                }
            }
            .padding(24)
        }
        .background(Color(red: 0.10, green: 0.11, blue: 0.11))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func routeSummaryRow(caption: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(caption)
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(1)
                .foregroundColor(dimText)
            Text(value.isEmpty ? "—" : value)
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }

    private func fareRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Font.custom("Inter", size: 14))
                .foregroundColor(dimText)
            Spacer()
            Text(value)
                .font(Font.custom("Inter-Bold", size: 14))
                .foregroundColor(.white)
        }
    }

    // MARK: - Trust badge

    private var trustBadge: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.976, green: 0.980, blue: 0.984))
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 18))
                    .foregroundColor(brandRed)
            }
            .frame(width: 38, height: 43)

            Text("Securely verified by Itzeazy Dummy Ticket Services. Instant delivery guaranteed with airline-validated PNR status.")
                .font(Font.custom("PlusJakartaSans-Regular", size: 10))
                .foregroundColor(mutedGray)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16.6)
        .background(Color(red: 0.976, green: 0.980, blue: 0.984))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor.opacity(0.6), lineWidth: 0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Next button

    private var nextButton: some View {
        Button(action: { booking.showPersonalDetails = true }) {
            HStack(spacing: 8) {
                Text("NEXT")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(brandRed)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationView {
        DummyTicketRouteDetailsView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
