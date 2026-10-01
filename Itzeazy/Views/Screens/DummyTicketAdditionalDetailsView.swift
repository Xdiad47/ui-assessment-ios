import SwiftUI
import UIKit

// MARK: - DummyTicketAdditionalDetailsView
// Figma: "Additional Details" (node 3470:3948) — step 3 of 5 in the Dummy Tickets booking flow,
// reached from DummyTicketPersonalDetailsView's NEXT button. NEXT pushes
// DummyTicketReviewBookingView (step 4). Payment (step 5) hasn't been designed yet.
// PREVIOUS pops back to Personal Details.
//
// Reads/writes DummyTicketBookingViewModel (shared across the whole flow via .environmentObject)
// instead of taking init parameters or holding its own local copies — Review Booking's Services
// Selected / Payment Summary sections depend on this screen's own state (isUrgentProcessing,
// sendEmailPDFCopy, sendWhatsAppCopy), so those need to live on the shared model too, not just the
// passenger/contact fields carried over from Personal Details.
//
// The Urgent Processing toggle is the one genuinely interactive piece of pricing on this screen —
// unlike the hardcoded base fare carried over from earlier steps, the Order Summary's "Urgent
// Processing" line and Total Amount actually react to it, since that's the toggle's entire
// purpose and leaving it inert would look broken.
//
// Has real text input (Special Instructions), so it carries the same three keyboard fixes
// DummyTicketInitialView/DummyTicketPersonalDetailsView needed: tap-outside-to-dismiss,
// .container-scoped ignoresSafeArea so the keyboard doesn't blind the ScrollView, and hiding
// MainTabView's tab bar for the keyboard's duration.

struct DummyTicketAdditionalDetailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel
    @FocusState private var focusedField: Field?

    @State private var showPurposePicker = false
    @State private var showComingSoonToast = false

    private enum Field {
        case specialInstructions
    }

    private let purposeOptions = ["Tourist", "Business", "Visa Application", "Other"]

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let sectionLabelGray = Color(red: 0.373, green: 0.369, blue: 0.369)
    private let placeholderGray = Color(red: 0.42, green: 0.447, blue: 0.502)

    // Base fare carried over unchanged from Route Details/Personal Details (₹825, incl. GST) —
    // Urgent Processing is the only genuinely optional add-on on this screen, so it's the only
    // piece of the total that's actually computed rather than a fixed mock number.
    private let baseAmount = 825
    private let urgentFee = 199
    private var totalAmount: Int { baseAmount + (booking.isUrgentProcessing ? urgentFee : 0) }

    private var ticketTypeLabel: String {
        switch booking.selectedTripType {
        case .oneWay: return "One-Way Ticket"
        case .roundTrip: return "Round Trip Ticket"
        case .multiTrip: return "Multi City Ticket"
        }
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

                if showComingSoonToast {
                    VStack {
                        Spacer()
                        ToastView(icon: "hourglass", message: "Coming soon! We're working hard to bring this to you.")
                            .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                NavigationLink(
                    destination: DummyTicketReviewBookingView().environmentObject(booking),
                    isActive: $booking.showReviewBooking
                ) {
                    EmptyView()
                }
                .hidden()
            }
            // .container, not the default .all — see DummyTicketPersonalDetailsView for why an
            // unscoped call (which also covers .keyboard) breaks scrolling once a field is focused.
            .ignoresSafeArea(.container, edges: .vertical)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showComingSoonToast)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPurposePicker) {
            PickerSheetView(
                title: "Choose Travel Purpose",
                items: purposeOptions.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                onSelect: { booking.travelPurpose = $0.value }
            )
            .environmentObject(booking)
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

    private func showComingSoon() {
        showComingSoonToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { showComingSoonToast = false }
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
        VStack(alignment: .leading, spacing: 24) {
            Text("Additional Details")
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .tracking(-0.75)
                .foregroundColor(darkText)

            formCard
            orderSummaryCard
            navigationButtons
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(24, tabBarState.height + 16))
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
    }

    // MARK: - Form card

    private var formCard: some View {
        VStack(spacing: 24) {
            travelPurposeField
            specialInstructionsField
            deliveryPreferencesSection
            urgentProcessingCard
            infoNote
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 24)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Font.custom("Inter-Bold", size: 12))
            .tracking(1.2)
            .foregroundColor(sectionLabelGray)
    }

    private var travelPurposeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TRAVEL PURPOSE")

            Button(action: { showPurposePicker = true }) {
                HStack {
                    Text(booking.travelPurpose ?? "Select Purpose")
                        .font(Font.custom("Inter", size: 16).weight(.medium))
                        .foregroundColor(booking.travelPurpose == nil ? placeholderGray : darkText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(placeholderGray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 0.6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    private var specialInstructionsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("SPECIAL INSTRUCTIONS")

            ZStack(alignment: .topLeading) {
                if booking.specialInstructions.isEmpty {
                    Text("e.g. Need embassy-ready reservation for visa application")
                        .font(Font.custom("Inter", size: 16))
                        .foregroundColor(placeholderGray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $booking.specialInstructions)
                    .font(Font.custom("Inter", size: 16))
                    .focused($focusedField, equals: .specialInstructions)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minHeight: 100)
            }
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var deliveryPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("DELIVERY PREFERENCES")
            checkboxRow(label: "Send WhatsApp Ticket Copy", isChecked: $booking.sendWhatsAppCopy, isEmphasized: false)
            checkboxRow(label: "Email PDF Copy (Official Letterhead)", isChecked: $booking.sendEmailPDFCopy, isEmphasized: true)
        }
    }

    private func checkboxRow(label: String, isChecked: Binding<Bool>, isEmphasized: Bool) -> some View {
        Button(action: { isChecked.wrappedValue.toggle() }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isChecked.wrappedValue ? brandRed : Color.white)
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isChecked.wrappedValue ? Color.clear : sectionLabelGray, lineWidth: 1)
                    if isChecked.wrappedValue {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 20, height: 20)

                Text(label)
                    .font(Font.custom(isEmphasized ? "Inter-Bold" : "Inter", size: 14))
                    .foregroundColor(isEmphasized ? brandRed : darkText)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .padding(isEmphasized ? 17 : 16)
            .background(isEmphasized ? brandRed.opacity(0.1) : Color.white)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(isEmphasized ? brandRed.opacity(0.1) : strokeColor, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private var urgentProcessingCard: some View {
        HStack(spacing: 16) {
            Toggle("", isOn: $booking.isUrgentProcessing)
                .labelsHidden()
                .tint(brandRed)

            VStack(alignment: .leading, spacing: 2) {
                Text("Urgent Processing")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                    .foregroundColor(darkText)
                Text("FAST-TRACK DELIVERY")
                    .font(Font.custom("Inter-Bold", size: 10))
                    .tracking(0.5)
                    .foregroundColor(brandRed)
            }

            Spacer(minLength: 8)

            Text("+₹\(urgentFee)")
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 16))
                .foregroundColor(brandRed)
        }
        .padding(.leading, 16)
        .padding(.trailing, 20)
        .padding(.vertical, 18)
        .background(Color(red: 1, green: 0.902, blue: 0.902))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(brandRed.opacity(0.1), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var infoNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0, green: 0.294, blue: 0.439))
            Text("Embassy-ready reservations are typically delivered within 30–60 minutes during working hours (9 AM – 9 PM IST).")
                .font(Font.custom("Inter", size: 12).weight(.medium))
                .foregroundColor(Color(red: 0, green: 0.294, blue: 0.439))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 17)
        .background(Color(red: 0.792, green: 0.902, blue: 1).opacity(0.3))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.792, green: 0.902, blue: 1).opacity(0.5), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Order summary card

    private var orderSummaryCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Text("Order Summary")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(brandRed)

            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ticketTypeLabel)
                            .font(Font.custom("Inter-Bold", size: 14))
                            .foregroundColor(.white)
                        // No fabricated "(BOM)"/"(CDG)" airport codes — just the plain city text
                        // typed on the first screen, same honesty call made on the earlier
                        // Flight Summary cards.
                        Text("\(booking.fromLocation.isEmpty ? "—" : booking.fromLocation) → \(booking.toLocation.isEmpty ? "—" : booking.toLocation)")
                            .font(Font.custom("Inter", size: 12))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    Spacer()
                    Text("₹\(baseAmount)")
                        .font(Font.custom("Inter-Bold", size: 14))
                        .foregroundColor(.white)
                }

                summaryRow(label: "Service Fee", value: "Included")

                if booking.isUrgentProcessing {
                    summaryRow(label: "Urgent Processing", value: "₹\(urgentFee)", labelColor: brandRed, valueColor: brandRed)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("Total Amount")
                            .font(Font.custom("Inter-Bold", size: 18))
                            .foregroundColor(.white)
                        Spacer()
                        Text("₹\(totalAmount)")
                            .font(Font.custom("Inter-Bold", size: 24))
                            .foregroundColor(brandRed)
                    }
                    Text("*GST included in final price")
                        .font(Font.custom("Inter", size: 10).italic())
                        .foregroundColor(.white)
                }
                .padding(.top, 16)
                .overlay(
                    DashedLine()
                        .stroke(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 0.8, dash: [4, 3]))
                        .frame(height: 1),
                    alignment: .top
                )
            }
            .padding(20)
        }
        .background(darkCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor.opacity(0.6), lineWidth: 0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func summaryRow(label: String, value: String, labelColor: Color = .white, valueColor: Color = .white) -> some View {
        HStack {
            Text(label)
                .font(Font.custom("Inter", size: 14))
                .foregroundColor(labelColor)
            Spacer()
            Text(value)
                .font(Font.custom("Inter-Bold", size: 14))
                .foregroundColor(valueColor)
        }
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

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

#Preview {
    NavigationView {
        DummyTicketAdditionalDetailsView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
