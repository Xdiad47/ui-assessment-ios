import SwiftUI

struct VehicleSearchCardView: View {
    @State private var vehicleNo: String = ""
    var onCheckStatus: (() -> Void)? = nil
    var isEmbedded: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 24) {

                // Title
                Text("Check RTO Vehicle Information Detail")
                    .font(Font.custom("Plus Jakarta Sans", size: 16).weight(.heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                VStack(spacing: 18) {

                    // Vehicle No field
                    VStack(alignment: .leading, spacing: 12) {
                        Text("VEHICLE NO")
                            .font(Font.custom("Inter", size: 12).weight(.semibold))
                            .tracking(0.45)
                            .foregroundColor(.white)

                        ZStack(alignment: .leading) {
                            if vehicleNo.isEmpty {
                                Text("HR-654365124512445")
                                    .font(Font.custom("Inter", size: 14))
                                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                                    .padding(.horizontal, 9)
                            }
                            TextField("", text: $vehicleNo)
                                .font(Font.custom("Inter", size: 14))
                                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                .padding(EdgeInsets(top: 13, leading: 9, bottom: 14, trailing: 16))
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

                    // Action buttons — Reset compact, Check Status fills remaining width
                    HStack(spacing: 16) {

                        // Reset — natural compact size
                        Button(action: { vehicleNo = "" }) {
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

                        // Check Status — fills remaining space
                        Button(action: { onCheckStatus?() }) {
                            Text("Check Status")
                                .font(Font.custom("Inter", size: 12).weight(.bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .background(Color(red: 0.93, green: 0.13, blue: 0.14))
                        .clipShape(Capsule())
                        .shadow(
                            color: Color(red: 0.93, green: 0.13, blue: 0.14).opacity(0.20),
                            radius: 6, y: 4
                        )
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
            Color(white: 0.97).edgesIgnoringSafeArea(.all)
            VehicleSearchCardView()
        }
        .previewLayout(.sizeThatFits)
        .padding(.vertical)
    }
}
