import SwiftUI

// MARK: - DummyTicketBothReviewBookingView
// Figma: "Review Your Booking" (node 3497:8554) — step 4 of 5 in the Both (Flight + Hotel)
// dummy ticket booking flow, reached from DummyTicketBothAdditionalDetailsView's NEXT button.
//
// Features on this screen:
// 1. Top navigation shell with back button, title, notification bell, and 5-step stepper:
//    Route Details (1) -> Passenger Details (2) -> Additional Details (3) -> Review Booking (4, active) -> Payment (5).
// 2. Flight Details card:
//    - Dark header bar with white circular airplane badge and "Flight Details", "Air France • Economy"
//    - Flight path layout with Departure code (e.g. DEL, 02:15 AM), center non-stop duration line,
//      and Arrival code (e.g. CDG, 08:10 AM)
// 3. Hotel Selection card:
//    - Dark header bar with hotel badge and "Hotel Selection", "Hôtel Plaza Athénée Paris"
//    - Luxury hotel room thumbnail (`hotel_review_photo`), room type ("Deluxe Junior Suite"),
//      stay duration & nights (e.g. Oct 12 - Oct 16 (4 Nights)), and "Breakfast Included" badge
// 4. Travelers card:
//    - Dark header bar with travelers badge, "Travelers", traveler count (e.g. "2 Adults"), and "Edit" action
//    - One row per real traveler: the lead passenger (booking.passengerName, always shown, "—" if not
//      yet filled in) plus one row per booking.additionalPassengers entry actually added via
//      "+ Add Passenger" on Personal Details — no fixed-count placeholder names, so a solo traveler
//      shows exactly one row, not two
// 5. Payment Summary card:
//    - Solid red header banner titled "Payment Summary"
//    - Breakdown: Flight Itinerary (₹ 24,000.00), Hotel Itinerary (₹ 24,000.00),
//      GST & Convenience Fee (₹ 4,320.00), Eco-Tourism Tax (₹ 450.00)
//    - TOTAL amount highlight (₹ 28,770.00)
//    - Free cancellation advisory note box
// 6. Footer Buttons:
//    - PREVIOUS: pops back to DummyTicketBothAdditionalDetailsView
//    - Process Payment: pushes DummyTicketPaymentView (Step 5)

