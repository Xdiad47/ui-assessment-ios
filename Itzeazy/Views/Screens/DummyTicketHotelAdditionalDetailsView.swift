import SwiftUI

// MARK: - DummyTicketHotelAdditionalDetailsView
// Figma: "Route Details" frame, shown on-screen as "Additional Details" (node 3497:7346) — the
// Hotel flow's own step 3, reached from DummyTicketHotelPersonalDetailsView's NEXT button. Mirrors
// DummyTicketAdditionalDetailsView's header/flowStepper/layout conventions closely, but every
// section here is genuinely Hotel-specific (Hotel Preferences, Estimated Arrival, Delivery Method,
// Special Requests, Terms Agreement) — none of Flight's fields (travel purpose, WhatsApp/Email PDF
// copy toggles, Urgent Processing) apply to a hotel stay, so this doesn't reuse that screen's
// model fields at all, only its own dedicated ones on the shared DummyTicketBookingViewModel.
//
// NEXT pushes DummyTicketHotelReviewBookingView — Hotel's own step 4 (node 3497:7499), not
// Flight's DummyTicketReviewBookingView. The Terms Agreement checkbox is tracked but doesn't gate
// NEXT, matching how every other toggle on this screen (and Flight's Additional Details) is
// informational rather than a hard requirement — no button in this flow is disabled beyond
// DummyTicketInitialView's own initial submit.

struct DummyTicketHotelAdditionalDetailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel
    @FocusState private var isSpecialRequestsFocused: Bool

    @State private var showArrivalTimePicker = false

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let rowFill = Color(red: 0.953, green: 0.957, blue: 0.961)
    private let checkboxBorder = Color(red: 0.573, green: 0.431, blue: 0.416)
    private let termsTextGray = Color(red: 0.373, green: 0.369, blue: 0.369)
    private let placeholderGray = Color(red: 0.373, green: 0.369, blue: 0.369).opacity(0.5)

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
                    destination: DummyTicketHotelReviewBookingView().environmentObject(booking),
                    isActive: $booking.showReviewBooking
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .ignoresSafeArea(edges: .vertical)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showArrivalTimePicker) {
            arrivalTimePickerSheet
                .environmentObject(booking)
        }
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
        let currentStep = 3
        let steps: [(number: Int, label: String)] = [
            (1, "Route\nDetails"),
            (2, "Guest\nDetails"),
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
        VStack(alignment: .leading, spacing: 24) {
            Text("Additional Details")
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .tracking(-0.75)
                .foregroundColor(darkText)

            hotelPreferencesCard
            estimatedArrivalCard
            deliveryMethodCard
            specialRequestsCard
            termsAgreementRow
            navigationButtons
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(24, tabBarState.height + 16))
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            isSpecialRequestsFocused = false
        }
    }

    // MARK: - Section header (shared visual for every card on this screen)

    private func sectionHeader(icon: String, title: String, height: CGFloat = 45) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(brandRed)
            Text(title)
                .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                .tracking(1.4)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .frame(height: height)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(darkCard)
    }

    // MARK: - Hotel Preferences card

    private var hotelPreferencesCard: some View {
        VStack(spacing: 0) {
            sectionHeader(icon: "checklist", title: "HOTEL PREFERENCES", height: 60)

            VStack(spacing: 12) {
                preferenceRow(isOn: $booking.hotelWantsFreeBreakfast, label: "Free Breakfast", icon: "cup.and.saucer.fill")
                preferenceRow(isOn: $booking.hotelWantsHighSpeedWiFi, label: "High-Speed WiFi", icon: "wifi")
                preferenceRow(isOn: $booking.hotelWantsRefundable, label: "Refundable", icon: "creditcard.fill")
                preferenceRow(isOn: $booking.hotelWantsNearCenter, label: "Near Center", icon: "mappin.circle.fill")
            }
            .padding(10)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func preferenceRow(isOn: Binding<Bool>, label: String, icon: String) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            HStack(spacing: 16) {
                checkbox(isOn: isOn.wrappedValue)
                Text(label)
                    .font(Font.custom("Inter", size: 16).weight(.medium))
                    .foregroundColor(darkText)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(brandRed)
            }
            .padding(16)
            .background(rowFill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func checkbox(isOn: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isOn ? brandRed : Color.white)
                .frame(width: 20, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isOn ? Color.clear : checkboxBorder, lineWidth: 1)
                )
            if isOn {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Estimated Arrival card

    private var estimatedArrivalCard: some View {
        VStack(spacing: 0) {
            sectionHeader(icon: "clock.fill", title: "ESTIMATED ARRIVAL")

            Button(action: { showArrivalTimePicker = true }) {
                HStack {
                    Text(booking.estimatedArrivalTimeText)
                        .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                        .foregroundColor(darkText)
                    Spacer()
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(brandRed)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor.opacity(0.6), lineWidth: 0.6))
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var arrivalTimePickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { showArrivalTimePicker = false }
                    .foregroundColor(.secondary)
                Spacer()
                Text("Estimated Arrival")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                Spacer()
                Button("Done") { showArrivalTimePicker = false }
                    .font(.body.bold())
                    .foregroundColor(brandRed)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            DatePicker(
                "Estimated Arrival",
                selection: $booking.estimatedArrivalTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(280)])
    }

    // MARK: - Delivery Method card

    private var deliveryMethodCard: some View {
        VStack(spacing: 0) {
            sectionHeader(icon: "paperplane.fill", title: "DELIVERY METHOD")

            HStack(spacing: 12) {
                deliveryButton(.email, label: "Email", icon: "envelope.fill")
                deliveryButton(.whatsapp, label: "WhatsApp", icon: "message.fill")
            }
            .padding(10)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func deliveryButton(_ method: DummyTicketDeliveryMethod, label: String, icon: String) -> some View {
        let isSelected = booking.deliveryMethod == method
        return Button(action: { booking.deliveryMethod = method }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? brandRed : darkText)
                Text(label)
                    .font(Font.custom("Inter-Bold", size: 14))
                    .foregroundColor(darkText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(isSelected ? brandRed.opacity(0.05) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? brandRed : strokeColor.opacity(0.6), lineWidth: isSelected ? 2 : 0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Special Requests card

    private var specialRequestsCard: some View {
        VStack(spacing: 0) {
            sectionHeader(icon: "square.and.pencil", title: "SPECIAL REQUESTS")

            ZStack(alignment: .topLeading) {
                if booking.hotelSpecialRequests.isEmpty {
                    Text("e.g. Quiet room, anniversary setup...")
                        .font(Font.custom("Inter", size: 16))
                        .foregroundColor(placeholderGray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $booking.hotelSpecialRequests)
                    .font(Font.custom("Inter", size: 16))
                    .foregroundColor(darkText)
                    .focused($isSpecialRequestsFocused)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minHeight: 120)
            }
            .background(rowFill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(16)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Terms Agreement

    private var termsAgreementRow: some View {
        Button(action: { booking.agreedToHotelTerms.toggle() }) {
            HStack(alignment: .top, spacing: 16) {
                checkbox(isOn: booking.agreedToHotelTerms)
                    .padding(.top, 2)

                (
                    Text("I agree to the ")
                        .foregroundColor(termsTextGray)
                    + Text("Terms of Service")
                        .foregroundColor(brandRed)
                    + Text(" and ")
                        .foregroundColor(termsTextGray)
                    + Text("Cancellation Policy")
                        .foregroundColor(brandRed)
                    + Text(". I understand that preferences are subject to availability.")
                        .foregroundColor(termsTextGray)
                )
                .font(Font.custom("Inter", size: 12))
                .lineSpacing(4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Previous / Next

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

            Button(action: { booking.showReviewBooking = true }) {
                HStack(spacing: 8) {
                    Text("NEXT")
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
        DummyTicketHotelAdditionalDetailsView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
