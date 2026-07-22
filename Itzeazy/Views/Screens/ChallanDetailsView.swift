import SwiftUI
import UIKit

struct ChallanDetailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @StateObject private var viewModel = ULIPChallanViewModel()
    @State private var selectedChallan: Challan? = nil
    @State private var navigateToProfile = false

    var body: some View {
        ZStack(alignment: .top) {
            NavigationLink(destination: ProfileView(onBackToHome: nil), isActive: $navigateToProfile) {
                EmptyView()
            }.hidden()

            Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()

            // ── Loading ───────────────────────────────────────────────────
            if viewModel.isLoading {
                VStack(spacing: 0) {
                    challanNavHeader
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                        Text("Fetching challan details…")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    Spacer()
                    UlipDisclaimerFooter(isOnDarkBackground: true)
                        .padding(.bottom, tabBarState.height)
                }

            // ── Error ─────────────────────────────────────────────────────
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 0) {
                    challanInputHeader
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                    UlipDisclaimerFooter(isOnDarkBackground: true)
                        .padding(.bottom, tabBarState.height)
                }

            // ── Results ───────────────────────────────────────────────────
            } else if viewModel.hasSearched {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {

                        challanInputHeader

                        VStack(spacing: 20) {

                            // Vehicle / owner overview
                            ChallanOverviewCard(
                                vehicleNumber: viewModel.vehicleNumber,
                                ownerName:     viewModel.ownerName
                            )

                            // Pending summary row
                            if !viewModel.challans.isEmpty {
                                HStack {
                                    HStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 20, height: 20)
                                            Text("\(viewModel.pendingCount)")
                                                .font(Font.custom("Inter", size: 10).weight(.bold))
                                                .foregroundColor(.white)
                                        }
                                        Text("Pending Challans Found")
                                            .font(Font.custom("Inter", size: 14).weight(.semibold))
                                            .foregroundColor(.red)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("TOTAL DUE")
                                            .font(Font.custom("Inter", size: 10).weight(.medium))
                                            .foregroundColor(.gray)
                                        Text("₹\(viewModel.totalDue)")
                                            .font(Font.custom("Inter", size: 16).weight(.bold))
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.99, green: 0.91, blue: 0.91))
                                .cornerRadius(16)
                            }

                            // All challans (pending + disposed)
                            if viewModel.challans.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.green)
                                    Text("No challans found for this vehicle.")
                                        .font(Font.custom("Inter", size: 14))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 32)
                            } else {
                                VStack(spacing: 16) {
                                    ForEach(viewModel.challans, id: \.id) { challan in
                                        ChallanRowCard(
                                            challan: challan,
                                            onDetailsPressed: { selectedChallan = challan },
                                            isSelected: viewModel.selectedChallanIDs.contains(challan.id),
                                            onToggleSelection: { viewModel.toggleSelection(challan.id) }
                                        )
                                    }
                                }
                            }

                            // Official gov data badge
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color(white: 0.2))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "checkmark.shield.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Secure & ULIP-Verified")
                                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                                        .foregroundColor(.white)
                                    Text("Challan data sourced via ULIP (Government of India). Payments processed through a secure gateway.")
                                        .font(Font.custom("Inter", size: 11))
                                        .foregroundColor(Color.gray)
                                        .lineLimit(3)
                                }
                            }
                            .padding(16)
                            .background(Color(red: 0.10, green: 0.11, blue: 0.11))
                            .cornerRadius(16)

                            // Bottom pay bar — only shown when user has selected at least one challan
                            if viewModel.selectedCount > 0 {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(viewModel.selectedCount) ITEMS SELECTED")
                                            .font(Font.custom("Inter", size: 10).weight(.medium))
                                            .foregroundColor(Color.gray)
                                        Text("₹\(viewModel.selectedTotal)")
                                            .font(Font.custom("Inter", size: 18).weight(.bold))
                                            .foregroundColor(.red)
                                    }
                                    Spacer()
                                    Button(action: {}) {
                                        Text("Pay All Selected")
                                            .font(Font.custom("Inter", size: 14).weight(.semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 160, height: 44)
                                            .background(Color.red)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.10, green: 0.11, blue: 0.11))
                                .cornerRadius(24)
                            }

                            UlipDisclaimerFooter(isOnDarkBackground: false)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20 + tabBarState.height)
                    }
                    .background(Color(white: 0.97))
                }

            // ── Initial — dark header, white below ────────────────────────
            } else {
                VStack(spacing: 0) {
                    challanInputHeader
                    ZStack(alignment: .bottom) {
                        Color.white
                        UlipDisclaimerFooter(isOnDarkBackground: false)
                            .padding(.bottom, tabBarState.height)
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
            }

            // ── Popup overlay ─────────────────────────────────────────────
            if let challan = selectedChallan {
                ZStack(alignment: .center) {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture { selectedChallan = nil }
                    ChallanDetailPopup(challan: challan) { selectedChallan = nil }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedChallan != nil)
        .navigationBarHidden(true)
    }

    // MARK: - Nav header (no input — for loading state)
    private var challanNavHeader: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.72, green: 0.72, blue: 0.72))
                .frame(maxWidth: .infinity).frame(height: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)
            Color(red: 0.10, green: 0.11, blue: 0.11)
                .frame(maxWidth: .infinity).frame(height: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
            HStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image("back_arrow").resizable().scaledToFit().frame(width: 24, height: 24)
                    }
                    Text("Challan Details")
                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                        .foregroundColor(.white)
                }
                Spacer()
                HStack(spacing: 16) {
                    Image(systemName: "bell").font(.system(size: 18)).foregroundColor(.white)
                    Button(action: { navigateToProfile = true }) {
                        ZStack {
                            Circle().fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50)).frame(width: 30, height: 30)
                            Image(systemName: "person.fill").font(.system(size: 14)).foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 20).frame(height: 60)
        }
    }

    // MARK: - Full dark header with input (for all states except loading)
    private var challanInputHeader: some View {
        VStack(spacing: 0) {
            challanNavHeader

            Text("Check & Pay Your Traffic Challan Online")
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 16))
                .foregroundColor(.white)
                .padding(.top, 24)

            Spacer().frame(height: 20)

            VStack(alignment: .leading, spacing: 14) {
                Text("VEHICLE NO")
                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                    .foregroundColor(.white)

                ZStack(alignment: .leading) {
                    if viewModel.vehicleNumber.isEmpty {
                        Text("e.g. HR26DX3155")
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                            .padding(.horizontal, 16)
                    }
                    TextField("", text: $viewModel.vehicleNumber)
                        .font(Font.custom("Inter", size: 14))
                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .onChange(of: viewModel.vehicleNumber) { v in
                            let u = v.uppercased()
                            if v != u { viewModel.vehicleNumber = u }
                        }
                }
                .background(Color.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 30)

            HStack(spacing: 16) {
                Button(action: { viewModel.reset() }) {
                    Text("Reset")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                        .frame(width: 115, height: 40)
                        .background(Color(red: 0.88, green: 0.89, blue: 0.89))
                        .clipShape(Capsule())
                }

                Button(action: { viewModel.search() }) {
                    Text("Check Status")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            viewModel.vehicleNumber.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.red.opacity(0.45)
                                : Color.red
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.red.opacity(0.3), radius: 6, x: 0, y: 4)
                }
                .disabled(viewModel.vehicleNumber.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 30)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(
            Color(red: 0.10, green: 0.11, blue: 0.11)
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
        )
    }
}

