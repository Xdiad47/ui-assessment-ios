import SwiftUI



struct VehicleSearchResultsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = ULIPVehicleViewModel()
    @State private var selectedChallan: Challan? = nil

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.10, green: 0.11, blue: 0.11).edgesIgnoringSafeArea(.all)

            // ── Loading state ──────────────────────────────────────────────
            if viewModel.isLoading {
                VStack(spacing: 0) {
                    vehicleNavHeader
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                        Text("Fetching vehicle details…")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    Spacer()
                }

            // ── Error state ────────────────────────────────────────────────
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 0) {
                    vehicleNavHeader
                    VehicleSearchCardView(
                        vehicleNo: $viewModel.vehicleNumber,
                        searchType: $viewModel.searchType,
                        onCheckStatus: { viewModel.search() },
                        onReset: { viewModel.reset() },
                        isEmbedded: true
                    )
                    .background(
                        Color(red: 0.10, green: 0.11, blue: 0.11)
                            .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                    )
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
                }

            // ── Results state ──────────────────────────────────────────────
            } else if let result = viewModel.searchResult {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {

                        // Dark top section with header + embedded search card
                        VStack(spacing: 0) {
                            vehicleNavHeader
                            VehicleSearchCardView(
                                vehicleNo: $viewModel.vehicleNumber,
                                searchType: $viewModel.searchType,
                                onCheckStatus: { viewModel.search() },
                                onReset: { viewModel.reset() },
                                isEmbedded: true
                            )
                        }
                        .background(
                            Color(red: 0.10, green: 0.11, blue: 0.11)
                                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                        )

                        // Results
                        VStack(spacing: 24) {
                            VehicleRegistrationCardView(
                                details: result.registrationDetails,
                                ownerName: result.ownerDetails.name
                            )

                            VStack(spacing: 24) {
                                RegistrationDetailsView(details: result.registrationDetails)
                                OwnerDetailsView(details: result.ownerDetails)

                                HStack(alignment: .top, spacing: 29) {
                                    InsuranceView(detail: result.insuranceDetail)
                                        .frame(maxWidth: .infinity)
                                    PUCDetailView(detail: result.pucDetail)
                                        .frame(maxWidth: .infinity)
                                }

                                FinanceStatusView(detail: result.financeDetail)

                                if !result.pendingChallans.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("Challan Details")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(white: 0.1))
                                        .cornerRadius(10)

                                        HStack {
                                            HStack(spacing: 12) {
                                                Text("\(viewModel.pendingChallanCount)")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.red)
                                                    .clipShape(Capsule())
                                                Text("Pending Challans Found")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.red)
                                            }
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("TOTAL DUE")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.gray)
                                                Text("₹\(viewModel.totalDue)")
                                                    .font(.system(size: 16, weight: .bold))
                                            }
                                        }
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(24)

                                        ForEach(result.pendingChallans) { challan in
                                            ChallanCardView(challan: challan, onDetailsPressed: {
                                                selectedChallan = challan
                                            })
                                        }

                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(viewModel.selectedChallansCount) ITEMS SELECTED")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.gray)
                                                Text("₹\(viewModel.totalDue)")
                                                    .font(.system(size: 20, weight: .heavy))
                                                    .foregroundColor(.red)
                                            }
                                            Spacer()
                                            Button(action: {}) {
                                                Text("Pay All Selected")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 32)
                                                    .padding(.vertical, 16)
                                                    .background(Color.red)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        .padding()
                                        .background(Color(white: 0.1))
                                        .cornerRadius(24)

                                        Spacer().frame(height: 28)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 24)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.97))
                    .padding(.bottom, 100)
                }
                .background(Color(white: 0.97))
                .edgesIgnoringSafeArea(.bottom)

            // ── Initial state — status bar stays dark (outer ZStack), content below header is white ──
            } else {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        vehicleNavHeader
                        VehicleSearchCardView(
                            vehicleNo: $viewModel.vehicleNumber,
                            searchType: $viewModel.searchType,
                            onCheckStatus: { viewModel.search() },
                            onReset: { viewModel.reset() },
                            isEmbedded: true
                        )
                    }
                    .background(
                        Color(red: 0.10, green: 0.11, blue: 0.11)
                            .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                    )

                    Color.white
                        .edgesIgnoringSafeArea(.bottom)
                }
            }

            // ── Challan detail popup overlay ───────────────────────────────
            if let challan = selectedChallan {
                ZStack(alignment: .center) {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture { selectedChallan = nil }

                    ChallanDetailPopup(challan: challan) {
                        selectedChallan = nil
                    }
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

    // MARK: - Shared nav header
    private var vehicleNavHeader: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.72, green: 0.72, blue: 0.72))
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            Color(red: 0.10, green: 0.11, blue: 0.11)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image("back_arrow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    Text("Vehicle Details")
                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                        .foregroundColor(.white)
                }
                Spacer()
                HStack(spacing: 16) {
                    Image(systemName: "bell")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                            .frame(width: 30, height: 30)
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
        }
    }
}

// Helper to round specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct VehicleSearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleSearchResultsView()
    }
}
