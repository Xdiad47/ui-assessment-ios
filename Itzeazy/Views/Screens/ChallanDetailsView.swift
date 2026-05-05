import SwiftUI
import UIKit

struct ChallanDetailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = VehicleViewModel()
    @State private var selectedChallan: Challan? = nil
    @State private var challanNo: String = "HR-654365124512445"
    
    var body: some View {
        ZStack(alignment: .top) {
            if viewModel.isLoading {
                Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()
                ProgressView("Loading...")
                    .foregroundColor(.white)
            } else if let result = viewModel.searchResult {
                Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        // ── Dark Header Section ───────────
                        VStack(spacing: 0) {
                            
                            // Header matching RTOServicesView & VehicleSearchResultsView
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
                                        Button(action: {
                                            presentationMode.wrappedValue.dismiss()
                                        }) {
                                            Image("back_arrow")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24)
                                        }
                                        Text("Challan Details")
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
                            
                            // Subtitle
                            Text("Check & Pay Your Traffic Challan Online")
                                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 16))
                                .foregroundColor(.white)
                                .padding(.top, 24)
                            
                            Spacer().frame(height: 20)
                            
                            // Input Section
                            VStack(alignment: .leading, spacing: 14) {
                                
                                Text("CHALLAN NO")
                                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                                    .foregroundColor(.white)
                                
                                TextField("Enter Challan No", text: $challanNo)
                                    .font(Font.custom("Inter", size: 14))
                                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 30)
                            
                            // Action Buttons
                            HStack(spacing: 16) {
                                Button(action: {
                                    challanNo = ""
                                }) {
                                    Text("Reset")
                                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                        .frame(width: 115, height: 40)
                                        .background(Color(red: 0.88, green: 0.89, blue: 0.89))
                                        .clipShape(Capsule())
                                }
                                
                                Button(action: {
                                    // action
                                }) {
                                    Text("Check Status")
                                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(Color.red)
                                        .clipShape(Capsule())
                                        .shadow(color: Color.red.opacity(0.3), radius: 6, x: 0, y: 4)
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 16)
                            .padding(.bottom, 24)
                            
                        }
                        .background(
                            Color(red: 0.10, green: 0.11, blue: 0.11)
                                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                        )
                        .zIndex(1)
                        
                        // ── Content Area ───────────
                        VStack(spacing: 24) {
                            
                            // Vehicle Overview Card
                            VehicleOverviewCard(result: result)
                            
                            // Pending Challans Header
                            HStack {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 20, height: 20)
                                        Text("\(result.pendingChallans.count)")
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
                                        .foregroundColor(Color.gray)
                                    Text("₹2,500")
                                        .font(Font.custom("Inter", size: 16).weight(.bold))
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.99, green: 0.91, blue: 0.91))
                            .cornerRadius(16)
                            
                            // Challan List
                            VStack(spacing: 16) {
                                ForEach(result.pendingChallans, id: \.id) { challan in
                                    ChallanRowCard(challan: challan, onDetailsPressed: {
                                        selectedChallan = challan
                                    })
                                }
                            }
                            
                            // View All
                            Button(action: {}) {
                                HStack {
                                    Text("View All")
                                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Official Gov Data Card
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
                                    Text("Official Government Data")
                                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                                        .foregroundColor(.white)
                                    Text("Secure payment gateway integrated with Parivahan and regional RTO databases.")
                                        .font(Font.custom("Inter", size: 11))
                                        .foregroundColor(Color.gray)
                                        .lineLimit(2)
                                }
                            }
                            .padding(16)
                            .background(Color(red: 0.10, green: 0.11, blue: 0.11))
                            .cornerRadius(16)
                            
                            // Bottom Pay Bar
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("3 ITEMS SELECTED")
                                        .font(Font.custom("Inter", size: 10).weight(.medium))
                                        .foregroundColor(Color.gray)
                                    Text("₹2,500")
                                        .font(Font.custom("Inter", size: 18).weight(.bold))
                                        .foregroundColor(.red)
                                }
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Text("Pay All Selected")
                                        .font(Font.custom("Inter", size: 16).weight(.semibold))
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
                            .padding(.top, 0)
                            
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 15)
                        .padding(.bottom, 80)
                        
                    }
                    .background(Color(white: 0.97)) // Light background
                }
            }
            
            // Popup Overlay
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
}

private struct VehicleOverviewCard: View {
    let result: VehicleSearchResult
    
    var body: some View {
        HStack {
            // Red accent line
            Rectangle()
                .fill(Color.red)
                .frame(width: 4)
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("VEHICLE NUMBER")
                            .font(Font.custom("Inter", size: 10).weight(.medium))
                            .foregroundColor(Color.gray)
                        Text(result.registrationDetails.vehicleNo)
                            .font(Font.custom("Inter", size: 14).weight(.bold))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OWNER NAME")
                            .font(Font.custom("Inter", size: 10).weight(.medium))
                            .foregroundColor(Color.gray)
                        Text(result.ownerDetails.name)
                            .font(Font.custom("Inter", size: 14).weight(.bold))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                    }
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MODEL")
                            .font(Font.custom("Inter", size: 10).weight(.medium))
                            .foregroundColor(Color.gray)
                        Text(result.registrationDetails.model)
                            .font(Font.custom("Inter", size: 14).weight(.bold))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RTO")
                            .font(Font.custom("Inter", size: 10).weight(.medium))
                            .foregroundColor(Color.gray)
                        Text(result.registrationDetails.registeredAt.split(separator: ",").first.map(String.init) ?? "")
                            .font(Font.custom("Inter", size: 14).weight(.bold))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                    }
                    Spacer()
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

private struct ChallanRowCard: View {
    let challan: Challan
    let onDetailsPressed: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(white: 0.95))
                        .frame(width: 44, height: 44)
                    
                    // --- CUSTOM ICONS SETUP ---
                    // Replace the string values below with your exact asset names from Xcode
                    let customIconName: String = {
                        if challan.title.contains("Speed") {
                            return "over_speeding"     // <-- Set your Speeding icon here
                        } else if challan.title.contains("Signal") {
                            return "signal_jumping"    // <-- Set your Signal jumping icon here
                        } else {
                            return "wrong_parking"   // <-- Set your Wrong parking icon here
                        }
                    }()
                    
                    // This automatically uses your custom asset if found, otherwise uses the placeholder
                    if UIImage(named: customIconName) != nil {
                        Image(customIconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    } else {
                        // Temporary custom icon fallback
                        Image(systemName: challan.title.contains("Speed") ? "gauge.with.dots.needle.bottom.50percent" :
                                        challan.title.contains("Signal") ? "trafficlights.fill" : "parkingsign.circle")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    }
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
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.99, green: 0.91, blue: 0.91))
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
                
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                        Text("Add to Pay")
                            .font(Font.custom("Inter", size: 13).weight(.bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color(red: 0.14, green: 0.15, blue: 0.23))
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
}