struct DummyTicketBothReviewBookingView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let mutedText = Color(red: 0.373, green: 0.369, blue: 0.369)
    private let avatarFill = Color(red: 0.882, green: 0.890, blue: 0.894)
    private let flightLineColor = Color(red: 0.91, green: 0.74, blue: 0.72).opacity(0.5)

    // Dynamic or graceful fallback computed properties
    private var departureCode: String {
        let loc = booking.fromLocation.trimmingCharacters(in: .whitespaces)
        if loc.isEmpty { return "DEL" }
        return loc.count == 3 ? loc.uppercased() : String(loc.prefix(3)).uppercased()
    }

    private var destinationCode: String {
        let loc = booking.toLocation.trimmingCharacters(in: .whitespaces)
        if loc.isEmpty { return "CDG" }
        return loc.count == 3 ? loc.uppercased() : String(loc.prefix(3)).uppercased()
    }

    private var hotelStayText: String {
        guard let checkIn = booking.checkInDate, let checkOut = booking.checkOutDate else {
            return "Oct 12 - Oct 16 (4 Nights)"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let nights = max(1, Calendar.current.dateComponents([.day], from: checkIn, to: checkOut).day ?? 1)
        return "\(formatter.string(from: checkIn)) - \(formatter.string(from: checkOut)) (\(nights) \(nights == 1 ? "Night" : "Nights"))"
    }

    private var travelersCountText: String {
        let count = 1 + booking.additionalPassengers.count
        return count == 1 ? "1 Adult" : "\(count) Adults"
    }

    private var leadPassengerName: String {
        let name = booking.passengerName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "— (Lead)" : "\(name) (Lead)"
    }

    private func initials(for name: String) -> String {
        let clean = name.replacingOccurrences(of: "(Lead)", with: "").trimmingCharacters(in: .whitespaces)
        let parts = clean.split(separator: " ").map(String.init)
        if parts.count >= 2, let first = parts.first?.first, let last = parts.last?.first {
            return "\(first)\(last)".uppercased()
        } else if let first = parts.first?.prefix(2) {
            return String(first).uppercased()
        }
        return "PA"
    }

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
        VStack(alignment: .leading, spacing: 16) {
            Text("Review Your Booking")
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .tracking(-0.75)
                .foregroundColor(darkText)

            flightDetailsCard
            hotelSelectionCard
            travelersCard
            paymentSummaryCard
            navigationButtons
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(24, tabBarState.height + 16))
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Card 1: Flight Details

    private var flightDetailsCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                    Image(systemName: "airplane")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(brandRed)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Flight Details")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                        .foregroundColor(.white)
                    Text("Air France • Economy")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(darkCard)

            HStack(alignment: .center, spacing: 12) {
                VStack(spacing: 4) {
                    Text(departureCode)
                        .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                        .foregroundColor(darkText)
                    Text("02:15 AM")
                        .font(Font.custom("Inter", size: 10).weight(.medium))
                        .foregroundColor(Color(hex: "#5f5e5e"))
                        .textCase(.uppercase)
                }
                .frame(minWidth: 50)

                VStack(spacing: 8) {
                    ZStack {
                        Rectangle()
                            .fill(flightLineColor)
                            .frame(height: 1)
                        Image(systemName: "airplane")
                            .font(.system(size: 11))
                            .foregroundColor(brandRed)
                            .background(Color.white.padding(.horizontal, 4))
                    }

                    Text("9h 25m • Non-stop")
                        .font(Font.custom("Inter", size: 9))
                        .foregroundColor(Color(hex: "#5f5e5e"))
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text(destinationCode)
                        .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                        .foregroundColor(darkText)
                    Text("08:10 AM")
                        .font(Font.custom("Inter", size: 10).weight(.medium))
                        .foregroundColor(Color(hex: "#5f5e5e"))
                        .textCase(.uppercase)
                }
                .frame(minWidth: 50)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color.white)
        }
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Card 2: Hotel Selection

    private var hotelSelectionCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(brandRed)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Hotel Selection")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                        .foregroundColor(.white)
                    Text(booking.hotelCity.isEmpty ? "Hôtel Plaza Athénée Paris" : "Hotel Plaza \(booking.hotelCity)")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(darkCard)

            HStack(alignment: .top, spacing: 16) {
                Image("hotel_review_photo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Deluxe Junior Suite")
                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                        .foregroundColor(darkText)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#5f5e5e"))
                        Text(hotelStayText)
                            .font(Font.custom("Inter", size: 12))
                            .foregroundColor(Color(hex: "#5f5e5e"))
                    }

                    if booking.hotelWantsFreeBreakfast {
                        Text("Breakfast Included")
                            .font(Font.custom("Inter", size: 12).weight(.medium))
                            .foregroundColor(Color(hex: "#b01"))
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color.white)
        }
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Card 3: Travelers

    private var travelersCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16))
                        .foregroundColor(brandRed)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Travelers")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                        .foregroundColor(.white)
                    Text(travelersCountText)
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Button(action: { booking.editPersonal() }) {
                    Text("Edit")
                        .font(Font.custom("Inter-Bold", size: 12))
                        .foregroundColor(brandRed)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(darkCard)

            VStack(spacing: 12) {
                travelerRow(name: leadPassengerName)

                // Only passengers actually added via "+ Add Passenger" on Personal Details show up
                // here — no fixed-count placeholder row, so a solo traveler shows just one row.
                ForEach(booking.additionalPassengers) { passenger in
                    let name = "\(passenger.firstName) \(passenger.lastName)".trimmingCharacters(in: .whitespaces)
                    travelerRow(name: name.isEmpty ? "—" : name)
                }
            }
            .padding(16)
            .background(Color.white)
        }
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func travelerRow(name: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(avatarFill)
                    .frame(width: 32, height: 32)
                Text(initials(for: name))
                    .font(Font.custom("Inter-Bold", size: 12))
                    .foregroundColor(Color(hex: "#5f5e5e"))
            }

            Text(name)
                .font(Font.custom("Inter", size: 14).weight(.medium))
                .foregroundColor(darkText)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor.opacity(0.3), lineWidth: 0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Card 4: Payment Summary

    private var paymentSummaryCard: some View {
        VStack(spacing: 0) {
            Text("Payment Summary")
                .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .frame(height: 60)
                .background(brandRed)

            VStack(spacing: 20) {
                paymentRow(label: "Flight Itinerary", value: "₹ 24,000.00")
                paymentRow(label: "Hotel Itinerary", value: "₹ 24,000.00")
                paymentRow(label: "GST & Convenience Fee", value: "₹ 4,320.00")
                paymentRow(label: "Eco-Tourism Tax", value: "₹ 450.00")

                HStack(alignment: .firstTextBaseline) {
                    Text("TOTAL")
                        .font(Font.custom("Inter", size: 20).weight(.heavy))
                        .tracking(1.2)
                        .foregroundColor(.white)
                    Spacer()
                    Text("₹28,770.00")
                        .font(Font.custom("Inter", size: 24).weight(.heavy))
                        .foregroundColor(.white)
                }
                .padding(.top, 16)
                .overlay(Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1), alignment: .top)

                // Free cancellation notice
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(brandRed)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Free cancellation available until Oct 22, 2023.")
                        Text("Post that, 1-night retention charges will apply.")
                    }
                    .font(Font.custom("Inter", size: 11))
                    .foregroundColor(Color(hex: "#d4d4d4"))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(20)
        }
        .background(darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func paymentRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Font.custom("Inter", size: 14).weight(.medium))
                .foregroundColor(Color.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(Font.custom("Inter", size: 14).weight(.semibold))
                .foregroundColor(.white)
        }
    }

    // MARK: - Footer Buttons

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
        .padding(.top, 8)
    }
}

#Preview {
    NavigationView {
        DummyTicketBothReviewBookingView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
