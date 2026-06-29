import SwiftUI

struct RegistrationDetailsView: View {
    let details: VehicleRegistrationDetails
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Registration Details")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(details.status)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(12)
            }
            .padding()
            .background(Color(white: 0.15))
            
            // Details Grid
            VStack(spacing: 20) {
                HStack(alignment: .top) {
                    DetailItemView(label: "VEHICLE NO", value: details.vehicleNo)
                    Spacer()
                    DetailItemView(label: "CLASS", value: details.vehicleClass)
                }
                
                HStack(alignment: .top) {
                    DetailItemView(label: "MAKER", value: details.maker)
                    Spacer()
                    DetailItemView(label: "MODEL", value: details.model)
                }
                
                HStack(alignment: .top) {
                    DetailItemView(label: "REG DATE", value: details.regDate)
                    Spacer()
                    DetailItemView(label: "FITNESS UPTO", value: details.fitnessUpto, isAlert: true)
                }
                
                HStack(alignment: .top) {
                    DetailItemView(label: "COLOUR", value: details.colour)
                    Spacer()
                    DetailItemView(label: "REGISTERED AT", value: details.registeredAt)
                }
                
                HStack(alignment: .top) {
                    DetailItemView(label: "FUEL", value: details.fuel)
                    Spacer()
                    DetailItemView(label: "CC", value: details.cc)
                }
                
                HStack(alignment: .top) {
                    DetailItemView(label: "CHASSIS NO", value: details.chassisNo)
                    Spacer()
                    DetailItemView(label: "ENGINE NO", value: details.engineNo)
                }
            }
            .padding()
            .background(Color.white)
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct DetailItemView: View {
    let label: String
    let value: String
    var isAlert: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isAlert ? .red : .gray)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isAlert ? .red : .black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OwnerDetailsView: View {
    let details: OwnerDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "person.circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.red)
                Text("Owner Details")
                    .font(Font.custom("Plus Jakarta Sans", size: 14).weight(.bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 42)
            .background(Color(red: 0.11, green: 0.11, blue: 0.12))
            .cornerRadius(10, corners: [.topLeft, .topRight])

            // Body
            HStack {
                VStack(alignment: .leading, spacing: 13) {
                    Text("OWNER NAME")
                        .font(Font.custom("Inter", size: 10).weight(.semibold))
                        .tracking(0.50)
                        .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
                    Text(details.name)
                        .font(Font.custom("Plus Jakarta Sans", size: 16).weight(.heavy))
                        .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.10))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 10) {
                    Text("SL NO")
                        .font(Font.custom("Inter", size: 10).weight(.semibold))
                        .tracking(0.50)
                        .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
                    Text(details.serialNo)
                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 10) {
                    Text("OWNER TYPE")
                        .font(Font.custom("Inter", size: 10).weight(.semibold))
                        .tracking(0.50)
                        .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
                    Text(details.type)
                        .font(Font.custom("Inter", size: 14).weight(.semibold))
                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                }
            }
            .padding(.horizontal, 26)
            .frame(maxWidth: .infinity, minHeight: 75)
            .background(Color(red: 0.97, green: 0.98, blue: 0.98))
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 0.50),
                alignment: .bottom
            )
        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 0.50)
        )
    }
}

struct InsuranceView: View {
    let detail: InsuranceDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image("tick")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 17)
                Text("INSURANCE")
                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                    .tracking(0.55)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(Color(red: 0.11, green: 0.11, blue: 0.12))
            .cornerRadius(10, corners: [.topLeft, .topRight])

            // Body
            VStack(alignment: .leading, spacing: 6) {
                Text(detail.provider)
                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                Text("Exp: \(detail.expiryDate)")
                    .font(Font.custom("Inter", size: 11).italic())
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11).opacity(0.89))
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 67, alignment: .leading)
            .background(Color.white)
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 0.50)
        )
    }
}

struct PUCDetailView: View {
    let detail: PUCDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image("puc_green_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                Text("PUC DETAIL")
                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                    .tracking(0.55)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(Color(red: 0.11, green: 0.11, blue: 0.12))
            .cornerRadius(10, corners: [.topLeft, .topRight])

            // Body
            VStack(alignment: .leading, spacing: 6) {
                Text("Valid Status")
                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                    .foregroundColor(Color(red: 0.08, green: 0.50, blue: 0.24))
                Text(detail.validStatus)
                    .font(Font.custom("Inter", size: 11).italic())
                    .foregroundColor(Color(red: 0.02, green: 0.02, blue: 0.02))
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 67, alignment: .leading)
            .background(Color.white)
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 0.50)
        )
    }
}

struct FinanceStatusView: View {
    let detail: FinanceDetail
    
    var body: some View {
        
        VStack(spacing: 0) {
            //Header
            HStack {
                Image("other_details")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 14)

                Text("OTHER DETAILS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color(white: 0.15))
            
            VStack(spacing: 16) {
                
         
                
                HStack {
                    Text("Finance Status")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text(detail.financeStatus)
                        .font(.system(size: 14, weight: .bold))
                }
                
                HStack {
                    Text("Blacklist Status")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text(detail.blacklistStatus)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("NOC Details")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text(detail.nocDetails)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .padding()
            .background(Color.white)
            
            
           
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ChallanCardView: View {
    let challan: Challan
    var onDetailsPressed: () -> Void = {}
    var isSelected: Bool = false
    var onToggleSelection: () -> Void = {}

    private var iconAssetName: String {
        challan.title.lowercased().replacingOccurrences(of: " ", with: "_")
    }
    private var isPending: Bool { challan.status.lowercased() == "pending" }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(iconAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(challan.title)
                        .font(.system(size: 16, weight: .bold))
                    Text("ID: #\(challan.id)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(challan.status)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isPending ? .red : .gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isPending ? Color.red : Color.gray).opacity(0.12))
                    .cornerRadius(4)
            }
            
            Divider()
            
            // Details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DATE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.gray)
                    Text(challan.date)
                        .font(.system(size: 12, weight: .semibold))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("AMOUNT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.gray)
                    Text("₹\(challan.amount)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                Button(action: onDetailsPressed) {
                    Text("Details")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.3))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(16)
                }

                if isPending {
                    Button(action: onToggleSelection) {
                        HStack {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle.fill")
                            Text(isSelected ? "Added" : "Add to Pay")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSelected ? Color(red: 0.1, green: 0.1, blue: 0.3) : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.12) : Color(red: 0.1, green: 0.1, blue: 0.3))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.1, green: 0.1, blue: 0.3).opacity(isSelected ? 0.4 : 0), lineWidth: 1)
                        )
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Paid")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(16)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
    }
}
