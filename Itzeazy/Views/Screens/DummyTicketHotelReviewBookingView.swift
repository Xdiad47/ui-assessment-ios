import SwiftUI

// MARK: - DummyTicketHotelReviewBookingView
// Figma: "Route Details" frame, shown on-screen as "Review Your Booking" (node 3497:7499) — the
// Hotel flow's own step 4, reached from DummyTicketHotelAdditionalDetailsView's NEXT button.
// Mirrors DummyTicketReviewBookingView's header/flowStepper conventions; every card here is
// Hotel-specific (Hotel Card w/ photo, Guest Information, Delivery Details, Payment Summary).
//
// The hotel photo is a real asset copied from Figma into Assets.xcassets/hotel_review_photo
// (512x512 source, cropped to the card's aspect ratio via .scaledToFill()+.clipped(), matching
// Figma's own cover-style crop) — not an SF Symbol placeholder, per the user's explicit request.
//
// Data honesty: Guest Information, Delivery Details' Service Method, and the Payment Summary's
// night count all read live values already collected earlier in the flow (booking.passengerName/
// emailAddress/phoneNumber, booking.deliveryMethod, booking.stayNights). The hotel's own
// name/location/star-photo and the Base Fare/GST/Eco-Tourism Tax/Total amounts have no live
// source anywhere in this flow (there's no "choose a hotel" or fare-calculation step), so — same
// reasoning as DummyTicketRouteDetailsView's own fixed Base Fare/GST/Total — they're kept as
// Figma's exact mock values rather than invented formulas. The one exception: the cancellation
// note's cutoff date is computed as 2 days before booking.checkInDate rather than copying Figma's
// literal "Oct 22, 2023" (a stale year that would visibly contradict every other date in this
// flow, which are all in the app's actual current date range).
//
// Process Payment pushes the shared DummyTicketPaymentView — no Hotel-specific Payment design has
// been provided yet.

