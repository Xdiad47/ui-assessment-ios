import SwiftUI

struct VehicleRegistrationCardView: View {
    let details: VehicleRegistrationDetails
    let ownerName: String

    var body: some View {
        HStack(spacing: 0) {
            // Red left accent bar — clipped to card's cornerRadius automatically
            Rectangle()
                .fill(Color.red)
                .frame(width: 5)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(details.vehicleNo)
                        .font(Font.custom("Plus Jakarta Sans", size: 20).weight(.heavy))
                        .foregroundColor(Color(red: 0.09, green: 0.09, blue: 0.11))
                        .padding(.top, 8)

                    Text("\(details.maker) \(details.model)")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Owner: \(ownerName)")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.27))
                        .padding(.top, 12)
                }

                Spacer()

                Image("vehicle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 95, height: 110)
                    .clipped()
                    .cornerRadius(10)
            }
            .padding(20)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        .padding(.horizontal)
    }
}

struct VehicleRegistrationCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(white: 0.97).edgesIgnoringSafeArea(.all)
            VehicleRegistrationCardView(
                details: VehicleRegistrationDetails(
                    vehicleNo: "UP14CQ4004",
                    vehicleClass: "LMV",
                    maker: "Mahindra",
                    model: "XUV 500 (W8 Model • AWD)",
                    regDate: "12-Mar-2016",
                    fitnessUpto: "11-Mar-2031",
                    colour: "Silver",
                    registeredAt: "Deoria RTO, Uttar Pradesh",
                    fuel: "Diesel",
                    cc: "2179 CC",
                    chassisNo: "MA1T******34",
                    engineNo: "D4D*******89",
                    status: "ACTIVE"
                ),
                ownerName: "AH GA"
            )
        }
        .previewLayout(.sizeThatFits)
        .padding(.vertical)
    }
}
