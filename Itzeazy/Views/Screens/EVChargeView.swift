import SwiftUI

struct EVChargeView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = EVChargeViewModel()
    @FocusState private var isSearchFocused: Bool

    private let red   = Color(hex: "#E61A20")
    private let dark  = Color(hex: "#0E0F11")
    private let cardShadow = Color.black.opacity(0.08)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                dark.ignoresSafeArea()

                VStack(spacing: 0) {
                    header(safeAreaTop: proxy.safeAreaInsets.top)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            searchBar
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 24)

                            stationSection
                                .padding(.horizontal, 16)

                            Color.clear.frame(height: proxy.safeAreaInsets.bottom + 90)
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onTapGesture { isSearchFocused = false }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private func header(safeAreaTop: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // Stroke peek — 1pt wider/taller, sits behind the dark card
            Rectangle()
                .fill(Color(red: 0.72, green: 0.72, blue: 0.72))
                .frame(maxWidth: .infinity)
                .frame(height: safeAreaTop + 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            // Dark header card
            Color(hex: "#191C1D")
                .frame(maxWidth: .infinity)
                .frame(height: safeAreaTop + 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 10) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(red)
                        .frame(width: 32, height: 32)
                }

                Text("Charging Stations")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

                Spacer()
//
//                Button(action: {}) {
//                    Image(systemName: "bell")
//                        .font(.system(size: 17))
//                        .foregroundColor(.white)
//                        .frame(width: 32, height: 32)
//                }
//
//                Button(action: {}) {
//                    ZStack {
//                        Circle()
//                            .fill(Color(hex: "#2A2A2A"))
//                            .frame(width: 32, height: 32)
//                        Image(systemName: "person.fill")
//                            .font(.system(size: 14))
//                            .foregroundColor(.white)
//                    }
//                }
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .padding(.top, safeAreaTop)
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#8A8A8A"))

            TextField("", text: $viewModel.searchText, prompt: Text("Search for a location or station...")
                .foregroundColor(Color(hex: "#6B6B6B"))
                .font(Font.custom("Inter", size: 14))
            )
            .font(Font.custom("Inter", size: 14))
            .foregroundColor(.white)
            .focused($isSearchFocused)
            .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color(hex: "#1E2025"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "#2E3038"), lineWidth: 1)
        )
    }

    // MARK: - Station section

    private var stationSection: some View {
        VStack(spacing: 0) {
            // Section header row
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nearby Charging Stations")
                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 20))
                        .foregroundColor(.white)

                    Text("Found \(viewModel.filteredStations.count) stations in your area")
                        .font(Font.custom("Inter", size: 13))
                        .foregroundColor(Color(hex: "#8A8A8A"))
                }

                Spacer()

                Button(action: {}) {
                    Text("View All")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                        .foregroundColor(red)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 20)

            // Cards
            VStack(spacing: 14) {
                ForEach(viewModel.filteredStations) { station in
                    StationCard(station: station)
                }
            }
        }
    }
}

// MARK: - Station card

private struct StationCard: View {
    let station: EVChargingStation

    private let red     = Color(hex: "#E61A20")
    private let gold    = Color(hex: "#D4A017")
    private let green   = Color(hex: "#1BA345")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Name + rating ─────────────────────────────────────────────
            HStack(alignment: .top) {
                Text(station.name)
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 17))
                    .foregroundColor(Color(hex: "#0E0F11"))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                // Rating badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(gold)
                    Text(String(format: "%.1f", station.rating))
                        .font(Font.custom("PlusJakartaSans-Bold", size: 13))
                        .foregroundColor(Color(hex: "#0E0F11"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(gold.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(gold.opacity(0.55), lineWidth: 1.2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            // ── Availability ──────────────────────────────────────────────
            HStack(spacing: 6) {
                Circle()
                    .fill(station.isAvailable ? green : Color(hex: "#E06B00"))
                    .frame(width: 8, height: 8)

                Text(station.isAvailable ? "Available" : "Busy")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                    .foregroundColor(station.isAvailable ? green : Color(hex: "#E06B00"))
            }
            .padding(.top, 12)

            // ── Address ───────────────────────────────────────────────────
            Text(station.address)
                .font(Font.custom("Inter", size: 14))
                .foregroundColor(Color(hex: "#6B6B6B"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            // ── Directions button ─────────────────────────────────────────
            Button(action: {}) {
                Text("Directions")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                    .foregroundColor(red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(red, lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 4)
    }
}

#Preview {
    NavigationView {
        EVChargeView()
    }
}
