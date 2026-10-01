import SwiftUI
import UIKit

// MARK: - DummyTicketPaymentView
// Figma: "Payment" (node 3497:6604 for Flight; node 3497:7665 confirms Hotel reuses this exact
// same screen — "same dropdown like earlier", per the user, just with its own Order Details
// amounts) — step 5 of 5 of the Dummy Tickets booking flow, reached from either
// DummyTicketReviewBookingView's or DummyTicketHotelReviewBookingView's Process Payment button.
// No real payment gateway exists (and shouldn't be faked here — no card-number capture, nothing
// that looks like a live checkout), so MAKE PAYMENT doesn't submit anything — it just calls
// booking.confirmBooking() (which branches its generated booking reference format by
// selectedServiceType) and pushes whichever confirmation screen matches: Flight/Both go to
// DummyTicketConfirmationView (node 3470:4453), Hotel goes to its own
// DummyTicketHotelConfirmationView (node 3497:7780) — see confirmationDestination below. The
// header's back chevron is the only way back — unlike steps 2-4, this Figma frame's footer has no
// separate PREVIOUS button, just MAKE PAYMENT.
//
// The Order Details card branches on selectedServiceType. Flight's amounts intentionally do NOT
// copy that Figma frame's own ₹700/₹125 sub-totals verbatim — every other Flight screen in this
// flow (Route Details through Review Booking) uses ₹699 base + ₹126 GST (+ ₹199 when Urgent
// Processing is on), and that frame's slightly different numbers still land on the same ₹825
// total, so they read as a designer rounding inconsistency between separately-authored Figma
// frames rather than a deliberate different price. Hotel's amounts likewise don't copy node
// 3497:7665's own Order Summary sample ("Passport Renewal Service" ₹22,500 — an unrelated,
// clearly-reused placeholder component) — they match DummyTicketHotelReviewBookingView's own
// Payment Summary card instead (₹24,000 base + ₹4,320 GST & Convenience Fee + ₹450 Eco-Tourism
// Tax = ₹28,770.00), so the total a user reviewed on the previous screen can't silently change on
// the very next one, for either flow.

