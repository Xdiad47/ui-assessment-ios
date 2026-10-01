import SwiftUI
import UIKit

// MARK: - DummyTicketHotelConfirmationView
// Figma: "Sucess" (node 3497:7780) — the screen shown after DummyTicketPaymentView's MAKE PAYMENT
// button when the booking is a Hotel one, once booking.confirmBooking() has generated
// hotelBookingReference. Mirrors DummyTicketConfirmationView's structure/colors closely, but has
// no "Delivery time" pill (Figma's Hotel success frame doesn't have one) and its own "BOOKING
// DETAILS" card shape (a CONFIRMED badge, Booking ID/Guest Name/Destination/Dates rows, then an
// Accommodation Type row below a dashed divider) instead of Flight's simpler card.
//
// Data honesty: Booking ID, Guest Name, Destination and Dates all read real values already
// collected earlier in the flow. Figma's own sample content for Destination ("Paris, France" /
// "Charles de Gaulle Vicinity") and Accommodation Type ("Embassy-Certified 4★ Hotel" — visa/
// passport wording that doesn't even apply to a hotel) are clearly leftover placeholder text from
// a reused component, not real design intent to preserve verbatim, so Destination shows
// booking.hotelCity alone (no live "vicinity" data exists anywhere in this flow to fill that
// second line) and Accommodation Type is derived from booking.hotelCategory instead.
//
// Of the 3 action buttons only "Back Home" does something real, same reasoning as
// DummyTicketConfirmationView: "My Booking" and "Download PDF" show the same "coming soon" toast
// used everywhere else in this app for a destination that isn't wired up.

struct DummyTicketHotelConfirmationView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel

    @State private var showComingSoonToast = false

    // Same literal reds/grays as DummyTicketConfirmationView (this screen's own Figma frame uses
    // the identical #ED2124, not the ₹FF0000 "primary red" the rest of the Hotel flow uses).
    private let brandRed = Color(red: 0.929, green: 0.129, blue: 0.141) // #ED2124
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11) // #191C1D
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72) // #B7B7B7
    private let darkText = Color(red: 0.059, green: 0.090, blue: 0.165) // #0F172A
    private let labelGray = Color(red: 0.373, green: 0.369, blue: 0.369) // #5F5E5E
    private let valueDark = Color(red: 0.098, green: 0.110, blue: 0.114) // #191C1D
    private let dashColor = Color(red: 0.882, green: 0.894, blue: 0.898) // #E1E3E4
    private let backHomeText = Color(red: 0.294, green: 0.333, blue: 0.388) // #4B5563
    private let confirmedBackground = Color(red: 0.863, green: 0.988, blue: 0.906) // #DCFCE7
    private let confirmedText = Color(red: 0.086, green: 0.502, blue: 0.239) // #15803D
    private let iconBoxFill = Color(red: 0.953, green: 0.957, blue: 0.961) // #F3F4F5

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
            }
            .ignoresSafeArea(.container, edges: .vertical)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showComingSoonToast)
        }
        .navigationBarHidden(true)
    }

    private func showComingSoon() {
        showComingSoonToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { showComingSoonToast = false }
    }

    // MARK: - Header

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
            .frame(height: 60)
        }
        .background(darkCard)
        .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 16) {
            successStatusSection
            bookingDetailsCard
            actionButtons
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(16, tabBarState.height + 16))
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Success status

    private var successStatusSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(brandRed)
                    .frame(width: 72, height: 72)
                    .shadow(color: brandRed.opacity(0.18), radius: 7.5, x: 0, y: 10)
                    .shadow(color: brandRed.opacity(0.18), radius: 3, x: 0, y: 4)
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 4)

            Text("Hotel Reservation Booked Successfully")
                .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                .foregroundColor(darkText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Booking details card

    private var bookingDetailsCard: some View {
        VStack(spacing: 0) {
            brandRed.frame(height: 6)

            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    Text("BOOKING DETAILS")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                        .tracking(1.6)
                        .foregroundColor(labelGray)

                    Spacer()

                    Text("CONFIRMED")
                        .font(Font.custom("Inter-Bold", size: 10))
                        .tracking(1)
                        .foregroundColor(confirmedText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(confirmedBackground)
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 20) {
                    bookingDetailRow(label: "BOOKING ID", value: "#\(booking.hotelBookingReference ?? "—")")
                    bookingDetailRow(label: "GUEST NAME", value: booking.passengerName.isEmpty ? "—" : booking.passengerName)
                    bookingDetailRow(label: "DESTINATION", value: booking.hotelCity.isEmpty ? "—" : booking.hotelCity)
                    bookingDetailRow(label: "DATES", value: booking.stayDateRangeShortText)
                }

                dashedDivider

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(iconBoxFill)
                            .frame(width: 32, height: 32)
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 13))
                            .foregroundColor(labelGray)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accommodation Type")
                            .font(Font.custom("Inter", size: 11))
                            .foregroundColor(labelGray)
                        Text("\(booking.hotelCategory) Hotel")
                            .font(Font.custom("Inter", size: 12).weight(.semibold))
                            .foregroundColor(darkText)
                    }
                }
            }
            .padding(24)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(strokeColor, lineWidth: 1)
        )
    }

    private func bookingDetailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(Font.custom("Inter", size: 12).weight(.medium))
                .tracking(0.6)
                .foregroundColor(labelGray)
            Spacer()
            Text(value)
                .font(Font.custom("Inter", size: 14).weight(.semibold))
                .foregroundColor(valueDark)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }

    private var dashedDivider: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0.5))
                path.addLine(to: CGPoint(x: geo.size.width, y: 0.5))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .foregroundColor(dashColor)
        }
        .frame(height: 1)
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: showComingSoon) {
                HStack(spacing: 12) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    Text("My Booking")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(darkCard)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(strokeColor, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button(action: booking.returnHome) {
                Text("Back Home")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                    .foregroundColor(backHomeText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(strokeColor, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button(action: showComingSoon) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Download PDF")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(brandRed)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    NavigationView {
        DummyTicketHotelConfirmationView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