struct DummyTicketHotelReviewBookingView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let darkText = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let mutedGray = Color(red: 0.373, green: 0.369, blue: 0.369)
    private let labelGray = Color(red: 0.639, green: 0.639, blue: 0.639)
    private let rowFill = Color(red: 0.906, green: 0.910, blue: 0.914).opacity(0.3)

    // Fixed placeholder amounts — no live fare engine exists for a "dummy ticket" (same reasoning
    // as DummyTicketRouteDetailsView's/DummyTicketHotelRouteDetailsView's own Base Fare/GST/Total).
    private let baseFare = "₹ 24,000.00"
    private let gstAndConvenienceFee = "₹ 4,320.00"
    private let ecoTourismTax = "₹ 450.00"
    private let totalAmount = "₹28,770.00"

    private static let cancellationCutoffFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    private var cancellationNoteText: String {
        guard let checkInDate = booking.checkInDate,
              let cutoff = Calendar.current.date(byAdding: .day, value: -2, to: checkInDate) else {
            return "Free cancellation available until 2 days before check-in. Post that, 1-night retention charges will apply."
        }
        let cutoffText = Self.cancellationCutoffFormatter.string(from: cutoff)
        return "Free cancellation available until \(cutoffText). Post that, 1-night retention charges will apply."
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
            Text("Review Your Booking")
                .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                .tracking(-0.75)
                .foregroundColor(darkText)

            hotelCard
            guestInformationCard
            deliveryDetailsCard
            paymentSummaryCard
            navigationButtons
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(24, tabBarState.height + 16))
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Hotel card

    private var hotelCard: some View {
        VStack(spacing: 0) {
            Text("REVIEW YOUR BOOKING")
                .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                .tracking(1.4)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(height: 60)
                .background(darkCard)

            ZStack(alignment: .topTrailing) {
                Image("hotel_review_photo")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 192)
                    .clipped()

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(darkText)
                    Text("\(booking.hotelCategory.uppercased()) LUXURY")
                        .font(Font.custom("Inter-Bold", size: 11))
                        .foregroundColor(darkText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
                .background(Color.white.opacity(0.6), in: Capsule())
                .padding(16)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("The Grand Heritage Residency")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                    .tracking(-0.5)
                    .foregroundColor(darkText)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(mutedGray)
                    Text(booking.hotelCity.isEmpty ? "New Delhi, India" : "\(booking.hotelCity), India")
                        .font(Font.custom("Inter", size: 12).weight(.medium))
                        .foregroundColor(mutedGray)
                }
                .padding(.bottom, 12)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DATES")
                            .font(Font.custom("Inter-Bold", size: 10))
                            .tracking(1)
                            .foregroundColor(mutedGray)
                        Text(booking.stayDateRangeShortText)
                            .font(Font.custom("Inter", size: 14).weight(.semibold))
                            .foregroundColor(darkText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("GUESTS")
                            .font(Font.custom("Inter-Bold", size: 10))
                            .tracking(1)
                            .foregroundColor(mutedGray)
                        Text(String(format: "%02d Adults", booking.guestsCount))
                            .font(Font.custom("Inter", size: 14).weight(.semibold))
                            .foregroundColor(darkText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 17)
                .overlay(Rectangle().fill(strokeColor.opacity(0.2)).frame(height: 1), alignment: .top)
            }
            .padding(24)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Guest Information card

    private var guestInformationCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text("Guest Information")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .frame(height: 45)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(darkCard)

            VStack(alignment: .leading, spacing: 8) {
                Text(booking.passengerName.isEmpty ? "—" : booking.passengerName)
                    .font(Font.custom("Inter", size: 14).weight(.semibold))
                    .foregroundColor(darkText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.emailAddress.isEmpty ? "—" : booking.emailAddress)
                    Text(booking.phoneNumber)
                }
                .font(Font.custom("Inter", size: 12))
                .foregroundColor(mutedGray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Delivery Details card

    private var deliveryDetailsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text("Delivery Details")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(darkCard)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SERVICE METHOD")
                        .font(Font.custom("Inter-Bold", size: 10))
                        .tracking(1)
                        .foregroundColor(labelGray)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 12) {
                        Image(systemName: serviceMethodIcon)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 25)
                            .background(brandRed)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 0) {
                            Text(serviceMethodTitle)
                                .font(Font.custom("Inter", size: 14).weight(.semibold))
                                .foregroundColor(darkText)
                            Text(serviceMethodSubtitle)
                                .font(Font.custom("Inter", size: 12))
                                .foregroundColor(mutedGray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(rowFill)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text("SPECIAL REQUESTS")
                        .font(Font.custom("Inter-Bold", size: 10))
                        .tracking(1)
                        .foregroundColor(labelGray)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if booking.hotelSpecialRequests.isEmpty {
                        Text("No special requests")
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(mutedGray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("\u{201C}\(booking.hotelSpecialRequests)\u{201D}")
                            .font(Font.custom("Inter", size: 14).italic())
                            .foregroundColor(mutedGray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var serviceMethodIcon: String {
        booking.deliveryMethod == .whatsapp ? "message.fill" : "envelope.fill"
    }

    private var serviceMethodTitle: String {
        booking.deliveryMethod == .whatsapp ? "WhatsApp Confirmation" : "Digital Confirmation"
    }

    private var serviceMethodSubtitle: String {
        booking.deliveryMethod == .whatsapp ? "Sent to your registered WhatsApp number" : "Sent to your registered email"
    }

    // MARK: - Payment Summary card

    private var paymentSummaryCard: some View {
        VStack(spacing: 0) {
            Text("Payment Summary")
                .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .frame(height: 60)
                .background(brandRed)

            VStack(spacing: 24) {
                paymentRow(label: "Base Fare (\(booking.stayNights) Nights)", value: baseFare)
                paymentRow(label: "GST & Convenience Fee", value: gstAndConvenienceFee)
                paymentRow(label: "Eco-Tourism Tax", value: ecoTourismTax)

                HStack(alignment: .lastTextBaseline) {
                    Text("Total")
                        .font(Font.custom("Inter-Bold", size: 18))
                        .foregroundColor(.white)
                    Spacer()
                    Text(totalAmount)
                        .font(Font.custom("Inter-Bold", size: 24))
                        .foregroundColor(brandRed)
                }
                .padding(.top, 24)
                .overlay(Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1), alignment: .top)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Text(cancellationNoteText)
                        .font(Font.custom("Inter", size: 11))
                        .foregroundColor(Color(red: 0.831, green: 0.831, blue: 0.831))
                        .lineSpacing(4)
                }
                .padding(17)
                .background(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(32)
        }
        .background(darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func paymentRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Font.custom("Inter", size: 14).weight(.medium))
                .foregroundColor(Color(red: 0.639, green: 0.639, blue: 0.639))
            Spacer()
            Text(value)
                .font(Font.custom("Inter-Bold", size: 14))
                .foregroundColor(.white)
        }
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
        DummyTicketHotelReviewBookingView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
