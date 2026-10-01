import SwiftUI

// MARK: - DummyTicketReviewBookingView
// Figma: "Review Booking" (node 3470:4107) — step 4 of 5 in the Dummy Tickets booking flow,
// reached from DummyTicketAdditionalDetailsView's NEXT button. Pure read-only recap of everything
// collected on steps 1-3 (no new input), so — unlike the two screens before it — this one has no
// keyboard to fight with. "Process Payment" pushes DummyTicketPaymentView (step 5, the flow's
// final screen).
//
// Every card's "Edit" link now actually navigates: it calls DummyTicketBookingViewModel.editRoute()
// or .editPersonal(), which flips every "show past this point" navigation flag on the shared model
// back to false in one synchronous change — since every screen in the flow's NavigationLink is
// bound to one of those flags, that collapses the whole pushed stack straight back to Route
// Details or Personal Details in a single transition, without needing a dismiss() chained through
// every intermediate screen (the legacy NavigationLink(isActive:) API has no "pop to a specific
// ancestor" of its own). Because both screens read/write the same shared model instead of a
// snapshot, whatever the user changes there is already live when they arrive back here — no
// re-fetch or explicit "save" step needed.
struct DummyTicketReviewBookingView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let captionGray = Color(red: 0.639, green: 0.639, blue: 0.639)
    private let mutedText = Color(red: 0.373, green: 0.369, blue: 0.369)

    // Same fixed mock numbers as the earlier screens — Base Fare + GST bundled there as ₹825,
    // broken out here to match this screen's own Figma line items exactly.
    private let baseFare = 699
    private let gst = 126
    private let urgentFee = 199
    private var totalAmount: Int { baseFare + gst + (booking.isUrgentProcessing ? urgentFee : 0) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea(edges: .vertical)

                VStack(spacing: 0) {
                    header(safeAreaTop: proxy.safeAreaInsets.top)

                    ScrollView(showsIndicators: false) {
                        content
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                NavigationLink(
                    destination: DummyTicketPaymentView().environmentObject(booking),
                    isActive: $booking.showPayment
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

    private var flowStepper: some View {
        let currentStep = 4
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
        VStack(alignment: .leading, spacing: 20) {
            Text("Review Your Booking")
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .tracking(-0.75)
                .foregroundColor(darkText)

            routeInformationCard
            passengerInformationCard
            contactDetailsCard
            servicesSelectedSection
            paymentSummaryCard
            navigationButtons
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(24, tabBarState.height + 16))
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Card shell (dark header + white body)

    private func recapCard<Content: View>(
        icon: String,
        title: String,
        iconInCircle: Bool = false,
        onEdit: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if iconInCircle {
                    ZStack {
                        Circle().fill(Color.white).frame(width: 28, height: 28)
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(brandRed)
                    }
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                    .foregroundColor(.white)

                Spacer(minLength: 8)

                Button(action: onEdit) {
                    Text("Edit")
                        .font(Font.custom("Inter-Bold", size: 14))
                        .foregroundColor(brandRed)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(darkCard)

            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(16)
            .background(Color.white)
        }
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor.opacity(0.6), lineWidth: 0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func labeledValue(_ label: String, _ value: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(1)
                .foregroundColor(captionGray)
            Text(value.isEmpty ? "—" : value)
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .foregroundColor(darkText)
        }
    }

    // MARK: - Route Information

    private var routeInformationCard: some View {
        // Edit here goes back to Route Details — that's the screen Origin/Destination/Departure
        // Date/Trip Type actually live on.
        recapCard(icon: "airplane.circle.fill", title: "Route Information", iconInCircle: true, onEdit: booking.editRoute) {
            HStack(alignment: .top, spacing: 8) {
                labeledValue("DEPARTURE", booking.fromLocation)

                Spacer(minLength: 4)

                VStack(spacing: 4) {
                    Image("airplane_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 20)
                    Text(booking.departureDateText)
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(mutedText)
                        .fixedSize()
                }

                Spacer(minLength: 4)

                labeledValue("ARRIVAL", booking.toLocation, alignment: .trailing)
            }
        }
    }

    // MARK: - Passenger Information

    private var passengerInformationCard: some View {
        // Edit here goes back to Personal Details — Title/First+Last Name/DOB/Gender/Passport/
        // Nationality are all on that screen's "Passenger" card.
        recapCard(icon: "person.crop.circle.fill", title: "Passenger Information", onEdit: booking.editPersonal) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PRIMARY PASSENGER")
                    .font(Font.custom("Inter-Bold", size: 10))
                    .tracking(1)
                    .foregroundColor(captionGray)
                Text(booking.passengerName.isEmpty ? "—" : booking.passengerName)
                    .font(Font.custom("Inter-Bold", size: 16))
                    .foregroundColor(darkText)
            }

            HStack(alignment: .top, spacing: 16) {
                smallLabeledValue("NATIONALITY", booking.nationality.name)
                smallLabeledValue("TRAVEL DATE", booking.departureDateText)
            }
        }
    }

    private func smallLabeledValue(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(1)
                .foregroundColor(captionGray)
            Text(value.isEmpty ? "—" : value)
                .font(Font.custom("Inter-Bold", size: 14))
                .foregroundColor(darkText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Contact Details

    private var contactDetailsCard: some View {
        // Contact info (mobile/email) also lives on Personal Details, not a separate screen — so
        // this Edit goes to the same place Passenger Information's does.
        recapCard(icon: "at.circle.fill", title: "Contact Details", onEdit: booking.editPersonal) {
            contactRow(icon: "envelope.fill", iconSize: 13, label: "EMAIL ADDRESS", value: booking.emailAddress)
            contactRow(icon: "phone.fill", iconSize: 12, label: "PHONE NUMBER", value: booking.phoneNumber)
        }
    }

    private func contactRow(icon: String, iconSize: CGFloat, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(red: 0.929, green: 0.933, blue: 0.937)).frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundColor(mutedText)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Font.custom("Inter-Bold", size: 10))
                    .tracking(1)
                    .foregroundColor(captionGray)
                Text(value.isEmpty ? "—" : value)
                    .font(Font.custom("Inter-Bold", size: 14))
                    .foregroundColor(darkText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Services Selected

    private var servicesSelectedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services Selected")
                .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                .foregroundColor(darkText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // DUMMY TICKET is the only pill Figma gives a border (a slightly darker pink
                    // ring over its light pink fill) — Urgent Processing and PDF Delivery are
                    // flat fills with no border. Its padding is also 1pt taller/wider than the
                    // other two (13/7 vs 12/6).
                    servicePill(icon: "ticket.fill", text: "DUMMY TICKET", foreground: brandRed, background: Color(red: 0.996, green: 0.949, blue: 0.949), border: Color(red: 0.996, green: 0.894, blue: 0.894), horizontalPadding: 13, verticalPadding: 7)

                    if booking.isUrgentProcessing {
                        servicePill(icon: "bolt.fill", text: "URGENT PROCESSING", foreground: .white, background: Color(red: 0.09, green: 0.09, blue: 0.09), border: nil, horizontalPadding: 12, verticalPadding: 6)
                    }
                    if booking.sendEmailPDFCopy {
                        servicePill(icon: "doc.fill", text: "PDF DELIVERY", foreground: mutedText, background: Color(red: 0.882, green: 0.890, blue: 0.898), border: nil, horizontalPadding: 12, verticalPadding: 6)
                    }
                    if booking.sendWhatsAppCopy {
                        servicePill(icon: "message.fill", text: "WHATSAPP DELIVERY", foreground: mutedText, background: Color(red: 0.882, green: 0.890, blue: 0.898), border: nil, horizontalPadding: 12, verticalPadding: 6)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func servicePill(icon: String, text: String, foreground: Color, background: Color, border: Color?, horizontalPadding: CGFloat, verticalPadding: CGFloat) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(Font.custom("Inter-Bold", size: 11))
                .tracking(0.55)
        }
        .foregroundColor(foreground)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(background)
        .overlay(Capsule().stroke(border ?? Color.clear, lineWidth: border == nil ? 0 : 1))
        .clipShape(Capsule())
    }

    // MARK: - Payment Summary

    private var paymentSummaryCard: some View {
        VStack(spacing: 0) {
            Text("Payment Summary")
                .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 21)
                .padding(.vertical, 16)
                .background(brandRed)

            VStack(spacing: 16) {
                paymentRow(label: "Base Fare", value: "₹\(baseFare)")
                if booking.isUrgentProcessing {
                    paymentRow(label: "Urgent Fee", value: "₹\(urgentFee)")
                }
                paymentRow(label: "GST (18%)", value: "₹\(gst)")

                HStack(alignment: .firstTextBaseline) {
                    Text("TOTAL AMOUNT")
                        .font(Font.custom("Inter-Bold", size: 18))
                        .foregroundColor(.white)
                    Spacer()
                    Text("₹\(totalAmount)")
                        .font(Font.custom("Inter-Bold", size: 22))
                        .foregroundColor(brandRed)
                }
                .padding(.top, 16)
                .overlay(Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1), alignment: .top)

                secureCheckoutNote
            }
            .padding(17)
        }
        .background(darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func paymentRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Font.custom("Inter", size: 16).weight(.medium))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(Font.custom("Inter-Bold", size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var secureCheckoutNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                Text("Secure Checkout")
                    .font(Font.custom("Inter-Bold", size: 14))
                    .foregroundColor(.white)
            }
            Text("Your payment information is encrypted and processed through industry-leading secure payment gateways.")
                .font(Font.custom("Inter", size: 12))
                .foregroundColor(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Previous / Process Payment

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(brandRed)
                    Text("PREVIOUS")
                        .font(Font.custom("Inter-Bold", size: 14))
                        .foregroundColor(darkText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .overlay(Capsule().stroke(brandRed, lineWidth: 1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button(action: { booking.showPayment = true }) {
                HStack(spacing: 8) {
                    Text("Process Payment")
                        .font(Font.custom("Inter-Bold", size: 14))
                        .foregroundColor(.white)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(brandRed)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    NavigationView {
        DummyTicketReviewBookingView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
