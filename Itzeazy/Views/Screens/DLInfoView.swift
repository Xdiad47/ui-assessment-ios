import SwiftUI

struct DLInfoView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = DLInfoViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            // Dark background fills entire screen incl. status bar — keeps it dark while scrolling
            Color(red: 0.10, green: 0.11, blue: 0.11).edgesIgnoringSafeArea(.all)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Dark top section (nav bar + input, scrolls with content) ───────────
                    VStack(spacing: 0) {

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
                                    Text("DL Details")
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

                        Spacer().frame(height: 32)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("DRIVING LICENCE NO")
                                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                                    .foregroundColor(.white)

                                TextField("HR-654365124512445", text: $viewModel.dlNumber)
                                    .font(Font.custom("Inter", size: 13))
                                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("DATE OF BIRTH (DOB)")
                                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                                    .foregroundColor(.white)

                                TextField("02-06-1986", text: $viewModel.dob)
                                    .font(Font.custom("Inter", size: 13))
                                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 24)

                        HStack(spacing: 16) {
                            Button(action: {
                                viewModel.dlNumber = ""
                                viewModel.dob = ""
                            }) {
                                Text("Reset")
                                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                    .frame(width: 115, height: 40)
                                    .background(Color(red: 0.88, green: 0.89, blue: 0.89))
                                    .clipShape(Capsule())
                            }

                            Button(action: {
                                viewModel.getDetails()
                            }) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                        .background(Color.red)
                                        .clipShape(Capsule())
                                } else {
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
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                    .background(
                        Color(red: 0.10, green: 0.11, blue: 0.11)
                            .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                    )

                    // ── Results content ───────────
                    VStack(spacing: 24) {
                        if let info = viewModel.dlInfo {
                            DLBasicInfoSection(info: info)
                            DLInitialDetailsSection(info: info)
                            DLValiditySection(info: info)
                            DLCOVSection(info: info)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 85)
                }
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.98))
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Section Components

private struct DLSectionHeader: View {
    let title: String
    @State private var lineWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 15))
                .foregroundColor(.black)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear { lineWidth = geo.size.width }
                    }
                )
            Rectangle()
                .fill(Color.red)
                .frame(width: lineWidth + 5, height: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DLInfoCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(white: 0.88), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

private struct DLInfoRow: View {
    let label: String
    var isLast: Bool = false
    @ViewBuilder let valueContent: () -> AnyView

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(label)
                    .font(Font.custom("Inter", size: 13).weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 140, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .frame(maxHeight: .infinity)
                    .background(Color(red: 0.10, green: 0.11, blue: 0.11))

                Rectangle()
                    .fill(Color(white: 0.85))
                    .frame(width: 1)

                valueContent()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .background(Color.white)
            }

            if !isLast {
                Rectangle()
                    .fill(Color(white: 0.88))
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Section Views

private struct DLBasicInfoSection: View {
    let info: DLInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DLSectionHeader(title: "Details Of Driving License: \(info.dlNumber)")

            DLInfoCard {
                DLInfoRow(label: "Current Status") {
                    AnyView(
                        Text(info.currentStatus)
                            .font(Font.custom("Inter", size: 11).weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color(red: 0.18, green: 0.72, blue: 0.42))
                            .cornerRadius(6)
                    )
                }
                DLInfoRow(label: "Holder Name") {
                    AnyView(
                        Text(info.holderName)
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                    )
                }
                DLInfoRow(label: "Old/New DL No.") {
                    AnyView(
                        Text(info.oldNewDLNumber)
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                    )
                }
                DLInfoRow(label: "Source Of Data", isLast: true) {
                    AnyView(
                        Text(info.sourceOfData)
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                    )
                }
            }
        }
    }
}

private struct DLInitialDetailsSection: View {
    let info: DLInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DLSectionHeader(title: "Driving Licens Initial Details")

            DLInfoCard {
                DLInfoRow(label: "Initial Issue Date") {
                    AnyView(
                        Text(info.initialIssueDate)
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                    )
                }
                DLInfoRow(label: "Initial Issuing Office", isLast: true) {
                    AnyView(
                        Text(info.initialIssuingOffice)
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                    )
                }
            }
        }
    }
}