// MARK: - Challan overview card (vehicle number + owner from challan data)

private struct ChallanOverviewCard: View {
    let vehicleNumber: String
    let ownerName: String

    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.red)
                .frame(width: 4)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("VEHICLE NUMBER")
                            .font(Font.custom("Inter", size: 10).weight(.medium))
                            .foregroundColor(Color.gray)
                        Text(vehicleNumber)
                            .font(Font.custom("Inter", size: 14).weight(.bold))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                    }
                    Spacer()
                    if !ownerName.isEmpty {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("OWNER NAME")
                                .font(Font.custom("Inter", size: 10).weight(.medium))
                                .foregroundColor(Color.gray)
                            Text(ownerName)
                                .font(Font.custom("Inter", size: 14).weight(.bold))
                                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.leading, 12)
            .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Challan row card

private struct ChallanRowCard: View {
    let challan: Challan
    let onDetailsPressed: () -> Void
    var isSelected: Bool = false
    var onToggleSelection: () -> Void = {}

    private var isPending: Bool { challan.status.lowercased() == "pending" }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(white: 0.95))
                        .frame(width: 44, height: 44)
                    Image(systemName: isPending ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(isPending ? .red : .gray)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(challan.title)
                        .font(Font.custom("Inter", size: 15).weight(.semibold))
                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                    Text("ID: #\(challan.id)")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(Color.gray)
                }

                Spacer()

                Text(challan.status)
                    .font(Font.custom("Inter", size: 10).weight(.bold))
                    .foregroundColor(isPending ? .red : .gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isPending ? Color.red : Color.gray).opacity(0.12))
                    .cornerRadius(6)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DATE")
                        .font(Font.custom("Inter", size: 10).weight(.medium))
                        .foregroundColor(Color.gray)
                    Text(challan.date)
                        .font(Font.custom("Inter", size: 13).weight(.semibold))
                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("AMOUNT")
                        .font(Font.custom("Inter", size: 10).weight(.medium))
                        .foregroundColor(Color.gray)
                    Text("₹\(challan.amount)")
                        .font(Font.custom("Inter", size: 16).weight(.bold))
                        .foregroundColor(.red)
                }
            }

            HStack(spacing: 12) {
                Button(action: onDetailsPressed) {
                    Text("Details")
                        .font(Font.custom("Inter", size: 13).weight(.bold))
                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(red: 0.88, green: 0.89, blue: 0.89))
                        .cornerRadius(12)
                }

                if isPending {
                    Button(action: onToggleSelection) {
                        HStack(spacing: 6) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                                .font(.system(size: 14))
                            Text(isSelected ? "Added" : "Add to Pay")
                                .font(Font.custom("Inter", size: 13).weight(.bold))
                        }
                        .foregroundColor(isSelected ? Color(red: 0.14, green: 0.15, blue: 0.23) : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(isSelected ? Color(red: 0.14, green: 0.15, blue: 0.23).opacity(0.12) : Color(red: 0.14, green: 0.15, blue: 0.23))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.14, green: 0.15, blue: 0.23).opacity(isSelected ? 0.4 : 0), lineWidth: 1)
                        )
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Paid")
                            .font(Font.custom("Inter", size: 13).weight(.bold))
                    }
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ChallanDetailsView()
        .environmentObject(TabBarState())
}
