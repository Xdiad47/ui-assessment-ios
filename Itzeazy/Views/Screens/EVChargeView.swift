import SwiftUI
import UIKit

struct EVChargeView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
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

                            UlipDisclaimerFooter(isOnDarkBackground: true)
                                .padding(.top, 14)

                            Color.clear.frame(height: proxy.safeAreaInsets.bottom + tabBarState.height + 8)
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onTapGesture { isSearchFocused = false }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.startFetchingLocation() }
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
                        .foregroundColor(.white)
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

                    if viewModel.isLoading {
                        Text("Finding stations near you…")
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(hex: "#8A8A8A"))
                    } else {
                        Text("Found \(viewModel.filteredStations.count) stations in your area")
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(hex: "#8A8A8A"))
                    }
                }
                Spacer()
            }
            .padding(.bottom, 20)

            // Content based on state
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.3)
                    Text("Fetching nearby stations…")
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(Color(hex: "#8A8A8A"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "bolt.slash.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "#8A8A8A"))
                    Text(error)
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(Color(hex: "#8A8A8A"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else if viewModel.filteredStations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bolt.circle")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "#8A8A8A"))
                    Text("No stations match your search.")
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(Color(hex: "#8A8A8A"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            } else {
                VStack(spacing: 14) {
                    ForEach(viewModel.filteredStations) { station in
                        StationCard(station: station)
                    }
                }
            }
        }
    }
}

// MARK: - Station card

private struct StationCard: View {
    let station: EVChargingStation

    private let red   = Color(hex: "#E61A20")
    private let green = Color(hex: "#1BA345")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Name + distance badge ──────────────────────────────────────
            HStack(alignment: .top) {
                Text(station.name)
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 17))
                    .foregroundColor(Color(hex: "#0E0F11"))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                // Distance badge
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#4A90D9"))
                    Text(String(format: "%.1f km", station.distanceKm))
                        .font(Font.custom("PlusJakartaSans-Bold", size: 13))
                        .foregroundColor(Color(hex: "#0E0F11"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: "#4A90D9").opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(hex: "#4A90D9").opacity(0.40), lineWidth: 1.2)
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
            Button(action: {
                if let lat = station.lat, let lng = station.lng,
                   let url = URL(string: "maps://?daddr=\(lat),\(lng)"),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }) {
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
    .environmentObject(TabBarState())
}
