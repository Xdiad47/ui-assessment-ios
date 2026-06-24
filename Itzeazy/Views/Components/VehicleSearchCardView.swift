import SwiftUI

enum VehicleSearchType: String, CaseIterable {
    case vehicle = "Vehicle"
    case chassis = "Chassis"
    case engine  = "Engine"

    var inputLabel: String {
        switch self {
        case .vehicle: return "VEHICLE NO"
        case .chassis: return "CHASSIS NO"
        case .engine:  return "ENGINE NO"
        }
    }

    var placeholder: String {
        switch self {
        case .vehicle: return "e.g. HR26DX3155"
        case .chassis: return "e.g. MA1PB2HEXPM123456"
        case .engine:  return "e.g. G13B12345"
        }
    }
}

struct VehicleSearchCardView: View {
    @Binding var vehicleNo: String
    @Binding var searchType: VehicleSearchType
    var onCheckStatus: (() -> Void)? = nil
    var onReset: (() -> Void)? = nil
    var isEmbedded: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 20) {

                // Title
                Text("Check RTO Vehicle Information Detail")
                    .font(Font.custom("Plus Jakarta Sans", size: 16).weight(.heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Tab selector — Vehicle / Chassis / Engine
                HStack(spacing: 0) {
                    ForEach(VehicleSearchType.allCases, id: \.self) { tab in
                        Button(action: {
                            searchType = tab
                            vehicleNo  = ""
                            onReset?()
                        }) {
                            VStack(spacing: 6) {
                                Text(tab.rawValue)
                                    .font(Font.custom("Inter", size: 14)
                                        .weight(searchType == tab ? .bold : .regular))
                                    .foregroundColor(searchType == tab
                                        ? .white
                                        : Color.white.opacity(0.45))

                                Rectangle()
                                    .fill(searchType == tab
                                        ? Color(red: 0.93, green: 0.13, blue: 0.14)
                                        : Color.white.opacity(0.15))
                                    .frame(height: 2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                VStack(spacing: 18) {

                    // Input field — label and placeholder follow selected tab
                    VStack(alignment: .leading, spacing: 12) {
                        Text(searchType.inputLabel)
                            .font(Font.custom("Inter", size: 12).weight(.semibold))
                            .tracking(0.45)
                            .foregroundColor(.white)

                        ZStack(alignment: .leading) {
                            if vehicleNo.isEmpty {
                                Text(searchType.placeholder)
                                    .font(Font.custom("Inter", size: 14))
                                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                                    .padding(.horizontal, 9)
                            }
                            TextField("", text: $vehicleNo)
                                .font(Font.custom("Inter", size: 14))
                                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                                .padding(EdgeInsets(top: 13, leading: 9, bottom: 14, trailing: 16))
                                .onChange(of: vehicleNo) { newValue in
                                    let uppercased = newValue.uppercased()
                                    if newValue != uppercased { vehicleNo = uppercased }
                                }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .inset(by: 0.5)
                                .stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 0.5)
                        )
                    }
                    .frame(maxWidth: .infinity)

                    // Action buttons
                    HStack(spacing: 16) {

                        Button(action: {
                            vehicleNo = ""
                            onReset?()
                        }) {
                            Text("Reset")
                                .font(Font.custom("Inter", size: 12).weight(.semibold))
                                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 24)
                        }
                        .background(Color(red: 0.88, green: 0.89, blue: 0.89))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .inset(by: 0.5)
                                .stroke(Color(red: 0.88, green: 0.89, blue: 0.89).opacity(0.30), lineWidth: 0.5)
                        )

                        Button(action: { onCheckStatus?() }) {
                            Text("Check Status")
                                .font(Font.custom("Inter", size: 12).weight(.bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .background(
                            vehicleNo.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(red: 0.93, green: 0.13, blue: 0.14).opacity(0.45)
                                : Color(red: 0.93, green: 0.13, blue: 0.14)
                        )
                        .clipShape(Capsule())
                        .shadow(
                            color: Color(red: 0.93, green: 0.13, blue: 0.14).opacity(0.20),
                            radius: 6, y: 4
                        )
                        .disabled(vehicleNo.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, isEmbedded ? 20 : 60)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(isEmbedded ? Color.clear : Color(red: 0.10, green: 0.11, blue: 0.11))
        .cornerRadius(isEmbedded ? 0 : 20)
        .padding(.horizontal, isEmbedded ? 0 : 16)
    }
}

struct VehicleSearchCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 0.10, green: 0.11, blue: 0.11).edgesIgnoringSafeArea(.all)
            VehicleSearchCardView(vehicleNo: .constant(""), searchType: .constant(.vehicle))
        }
        .previewLayout(.sizeThatFits)
        .padding(.vertical)
    }
}