private struct DLValiditySection: View {
    let info: DLInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DLSectionHeader(title: "Driving Licens Validity Details")

            DLInfoCard {
                // Non-Transport row
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Non-Transport")
                            .font(Font.custom("Inter", size: 13).weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 140, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .frame(maxHeight: .infinity)
                            .background(Color(red: 0.10, green: 0.11, blue: 0.11))

                        Rectangle()
                            .fill(Color(white: 0.85))
                            .frame(width: 1)

                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("From:")
                                    .font(Font.custom("Inter", size: 11))
                                    .foregroundColor(Color(white: 0.55))
                                Text(info.nonTransportFrom)
                                    .font(Font.custom("Inter", size: 13))
                                    .foregroundColor(Color(white: 0.2))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 14)

                            Rectangle()
                                .fill(Color(white: 0.88))
                                .frame(width: 1)
                                .padding(.vertical, 8)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("To:")
                                    .font(Font.custom("Inter", size: 11))
                                    .foregroundColor(Color(white: 0.55))
                                Text(info.nonTransportTo)
                                    .font(Font.custom("Inter", size: 13))
                                    .foregroundColor(Color(white: 0.2))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 10)
                            .padding(.trailing, 14)
                        }
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                    }

                    Rectangle()
                        .fill(Color(white: 0.88))
                        .frame(height: 1)
                }

                // Transport row
                HStack(spacing: 0) {
                    Text("Transport")
                        .font(Font.custom("Inter", size: 13).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 140, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .frame(maxHeight: .infinity)
                        .background(Color(red: 0.10, green: 0.11, blue: 0.11))

                    Rectangle()
                        .fill(Color(white: 0.85))
                        .frame(width: 1)

                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("From:")
                                .font(Font.custom("Inter", size: 11))
                                .foregroundColor(Color(white: 0.55))
                            Text(info.transportFrom)
                                .font(Font.custom("Inter", size: 13))
                                .foregroundColor(Color(white: 0.2))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 14)

                        Rectangle()
                            .fill(Color(white: 0.88))
                            .frame(width: 1)
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("From:")
                                .font(Font.custom("Inter", size: 11))
                                .foregroundColor(Color(white: 0.55))
                            Text(info.transportTo)
                                .font(Font.custom("Inter", size: 13))
                                .foregroundColor(Color(white: 0.2))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                        .padding(.trailing, 14)
                    }
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                }
            }
        }
    }
}

private struct DLCOVSection: View {
    let info: DLInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DLSectionHeader(title: "Class Of Vehicle Details")

            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    Text("COV Category")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.10, green: 0.11, blue: 0.11))

                    Rectangle()
                        .fill(Color(white: 0.25))
                        .frame(width: 1)

                    Text("Class Of Vehicle")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.10, green: 0.11, blue: 0.11))

                    Rectangle()
                        .fill(Color(white: 0.25))
                        .frame(width: 1)

                    Text("COV Issue Date")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.10, green: 0.11, blue: 0.11))
                }

                // Data rows
                ForEach(Array(info.covDetails.enumerated()), id: \.element.id) { index, detail in
                    Rectangle()
                        .fill(Color(white: 0.88))
                        .frame(height: 1)

                    HStack(spacing: 0) {
                        Text(detail.category)
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)

                        Rectangle()
                            .fill(Color(white: 0.88))
                            .frame(width: 1)

                        Text(detail.classOfVehicle)
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)

                        Rectangle()
                            .fill(Color(white: 0.88))
                            .frame(width: 1)

                        Text(detail.issueDate)
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(white: 0.2))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                    }
                }
            }
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(white: 0.88), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
    }
}

#Preview {
    DLInfoView()
}
