import SwiftUI

struct ChallanDetailPopup: View {
    let challan: Challan
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // Close button row
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(white: 0.5))
                        .frame(width: 24, height: 24)
                        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
                        .cornerRadius(10)
                }
            }
            .padding(.bottom, 12)

            // Header buttons
            HStack(spacing: 12) {
                headerButton("Challan Details")
                headerButton("Offence Details")
            }
            .padding(.bottom, 16)

            // Two-column content
            HStack(alignment: .top, spacing: 13) {

                // Left column
                VStack(alignment: .leading, spacing: 14) {
                    fieldView(label: "CHALLAN NO", value: challan.challanNo)

                    HStack(spacing: 10) {
                        Text("STATUS")
                            .font(Font.custom("Inter", size: 10).weight(.semibold))
                            .tracking(0.50)
                            .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                        Text(challan.status)
                            .font(Font.custom("Inter", size: 8).weight(.semibold))
                            .tracking(0.50)
                            .foregroundColor(Color(red: 0.58, green: 0, blue: 0.04))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(red: 1, green: 0.85, blue: 0.84))
                            .clipShape(Capsule())
                    }

                    fieldView(label: "CHALLAN DATE & TIME", value: challan.dateTime)

                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SENT TO\nCOURT")
                                .font(Font.custom("Inter", size: 10).weight(.semibold))
                                .tracking(0.50)
                                .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(challan.sentToCourt ? "Yes" : "No")
                                .font(Font.custom("Inter", size: 12))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("STATE\nCODE")
                                .font(Font.custom("Inter", size: 10).weight(.semibold))
                                .tracking(0.50)
                                .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(challan.stateCode)
                                .font(Font.custom("Inter", size: 12))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Red divider
                Rectangle()
                    .fill(Color(red: 0.93, green: 0.13, blue: 0.14))
                    .frame(width: 4, height: 220)

                // Right column
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NAME OF OFFENCE")
                            .font(Font.custom("Inter", size: 10).weight(.semibold))
                            .tracking(0.50)
                            .foregroundColor(Color(red: 0.93, green: 0.13, blue: 0.14))
                        Text(challan.offenceName)
                            .font(Font.custom("Inter", size: 11))
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ACT")
                                .font(Font.custom("Inter", size: 10).weight(.semibold))
                                .tracking(0.50)
                                .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                            Text(challan.act)
                                .font(Font.custom("Inter", size: 12))
                                .foregroundColor(.black)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("FINE AMOUNT")
                                .font(Font.custom("Inter", size: 10).weight(.semibold))
                                .tracking(0.50)
                                .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                            Text("₹ \(challan.amount).00")
                                .font(Font.custom("Inter", size: 12))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(alignment: .top, spacing: 11) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PROCESSING\nDATE")
                                .font(Font.custom("Inter", size: 9).weight(.semibold))
                                .tracking(0.50)
                                .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(challan.processingDate)
                                .font(Font.custom("Inter", size: 12))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("RTO\nDISTRICT")
                                .font(Font.custom("Inter", size: 10).weight(.semibold))
                                .tracking(0.50)
                                .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(challan.rtoDistrict)
                                .font(Font.custom("Inter", size: 12))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("COURT DETAILS")
                            .font(Font.custom("Inter", size: 10).weight(.semibold))
                            .tracking(0.50)
                            .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                        Text(challan.courtDetails)
                            .font(Font.custom("Inter", size: 12))
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 20)

            // Bottom: Total fine + actions
            HStack {
                VStack(spacing: 2) {
                    Text("TOTAL FINE IMPOSED")
                        .font(Font.custom("Inter", size: 11).weight(.semibold))
                        .tracking(0.60)
                        .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                    Text("₹ \(challan.totalFine)")
                        .font(Font.custom("Inter", size: 18).weight(.semibold))
                        .foregroundColor(Color(red: 0.93, green: 0.13, blue: 0.14))
                }
                .padding(6)
                .frame(width: 154)
                .background(Color(red: 0.92, green: 0.92, blue: 0.92))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.40, green: 0.40, blue: 0.40).opacity(0.28), lineWidth: 0.50)
                )

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {}) {
                        Text("Pay Now")
                            .font(Font.custom("Inter", size: 11).weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 26)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.93, green: 0.13, blue: 0.14))
                            .cornerRadius(12)
                    }

                    Button(action: {}) {
                        Text("Receipt")
                            .font(Font.custom("Inter", size: 11).weight(.semibold))
                            .foregroundColor(Color(red: 0.10, green: 0.45, blue: 0.91))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 20, y: 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: 372)
    }

    @ViewBuilder
    private func headerButton(_ title: String) -> some View {
        ZStack {
            // Red card — full width, sits behind
            RoundedRectangle(cornerRadius: 9)
                .fill(Color(red: 0.93, green: 0.13, blue: 0.14))

            // Navy card — 5pt inset from left, so red shows on left edge only
            RoundedRectangle(cornerRadius: 9)
                .fill(Color(red: 0.13, green: 0.13, blue: 0.28))
                .padding(.leading, 5)

            // Label centred over the navy area
            Text(title)
                .font(Font.custom("Plus Jakarta Sans", size: 16).weight(.bold))
                .foregroundColor(.white)
                .padding(.leading, 5)
        }
        .frame(maxWidth: .infinity, minHeight: 39, maxHeight: 39)
    }

    @ViewBuilder
    private func fieldView(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Font.custom("Inter", size: 10).weight(.semibold))
                .tracking(0.50)
                .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
            Text(value)
                .font(Font.custom("Inter", size: 12))
                .foregroundColor(.black)
        }
    }
}
