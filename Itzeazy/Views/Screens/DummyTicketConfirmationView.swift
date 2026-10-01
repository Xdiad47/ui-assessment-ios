import SwiftUI
import UIKit

// MARK: - DummyTicketConfirmationView
// Figma: "success" (node 3470:4453) — the screen shown after DummyTicketPaymentView's MAKE
// PAYMENT button, once booking.confirmBooking() has generated a booking reference on the shared
// DummyTicketBookingViewModel. This is the end of the Dummy Tickets flow: there's no NEXT button
// and nothing pushed forward from here.
//
// Of the 3 action buttons only "Back Home" does something real (booking.returnHome() unwinds the
// whole pushed stack back to HomeView). "My Bookings" would need to switch MainTabView's own
// selectedTab to the My Orders tab, but that's private @State local to MainTabView, not part of
// this flow's shared model — out of scope for this screen, so it shows the same "coming soon"
// toast used everywhere else in this app for a destination that isn't wired up yet. "Download PDF"
// has no real PDF to generate (no backend behind this flow at all — see DummyTicketPaymentView's
// header comment), so it gets the same toast.

struct DummyTicketConfirmationView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @EnvironmentObject private var booking: DummyTicketBookingViewModel

    @State private var showComingSoonToast = false

    // This screen's own literal reds/grays from the Figma frame — #ED2124, not the ₹FF0000
    // "primary red" the rest of this flow's own design tokens use elsewhere (RouteDetails/
    // Initial/Payment all define their own brandRed the same way, so this isn't a new pattern).
    private let brandRed = Color(red: 0.929, green: 0.129, blue: 0.141) // #ED2124
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11) // #191C1D
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72) // #B7B7B7
    private let darkText = Color(red: 0.059, green: 0.090, blue: 0.165) // #0F172A
    private let bodyGray = Color(red: 0.420, green: 0.447, blue: 0.502) // #6B7280
    private let labelGray = Color(red: 0.612, green: 0.639, blue: 0.686) // #9CA3AF
    private let valueDark = Color(red: 0.122, green: 0.161, blue: 0.216) // #1F2937
    private let pillBackground = Color(red: 0.976, green: 0.980, blue: 0.984) // #F9FAFB
    private let pillBorder = Color(red: 0.953, green: 0.957, blue: 0.965) // #F3F4F6
    private let processingBackground = Color(red: 0.996, green: 0.949, blue: 0.949) // #FEF2F2
    private let dashColor = Color(red: 0.898, green: 0.906, blue: 0.922) // #E5E7EB
    private let backHomeText = Color(red: 0.294, green: 0.333, blue: 0.388) // #4B5563

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
            orderDetailsCard
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

            Text("Booking Submitted Successfully")
                .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                .foregroundColor(darkText)
                .multilineTextAlignment(.center)

            Text("Your embassy-ready reservation is being generated by our legal experts.")
                .font(Font.custom("PlusJakartaSans-Regular", size: 14))
                .foregroundColor(bodyGray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 280)
                .padding(.bottom, 4)

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 13))
                    .foregroundColor(brandRed)
                Text("Delivery time: 30–60 Minutes")
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 12))
                    .foregroundColor(darkText)
            }
            .padding(.horizontal, 17)
            .padding(.vertical, 9)
            .background(pillBackground)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(pillBorder, lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Order details card

    private var orderDetailsCard: some View {
        VStack(spacing: 0) {
            brandRed.frame(height: 6)

            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ORDER DETAILS")
                            .font(Font.custom("PlusJakartaSans-Bold", size: 10))
                            .tracking(1)
                            .foregroundColor(labelGray)

                        Text("Booking ID: #\(booking.bookingReference ?? "—")")
                            .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                            .foregroundColor(darkText)
                    }

                    Spacer()

                    processingBadge
                }

                dashedDivider

                VStack(alignment: .leading, spacing: 20) {
                    orderDetailRow(label: "Confirmation Email", value: booking.emailAddress.isEmpty ? "—" : booking.emailAddress)
                    orderDetailRow(label: "Document Type", value: "Dummy Flight Ticket")
                }
            }
            .padding(24)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(strokeColor, lineWidth: 0.8)
        )
    }

    private var processingBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(brandRed)
                .frame(width: 6, height: 6)
            Text("PROCESSING")
                .font(Font.custom("PlusJakartaSans-Bold", size: 10))
                .tracking(0.5)
                .foregroundColor(brandRed)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(processingBackground)
        .clipShape(Capsule())
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

    private func orderDetailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Font.custom("PlusJakartaSans-Regular", size: 12).weight(.medium))
                .foregroundColor(labelGray)
            Text(value)
                .font(Font.custom("PlusJakartaSans-SemiBold", size: 14))
                .foregroundColor(valueDark)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: showComingSoon) {
                HStack(spacing: 12) {
                    Image("my_bookings_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("My Bookings")
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
        DummyTicketConfirmationView()
            .environmentObject(TabBarState())
            .environmentObject(DummyTicketBookingViewModel())
    }
}
