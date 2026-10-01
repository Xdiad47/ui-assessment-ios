import SwiftUI
import UIKit

// MARK: - DummyTicketHotelRouteDetailsView
// Figma: "Route Details" (node 3497:6972) — the Hotel flow's own step 1, reached from
// DummyTicketInitialView's BUY DUMMY TICKET button when HOTEL is the selected service type (see
// DummyTicketInitialView.routeDetailsDestination). NEXT pushes DummyTicketHotelPersonalDetailsView
// (Hotel's own step 2, labeled "Guest Details" in the stepper — node 3497:7146) — Additional
// Details / Review Booking / Payment (steps 3-5) onward ARE shared, unchanged, with the Flight
// flow. Mirrors DummyTicketRouteDetailsView's header/flowStepper/layout conventions closely; only
// "Select Trip Type" (Single/Couple/Family Stay here, not One Way/Round Trip/Multi City) and the
// Hotel Details / Hotel Summary cards differ.
//
// City/Check-in/Check-out were already set on DummyTicketInitialView, but — unlike Flight's Route
// Details, which shows From/To/Departure as a muted read-only recap — Figma renders all 6 fields
// here (City, Hotel Category, Check-in, Check-out, Rooms, Guests) as live inputs, so this screen
// lets the user refine any of them, not just the 3 new ones (Category/Rooms/Guests) that only
// exist here.

struct DummyTicketHotelRouteDetailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel
    @FocusState private var isCityFocused: Bool

    @State private var showCheckInPicker = false
    @State private var showCheckOutPicker = false
    @State private var showCategoryPicker = false
    @State private var showRoomsPicker = false
    @State private var showGuestsPicker = false

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let mutedGray = Color(red: 0.42, green: 0.447, blue: 0.502)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let fieldLabelGray = Color(red: 0.373, green: 0.369, blue: 0.369)

    private let categoryOptions = ["3 Star", "4 Star", "5 Star"]
    private let roomOptions = Array(1...5)
    private let guestOptions = Array(1...8)

    // Fixed placeholder amounts, matching Figma's own numbers — no live fare engine exists for a
    // "dummy ticket", same reasoning DummyTicketRouteDetailsView's Base Fare/GST/Total already use.
    private let roomFare = "₹499"
    private let gst = "₹90"
    private let totalAmount = "₹589"

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea(.container, edges: .vertical)

                VStack(spacing: 0) {
                    header(safeAreaTop: proxy.safeAreaInsets.top)

                    ScrollView(showsIndicators: false) {
                        content
                    }
                    .frame(maxHeight: .infinity)
                }

                NavigationLink(
                    destination: DummyTicketHotelPersonalDetailsView().environmentObject(booking),
                    isActive: $booking.showPersonalDetails
                ) {
                    EmptyView()
                }
                .hidden()
            }
            // .container, not the default .all — the City field is a real text field, so this
            // screen needs the same keyboard-aware scrolling fix as every other text-entry screen
            // in this flow (see DummyTicketInitialView for the full story).
            .ignoresSafeArea(.container, edges: .vertical)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCheckInPicker) {
            checkInDatePickerSheet
                .environmentObject(booking)
        }
        .sheet(isPresented: $showCheckOutPicker) {
            checkOutDatePickerSheet
                .environmentObject(booking)
        }
        .sheet(isPresented: $showCategoryPicker) {
            PickerSheetView(
                title: "Hotel Category",
                items: categoryOptions.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                onSelect: { booking.hotelCategory = $0.value }
            )
            .environmentObject(booking)
        }
        .sheet(isPresented: $showRoomsPicker) {
            PickerSheetView(
                title: "Rooms",
                items: roomOptions.map { IdentifiableString(value: "\($0)") },
                displayText: { $0.value },
                onSelect: { if let count = Int($0.value) { booking.roomsCount = count } }
            )
            .environmentObject(booking)
        }
        .sheet(isPresented: $showGuestsPicker) {
            PickerSheetView(
                title: "Guests",
                items: guestOptions.map { IdentifiableString(value: "\($0)") },
                displayText: { $0.value },
                onSelect: { if let count = Int($0.value) { booking.guestsCount = count } }
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

    // MARK: - Header (back row + 5-step progress) — identical to DummyTicketRouteDetailsView's

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
        // Step 2 reads "Guest\nDetails" here, not "Passenger\nDetails" — matching
        // DummyTicketHotelPersonalDetailsView's own stepper (node 3497:7146), which relabels this
        // step for the Hotel flow specifically. The original Route Details frame (node 3497:6972)
        // this screen was built from still said "Passenger Details" on its own stepper, but
        // showing two different labels for the same step across two screens in the same flow
        // would read as a bug, so this follows the newer, Hotel-specific wording consistently.
        let currentStep = 1
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
            VStack(alignment: .leading, spacing: 12) {
                Text("Route Details")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .tracking(-0.75)
                    .foregroundColor(darkText)

                Text("Select Trip Type")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                    .foregroundColor(darkText)

                stayTypeSelector
            }

            hotelDetailsCard
            hotelSummaryCard
            nextButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(24, tabBarState.height + 16))
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
        // Tap outside the City field to dismiss the keyboard — same established pattern as every
        // other text-entry screen in this flow.
        .contentShape(Rectangle())
        .onTapGesture {
            isCityFocused = false
        }
    }

    // MARK: - Stay type selector

    private var stayTypeSelector: some View {
        HStack(spacing: 8) {
            stayTypeButton(.single, label: "Single Stay", icon: "person.fill")
            stayTypeButton(.couple, label: "Couple Stay", icon: "person.2.fill")
            stayTypeButton(.family, label: "Family Stay", icon: "figure.2.and.child.holdinghands")
        }
    }

    private func stayTypeButton(_ type: DummyTicketStayType, label: String, icon: String) -> some View {
        let isSelected = booking.selectedStayType == type
        return Button(action: { booking.selectedStayType = type }) {
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

    // MARK: - Hotel details card

    private var hotelDetailsCard: some View {
        VStack(spacing: 0) {
            Text("Hotel Details")
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .tracking(-0.45)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(darkCard)

            VStack(spacing: 24) {
                hotelFieldBlock(label: "CITY") {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14))
                            .foregroundColor(mutedGray)
                        TextField("Enter City", text: $booking.hotelCity)
                            .font(Font.custom("Inter", size: 14).weight(.semibold))
                            .foregroundColor(darkText)
                            .focused($isCityFocused)
                    }
                }

                hotelDropdownBlock(label: "HOTEL CATEGORY", icon: "star.fill", value: booking.hotelCategory) {
                    showCategoryPicker = true
                }

                HStack(spacing: 16) {
                    hotelDateBlock(label: "CHECK-IN", value: booking.checkInDateText) { showCheckInPicker = true }
                    hotelDateBlock(label: "CHECK-OUT", value: booking.checkOutDateText) { showCheckOutPicker = true }
                }

                HStack(spacing: 16) {
                    hotelCounterBlock(label: "ROOMS", value: "\(booking.roomsCount)") { showRoomsPicker = true }
                    hotelCounterBlock(label: "GUESTS", value: booking.guestsText) { showGuestsPicker = true }
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func hotelFieldBlock<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 10))
                .tracking(1)
                .foregroundColor(fieldLabelGray)

            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor, lineWidth: 0.8))
        }
    }

    private func hotelDropdownBlock(label: String, icon: String, value: String, action: @escaping () -> Void) -> some View {
        hotelFieldBlock(label: label) {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(brandRed)
                    Text(value)
                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                        .foregroundColor(darkText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(mutedGray)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func hotelDateBlock(label: String, value: String, action: @escaping () -> Void) -> some View {
        hotelFieldBlock(label: label) {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                        .foregroundColor(mutedGray)
                    Text(value)
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(darkText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private func hotelCounterBlock(label: String, value: String, action: @escaping () -> Void) -> some View {
        hotelFieldBlock(label: label) {
            Button(action: action) {
                HStack {
                    Text(value)
                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                        .foregroundColor(darkText)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(mutedGray)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Hotel summary card

    private var hotelSummaryCard: some View {
        VStack(spacing: 0) {
            Text("Hotel Summary")
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(brandRed)

            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(booking.hotelCity.isEmpty ? "—" : booking.hotelCity)
                            .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                            .foregroundColor(.white)
                        Text("\(booking.hotelCategory) Luxury Stay")
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(brandRed)
                }

                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    Text(booking.stayDateRangeText)
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                VStack(spacing: 16) {
                    fareRow(label: "Rooms x\(booking.roomsCount)", value: roomFare)
                    fareRow(label: "GST (18%)", value: gst)
                }
                .padding(.top, 4)
                .overlay(Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1), alignment: .top)

                HStack {
                    Text("Total")
                        .font(Font.custom("Inter-Bold", size: 18))
                        .foregroundColor(.white)
                    Spacer()
                    Text(totalAmount)
                        .font(Font.custom("Inter-Bold", size: 24))
                        .foregroundColor(brandRed)
                }
                .padding(.top, 16)
                .overlay(Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1), alignment: .top)
            }
            .padding(24)
        }
        .background(darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func fareRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Font.custom("Inter", size: 14).weight(.medium))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(Font.custom("Inter-Bold", size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
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

    // MARK: - Check-in / Check-out sheets

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

            // Can't check out before checking in — same reasoning as DummyTicketInitialView's
            // identical Check In/Check Out sheets.
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
        DummyTicketHotelRouteDetailsView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