struct DummyTicketPaymentView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel
    @FocusState private var focusedField: Field?

    @State private var selectedMethod: PaymentMethod? = nil
    @State private var billingState: String? = nil
    @State private var showStatePicker = false
    @State private var orderID: String = DummyTicketPaymentView.generateOrderID()

    // Card fields — kept as transient @State only, never persisted (no @AppStorage, no
    // UserDefaults, no Keychain) since there's no real payment gateway behind this screen.
    @State private var cardNumber: String = ""
    @State private var cardHolderName: String = ""
    @State private var expiryDate: String = ""
    @State private var cvv: String = ""

    @State private var upiID: String = ""

    @State private var selectedBank: String? = nil
    @State private var showBankPicker = false

    private enum Field {
        case cardNumber, cardHolderName, expiryDate, cvv, upiID
    }

    private enum PaymentMethod: String, CaseIterable, Identifiable {
        case card = "Debit / Credit Card"
        case netBanking = "Net Banking"
        case upi = "UPI"

        var id: String { rawValue }

        var subtitle: String {
            switch self {
            case .card: return "Visa, MasterCard, RuPay"
            case .netBanking: return "All major banks supported"
            case .upi: return "Google Pay, PhonePe, Paytm"
            }
        }

        var icon: String {
            switch self {
            case .card: return "creditcard.fill"
            case .netBanking: return "building.columns.fill"
            case .upi: return "qrcode"
            }
        }
    }

    private let banks = [
        "State Bank of India", "HDFC Bank", "ICICI Bank", "Axis Bank", "Punjab National Bank",
        "Bank of Baroda", "Kotak Mahindra Bank", "IndusInd Bank", "Yes Bank", "IDFC FIRST Bank",
        "Union Bank of India", "Canara Bank"
    ]

    private let indianStates = [
        "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa", "Gujarat",
        "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh",
        "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab",
        "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand",
        "West Bengal", "Andaman and Nicobar Islands", "Chandigarh",
        "Dadra and Nagar Haveli and Daman and Diu", "Delhi", "Jammu and Kashmir", "Ladakh",
        "Lakshadweep", "Puducherry"
    ]

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let mutedText = Color(red: 0.373, green: 0.369, blue: 0.369)
    private let captionGray = Color(red: 0.612, green: 0.639, blue: 0.686)

    private let baseFare = 699
    private let gst = 126
    private let urgentFee = 199
    private var totalAmount: Int { baseFare + gst + (booking.isUrgentProcessing ? urgentFee : 0) }

    // Hotel's own fixed amounts — matches DummyTicketHotelReviewBookingView's Payment Summary
    // card exactly (see this file's header comment for why these, not node 3497:7665's own
    // mismatched "Passport Renewal Service" sample).
    private let hotelBaseFareText = "₹24,000.00"
    private let hotelGstText = "₹4,320.00"
    private let hotelTaxText = "₹450.00"
    private let hotelTotalText = "₹28,770.00"

    private var canProceed: Bool { selectedMethod != nil && billingState != nil }

    private static func generateOrderID() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea(.container, edges: .vertical)

                VStack(spacing: 0) {
                    header(safeAreaTop: proxy.safeAreaInsets.top)

                    ScrollView(showsIndicators: false) {
                        content
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                NavigationLink(
                    destination: confirmationDestination,
                    isActive: $booking.showConfirmation
                ) {
                    EmptyView()
                }
                .hidden()
            }
            // .container, not the default .all — the expanded Card/UPI panels have real text
            // fields now, and .all also covers .keyboard, which is exactly what stopped this
            // screen's ScrollView from being keyboard-aware on DummyTicketInitialView. See that
            // file's comment for the full story.
            .ignoresSafeArea(.container, edges: .vertical)
            .animation(.easeInOut(duration: 0.2), value: selectedMethod)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showStatePicker) {
            PickerSheetView(
                title: "Billing State",
                items: indianStates.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                isSearchable: true,
                onSelect: { billingState = $0.value }
            )
        }
        .sheet(isPresented: $showBankPicker) {
            PickerSheetView(
                title: "Choose Your Bank",
                items: banks.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                isSearchable: true,
                onSelect: { selectedBank = $0.value }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            tabBarState.isHidden = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            tabBarState.isHidden = false
        }
        .onDisappear {
            tabBarState.isHidden = false
        }
    }

    // Hotel gets its own confirmation screen (node 3497:7780, distinct "BOOKING DETAILS" card and
    // booking-reference format) — Flight/Both keep going to the original one.
    @ViewBuilder
    private var confirmationDestination: some View {
        if booking.selectedServiceType == .hotel {
            DummyTicketHotelConfirmationView().environmentObject(booking)
        } else {
            DummyTicketConfirmationView().environmentObject(booking)
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
        // All 5 circles render completed — this is the flow's last step, and every earlier screen
        // showed the CURRENT step with the same checkmark styling as a completed one (confirmed
        // across steps 2-4), so step 5 follows the same rule here.
        let currentStep = 5
        // Step 2 reads "Guest\nDetails" for a Hotel booking, matching every other Hotel screen's
        // own stepper (this one screen is shared between both flows, so it's the one place this
        // needs to branch instead of just being a fixed string).
        let step2Label = booking.selectedServiceType == .hotel ? "Guest\nDetails" : "Passenger\nDetails"
        let steps: [(number: Int, label: String)] = [
            (1, "Route\nDetails"),
            (2, step2Label),
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
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Payment Method")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .foregroundColor(darkText)

                VStack(spacing: 12) {
                    ForEach(PaymentMethod.allCases) { method in
                        paymentMethodRow(method)
                    }
                }

                billingStateField
            }

            orderDetailsCard

            makePaymentButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(16, tabBarState.height + 16))
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
        // Tap outside any field/button to dismiss the keyboard — same established pattern as
        // every other screen with text input in this flow.
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
    }

    // MARK: - Payment method selector

    private func paymentMethodRow(_ method: PaymentMethod) -> some View {
        let isSelected = selectedMethod == method
        return VStack(spacing: 8) {
            Button(action: {
                if isSelected {
                    selectedMethod = nil
                } else {
                    selectedMethod = method
                }
                focusedField = nil
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(iconBackground(for: method, isSelected: isSelected))
                            .frame(width: 48, height: 48)
                        Image(systemName: method.icon)
                            .font(.system(size: 18))
                            .foregroundColor(brandRed)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(method.rawValue)
                            .font(Font.custom("Inter-Bold", size: 16))
                            .foregroundColor(darkText)
                        Text(method.subtitle)
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(mutedText)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(darkText.opacity(0.6))
                }
                .padding(20)
                .background(Color.white)
                // Unselected rows use a plain gray border, not red — the overview screen's export
                // showed all three with a red border simultaneously, but the per-method detail
                // frames make clear that's only the expanded/selected state; collapsed is gray.
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? brandRed : strokeColor, lineWidth: isSelected ? 1.5 : 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            if isSelected {
                expandedPanel(for: method)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // Card keeps the same pink tint whether selected or not (its unselected/selected frames use
    // near-identical pinks); UPI/Net Banking switch from a neutral gray to a red tint only once
    // selected, per the detail frames.
    private func iconBackground(for method: PaymentMethod, isSelected: Bool) -> Color {
        switch method {
        case .card:
            return brandRed.opacity(0.1)
        case .upi, .netBanking:
            return isSelected ? brandRed.opacity(0.1) : Color(red: 0.882, green: 0.890, blue: 0.898)
        }
    }

    @ViewBuilder
    private func expandedPanel(for method: PaymentMethod) -> some View {
        switch method {
        case .card: cardExpandedPanel
        case .upi: upiExpandedPanel
        case .netBanking: netBankingExpandedPanel
        }
    }

    private var expandedPanelBackground: Color { Color(red: 0.976, green: 0.980, blue: 0.984) }

    // MARK: - Debit / Credit Card panel

    private var cardExpandedPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            expandedField(label: "Card Number", text: $cardNumber, placeholder: "0000 0000 0000 0000", keyboardType: .numberPad, focus: .cardNumber)
                .onChange(of: cardNumber) { _, newValue in
                    let formatted = Self.formattedCardNumber(newValue)
                    if formatted != newValue { cardNumber = formatted }
                }

            expandedField(label: "Card Holder Name", text: $cardHolderName, placeholder: "Enter name on card", focus: .cardHolderName)

            HStack(spacing: 16) {
                expandedField(label: "Expiry Date", text: $expiryDate, placeholder: "MM / YY", keyboardType: .numberPad, focus: .expiryDate)
                    .onChange(of: expiryDate) { _, newValue in
                        let formatted = Self.formattedExpiry(newValue)
                        if formatted != newValue { expiryDate = formatted }
                    }

                expandedField(label: "CVV", text: $cvv, placeholder: "123", keyboardType: .numberPad, focus: .cvv, isSecure: true)
                    .onChange(of: cvv) { _, newValue in
                        let formatted = String(newValue.filter(\.isNumber).prefix(4))
                        if formatted != newValue { cvv = formatted }
                    }
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 20)
        .background(expandedPanelBackground)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private static func formattedCardNumber(_ raw: String) -> String {
        let digits = String(raw.filter(\.isNumber).prefix(16))
        var result = ""
        for (index, character) in digits.enumerated() {
            if index != 0 && index % 4 == 0 { result += " " }
            result.append(character)
        }
        return result
    }

    private static func formattedExpiry(_ raw: String) -> String {
        let digits = String(raw.filter(\.isNumber).prefix(4))
        guard digits.count > 2 else { return digits }
        let month = digits.prefix(2)
        let year = digits.suffix(digits.count - 2)
        return "\(month)/\(year)"
    }

    private func expandedField(label: String, text: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default, focus: Field, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 14))
                .foregroundColor(darkText)

            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .font(Font.custom("Inter", size: 16))
            .keyboardType(keyboardType)
            .focused($focusedField, equals: focus)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - UPI panel

    private var upiExpandedPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter your UPI ID")
                .font(Font.custom("Inter-Bold", size: 14))
                .foregroundColor(darkText)

            TextField("example@upi", text: $upiID)
                .font(Font.custom("Inter", size: 18))
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($focusedField, equals: .upiID)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 21)
        .background(expandedPanelBackground)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Net Banking panel

    private var netBankingExpandedPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter your Bank")
                .font(Font.custom("Inter-Bold", size: 14))
                .foregroundColor(darkText)

            Button(action: { showBankPicker = true }) {
                HStack {
                    Text(selectedBank ?? "Choose your bank")
                        .font(Font.custom("Inter", size: 16))
                        .foregroundColor(selectedBank == nil ? captionGray : darkText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(captionGray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 21)
        .background(expandedPanelBackground)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Billing state

    private var billingStateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BILLING STATE (GST COMPLIANCE)")
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(1)
                .foregroundColor(captionGray)

            Button(action: { showStatePicker = true }) {
                HStack {
                    Text(billingState ?? "Select your state")
                        .font(Font.custom("PlusJakartaSans-Regular", size: 16).weight(.medium))
                        .foregroundColor(billingState == nil ? captionGray : darkText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(captionGray)
                }
                .padding(.horizontal, 17)
                .frame(height: 48)
                .background(Color(red: 0.976, green: 0.980, blue: 0.984))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Order details card

    private var orderDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ORDER DETAILS")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .tracking(-0.45)
                    .foregroundColor(.white)
                Text("ID: \(orderID)")
                    .font(Font.custom("PlusJakartaSans-Regular", size: 10))
                    .foregroundColor(captionGray)
            }

            if booking.selectedServiceType == .both {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ITEMS")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 10))
                        .tracking(0.5)
                        .foregroundColor(captionGray)

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Flight + Hotel Dummy Booking")
                                .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                                .foregroundColor(.white)
                            Text("Combined Itinerary Package")
                                .font(Font.custom("PlusJakartaSans-Regular", size: 10))
                                .foregroundColor(captionGray)
                        }
                        Spacer()
                        Text("₹24,000.00")
                            .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                            .foregroundColor(.white)
                    }
                }
            } else if booking.selectedServiceType == .hotel {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ITEMS")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 10))
                        .tracking(0.5)
                        .foregroundColor(captionGray)

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hotel Booking Charges")
                                .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                                .foregroundColor(.white)
                            Text("\(booking.stayNights) Night\(booking.stayNights == 1 ? "" : "s") x \(booking.roomsCount) Room\(booking.roomsCount == 1 ? "" : "s")")
                                .font(Font.custom("PlusJakartaSans-Regular", size: 10))
                                .foregroundColor(captionGray)
                        }
                        Spacer()
                        Text(hotelBaseFareText)
                            .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                            .foregroundColor(.white)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ITEMS")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 10))
                        .tracking(0.5)
                        .foregroundColor(captionGray)

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dummy Ticket Charges")
                                .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                                .foregroundColor(.white)
                            Text("Standard Service x 1")
                                .font(Font.custom("PlusJakartaSans-Regular", size: 10))
                                .foregroundColor(captionGray)
                        }
                        Spacer()
                        Text("₹\(baseFare).00")
                            .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                            .foregroundColor(.white)
                    }
                }
            }

            VStack(spacing: 8) {
                if booking.selectedServiceType == .both {
                    orderRow(label: "Flight Itinerary", value: "₹ 24,000.00")
                    orderRow(label: "Hotel Itinerary", value: "₹ 24,000.00")
                    orderRow(label: "GST & Convenience Fee", value: hotelGstText)
                    orderRow(label: "Eco-Tourism Tax", value: hotelTaxText)
                } else if booking.selectedServiceType == .hotel {
                    orderRow(label: "Base Fare (\(booking.stayNights) Nights)", value: hotelBaseFareText)
                    orderRow(label: "GST & Convenience Fee", value: hotelGstText)
                    orderRow(label: "Eco-Tourism Tax", value: hotelTaxText)
                } else {
                    orderRow(label: "Passengers (1)", value: "₹\(baseFare).00")
                    if booking.isUrgentProcessing {
                        orderRow(label: "Urgent Processing", value: "₹\(urgentFee).00")
                    }
                    orderRow(label: "GST (18%)", value: "₹\(gst).00")
                }
            }
            .padding(.top, 8)
            .overlay(Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1), alignment: .top)

            HStack(alignment: .firstTextBaseline) {
                Text("Total Amount")
                    .font(Font.custom("Inter-Bold", size: 18))
                    .foregroundColor(.white)
                Spacer()
                Text(booking.selectedServiceType == .hotel || booking.selectedServiceType == .both ? hotelTotalText : "₹\(totalAmount).00")
                    .font(Font.custom("Inter-Bold", size: 22))
                    .tracking(-0.6)
                    .foregroundColor(brandRed)
            }
            .padding(.top, 8)
            .overlay(Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1), alignment: .top)

            (
                Text("Secure checkout powered by Itzeazy. By proceeding you agree to our ")
                    .foregroundColor(Color(red: 0.42, green: 0.447, blue: 0.502))
                + Text("Terms of Service.")
                    .foregroundColor(brandRed)
            )
            .font(Font.custom("PlusJakartaSans-Regular", size: 9))
            .padding(.top, 8)
            .overlay(Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1), alignment: .top)
            .onTapGesture {
                guard let url = URL(string: "https://itzeazy.in/terms") else { return }
                UIApplication.shared.open(url)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .background(darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func orderRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Font.custom("PlusJakartaSans-Regular", size: 14))
                .foregroundColor(captionGray)
            Spacer()
            Text(value)
                .font(Font.custom("PlusJakartaSans-Regular", size: 14).weight(.medium))
                .foregroundColor(.white)
        }
    }

    // MARK: - Make Payment

    private var makePaymentButton: some View {
        Button(action: {
            guard canProceed else { return }
            booking.confirmBooking()
        }) {
            Text("MAKE PAYMENT")
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 16))
                .tracking(1.6)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(canProceed ? brandRed : brandRed.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationView {
        DummyTicketPaymentView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
