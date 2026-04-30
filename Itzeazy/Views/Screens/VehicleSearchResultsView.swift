import SwiftUI

struct VehicleSearchResultsView: View {
    @StateObject private var viewModel = VehicleViewModel()
    @State private var selectedChallan: Challan? = nil

    var body: some View {

        ZStack {
            Color(white: 0.97).edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }

            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if let result = viewModel.searchResult {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {

                        // Header
                        HStack(spacing: 12) {
                            Button(action: {}) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.red)
                            }

                            Text("Vehicle Search")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color(white: 0.1))

                            Spacer()

                            Button(action: {}) {
                                Image(systemName: "bell")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(white: 0.4))
                            }

                            ZStack {
                                Circle()
                                    .fill(Color(white: 0.15))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 4)

                        VehicleSearchCardView()

                        VehicleRegistrationCardView(
                            details: result.registrationDetails,
                            ownerName: result.ownerDetails.name
                        )

                        // Main content
                        VStack(spacing: 24) {
                            
                            // Registration Details
                            RegistrationDetailsView(details: result.registrationDetails)
                            
                            // PUC Detail (half width layout usually, but here just stacked)
                            // In Figma they are placed in different spots but we'll stack them cleanly
                            
                            OwnerDetailsView(details: result.ownerDetails)

                            HStack(alignment: .top, spacing: 29) {
                                InsuranceView(detail: result.insuranceDetail)
                                    .frame(maxWidth: .infinity)
                                PUCDetailView(detail: result.pucDetail)
                                    .frame(maxWidth: .infinity)
                            }
                            
                            FinanceStatusView(detail: result.financeDetail)
                            
                            // Challan Section
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
                                
                                // Pending Challans Banner
                                HStack {
                                    HStack(spacing: 12) {
                                        Text("\(result.pendingChallans.count)")
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
                                
                                // Challan Cards
                                ForEach(result.pendingChallans) { challan in
                                    ChallanCardView(challan: challan, onDetailsPressed: {
                                        selectedChallan = challan
                                    })
                                }

                                // Pay bar — fixed in scroll after challans
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
                            }
                        }
                        .padding(.horizontal)
                        
                    }
                }
                .navigationBarHidden(true)
            }

            // Centered popup overlay
            if let challan = selectedChallan {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { selectedChallan = nil }

                ChallanDetailPopup(challan: challan) {
                    selectedChallan = nil
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedChallan != nil)
        .navigationBarHidden(true)
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
