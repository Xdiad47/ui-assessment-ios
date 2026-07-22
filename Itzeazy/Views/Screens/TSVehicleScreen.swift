import SwiftUI

struct TSVehicleScreen: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState
    @StateObject private var viewModel = ULIPTGVehicleViewModel()
    @State private var navigateToProfile = false

    private let dark = Color(red: 0.10, green: 0.11, blue: 0.11)

    var body: some View {
        ZStack(alignment: .top) {
            NavigationLink(destination: ProfileView(onBackToHome: nil), isActive: $navigateToProfile) {
                EmptyView()
            }.hidden()

            dark.edgesIgnoringSafeArea(.all)

            // ── Loading ────────────────────────────────────────────────────────
            if viewModel.isLoading {
                VStack(spacing: 0) {
                    navHeader
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                        Text("Fetching TS vehicle details…")
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    Spacer()
                    UlipDisclaimerFooter(isOnDarkBackground: true)
                        .padding(.bottom, tabBarState.height)
                }

            // ── Error ──────────────────────────────────────────────────────────
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 0) {
                    navHeader
                    searchCard
                        .background(dark.cornerRadius(20, corners: [.bottomLeft, .bottomRight]))
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.red)
                        Text(error)
                            .font(Font.custom("Inter", size: 14))
                            .foregroundColor(Color.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                    UlipDisclaimerFooter(isOnDarkBackground: true)
                        .padding(.bottom, tabBarState.height)
                }

            // ── Results ────────────────────────────────────────────────────────
            } else if let data = viewModel.vehicleData, viewModel.hasSearched {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            navHeader
                            searchCard
                        }
                        .background(dark.cornerRadius(20, corners: [.bottomLeft, .bottomRight]))

                        VStack(spacing: 24) {
                            TSVehicleHeaderCard(data: data)
                            TSRegistrationDetailsCard(data: data)
                            TSOwnerDetailsCard(data: data)

                            HStack(alignment: .top, spacing: 12) {
                                TSInsuranceCard(data: data).frame(maxWidth: .infinity)
                                TSPUCCard(data: data).frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal)

                            // Permit card — shown only when permit data is present
                            if data.permitNo != "N/A" {
                                TSPermitDetailsCard(data: data)
                            }

                            //TSOtherDetailsCard(data: data)

                            UlipDisclaimerFooter(isOnDarkBackground: false)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 20 + tabBarState.height)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.97))
                }

            // ── Initial ────────────────────────────────────────────────────────
            } else {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        navHeader
                        searchCard
                    }
                    .background(dark.cornerRadius(20, corners: [.bottomLeft, .bottomRight]))

                    ZStack(alignment: .bottom) {
                        Color.white
                        UlipDisclaimerFooter(isOnDarkBackground: false)
                            .padding(.bottom, tabBarState.height)
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Nav Header

    private var navHeader: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.72, green: 0.72, blue: 0.72))
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            dark
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
                    Text("TS Vehicle Details")
                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                        .foregroundColor(.white)
                }
                Spacer()
                HStack(spacing: 16) {
                    Image(systemName: "bell")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    Button(action: { navigateToProfile = true }) {
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
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
        }
    }

    // MARK: - Search Card

    private var searchCard: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TS VEHICLE NO")
                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                    .foregroundColor(.white)

                ZStack(alignment: .leading) {
                    if viewModel.vehicleNumber.isEmpty {
                        Text("e.g. TS09EA1234")
                            .font(Font.custom("Inter", size: 13))
                            .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.68))
                            .padding(.horizontal, 16)
                    }
                    TextField("", text: $viewModel.vehicleNumber)
                        .font(Font.custom("Inter", size: 13))
                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }
                .background(Color.white)
                .cornerRadius(12)

            }
            .padding(.horizontal, 16)
            .padding(.top, 24)

            HStack(spacing: 16) {
                Button(action: { viewModel.reset() }) {
                    Text("Reset")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                        .frame(width: 115, height: 40)
                        .background(Color(red: 0.88, green: 0.89, blue: 0.89))
                        .clipShape(Capsule())
                }

                let canSearch = !viewModel.vehicleNumber.trimmingCharacters(in: .whitespaces).isEmpty

                Button(action: { viewModel.search() }) {
                    Text("Check Status")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(canSearch ? Color.red : Color.red.opacity(0.4))
                        .clipShape(Capsule())
                        .shadow(color: Color.red.opacity(0.3), radius: 6, x: 0, y: 4)
                }
                .disabled(!canSearch || viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Header Card (like VehicleRegistrationCardView)

private struct TSVehicleHeaderCard: View {
    let data: TSVehicleData

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.red)
                .frame(width: 5)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(data.regNo)
                        .font(Font.custom("Plus Jakarta Sans", size: 20).weight(.heavy))
                        .foregroundColor(Color(red: 0.09, green: 0.09, blue: 0.11))
                        .padding(.top, 8)

                    Text("\(data.makerName)  \(data.modelDesc)")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(Color(red: 0.44, green: 0.44, blue: 0.48))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Owner: \(data.ownerName)")
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

// MARK: - Registration Details

private struct TSRegistrationDetailsCard: View {
    let data: TSVehicleData

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Registration Details")
                    .font(.headline).fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Text(data.rcStatus)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(12)
            }
            .padding()
            .background(Color(white: 0.15))

            VStack(spacing: 20) {
                TSDetailRow("VEHICLE NO",    data.regNo,
                            "CLASS",         data.vehicleClass)
                TSDetailRow("MAKER",         data.makerName,
                            "MODEL",         data.modelDesc)
                TSDetailRow("REG DATE",      data.registrationDate,
                            "RC VALID UPTO", data.rcValidUpto, rightAlert: true)
                TSDetailRow("COLOUR",        data.color,
                            "ISSUE PLACE",   data.issuePlace)
                TSDetailRow("FUEL",          data.fuel,
                            "CC",            data.cubicCapacity)
                TSDetailRow("BODY TYPE",     data.bodyType,
                            "MAKE YEAR",     data.makeYear)
                TSDetailRow("VEHICLE TYPE",  data.vehicleType,
                            "SEATING",       data.seatingCapacity)
                TSDetailRow("CHASSIS NO",    data.chassisNo,
                            "ENGINE NO",     data.engineNo)
                TSDetailRow("FC VALIDITY",   data.fcValidity,
                            "TAX VALIDITY",  data.taxValidity)
            }
            .padding()
            .background(Color.white)
        }
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
        .padding(.horizontal)
    }
}

// MARK: - Owner Details

private struct TSOwnerDetailsCard: View {
    let data: TSVehicleData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "person.circle")
                    .font(.system(size: 22))
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

            VStack(spacing: 14) {
                HStack {
                    TSOwnerField("OWNER NAME",   data.ownerName)
                    Spacer()
                    TSOwnerField("SL NO",        data.ownerSerialNo)
                    Spacer()
                    TSOwnerField("FATHER NAME",  data.fatherName)
                }

                TSOwnerFieldFull("PRESENT ADDRESS",   data.presentAddress)
                TSOwnerFieldFull("PERMANENT ADDRESS", data.permanentAddress)
                TSOwnerFieldFull("MOBILE NO",         data.mobileNo)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(red: 0.97, green: 0.98, blue: 0.98))
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
        }
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 0.5))
        .padding(.horizontal)
    }
}

// MARK: - Insurance Card

private struct TSInsuranceCard: View {
    let data: TSVehicleData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image("tick")
                    .resizable().scaledToFit()
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

            VStack(alignment: .leading, spacing: 6) {
                Text(data.insuranceCompany)
                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                Text("Policy: \(data.insuranceNo)")
                    .font(Font.custom("Inter", size: 11))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11).opacity(0.7))
                Text("Exp: \(data.insuranceValidity)")
                    .font(Font.custom("Inter", size: 11).italic())
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11).opacity(0.89))
            }
            .padding(.horizontal, 12).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 67, alignment: .leading)
            .background(Color.white)
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
        }
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 0.5))
    }
}

// MARK: - PUC Card

private struct TSPUCCard: View {
    let data: TSVehicleData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image("puc_green_icon")
                    .resizable().scaledToFit()
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

            VStack(alignment: .leading, spacing: 6) {
                Text("PUCC Valid")
                    .font(Font.custom("Inter", size: 12).weight(.semibold))
                    .foregroundColor(Color(red: 0.08, green: 0.50, blue: 0.24))
                Text("From: \(data.puccValidFrom)")
                    .font(Font.custom("Inter", size: 11).italic())
                    .foregroundColor(Color(red: 0.02, green: 0.02, blue: 0.02))
                Text("To: \(data.puccValidTo)")
                    .font(Font.custom("Inter", size: 11).italic())
                    .foregroundColor(Color(red: 0.02, green: 0.02, blue: 0.02))
            }
            .padding(.horizontal, 12).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 67, alignment: .leading)
            .background(Color.white)
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
        }
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 0.5))
    }
}

// MARK: - Other Details

//private struct TSOtherDetailsCard: View {
//    let data: TSVehicleData
//
//    var body: some View {
//        VStack(spacing: 0) {
//            HStack {
//                Image("other_details")
//                    .resizable().scaledToFit()
//                    .frame(width: 13, height: 14)
//                Text("OTHER DETAILS")
//                    .font(.system(size: 12, weight: .bold))
//                    .foregroundColor(.white)
//                Spacer()
//            }
//            .padding()
//            .background(Color(white: 0.15))
//
//            VStack(spacing: 16) {
//                TSKeyValue("Finance / Hypothecation", data.financerName)
//                TSKeyValue("Theft Status",
//                           data.theftStatus == "N" ? "Not Stolen" : data.theftStatus)
//                TSKeyValue("Tax Validity",     data.taxValidity)
//                TSKeyValue("FC Validity",      data.fcValidity)
//                TSKeyValue("Wheel Base",       data.wheelBase)
//                TSKeyValue("Unladen Weight",   data.ulw)
//                TSKeyValue("Gross Weight",     data.gvw)
//            }
//            .padding()
//            .background(Color.white)
//        }
//        .cornerRadius(12)
//        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
//        .padding(.horizontal)
//    }
//}

// MARK: - Permit Details Card

private struct TSPermitDetailsCard: View {
    let data: TSVehicleData

    // Expand single-letter VehicleType codes to human-readable labels
    private var vehicleTypeDisplay: String {
        switch data.vehicleType {
        case "T": return "T (Transport)"
        case "N": return "N (Non-Transport)"
        default:  return data.vehicleType
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ────────────────────────────────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                Text("PERMIT DETAILS")
                    .font(Font.custom("Inter", size: 12).weight(.bold))
                    .tracking(0.55)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color(red: 0.11, green: 0.11, blue: 0.12))
            .cornerRadius(10, corners: [.topLeft, .topRight])

            // ── Body ──────────────────────────────────────────────────────────
            VStack(spacing: 0) {

                TSPermitRow(label: "Permit No.",
                            value: data.permitNo,
                            isMonospaced: true)
                Divider().padding(.horizontal, 16)

                TSPermitRow(label: "Permit Type",
                            value: data.permitType,
                            isMonospaced: true)
                Divider().padding(.horizontal, 16)

                TSPermitRow(label: "Permit Valid Upto",
                            value: data.permitValidity,
                            isValidityBadge: true)
                Divider().padding(.horizontal, 16)

                TSPermitRow(label: "Vehicle Type",
                            value: vehicleTypeDisplay,
                            isMonospaced: true)
                Divider().padding(.horizontal, 16)

                TSPermitRow(label: "Class ID",
                            value: data.classID,
                            isMonospaced: true)
            }
            .background(Color.white)
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
        }
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 0.5))
        .padding(.horizontal)
    }
}

// MARK: - Permit Row helper

private struct TSPermitRow: View {
    let label: String
    let value: String
    var isMonospaced: Bool    = false
    var isValidityBadge: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(Font.custom("Inter", size: 13).weight(.medium))
                .foregroundColor(Color(red: 0.42, green: 0.42, blue: 0.45))

            Spacer()

            if isValidityBadge {
                Text(value)
                    .font(Font.custom("Inter", size: 12).weight(.bold))
                    .foregroundColor(Color(red: 0.08, green: 0.50, blue: 0.24))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.08, green: 0.50, blue: 0.24).opacity(0.12))
                    .cornerRadius(8)
            } else if isMonospaced {
                Text(value)
                    .font(Font.custom("Inter", size: 13).weight(.semibold).monospaced())
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.11))
            } else {
                Text(value)
                    .font(Font.custom("Inter", size: 13).weight(.semibold))
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.11))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Reusable row helpers

private struct TSDetailRow: View {
    let leftLabel: String;  let leftValue: String
    let rightLabel: String; let rightValue: String
    var leftAlert: Bool  = false
    var rightAlert: Bool = false

    init(_ leftLabel: String, _ leftValue: String,
         _ rightLabel: String, _ rightValue: String,
         leftAlert: Bool = false, rightAlert: Bool = false) {
        self.leftLabel  = leftLabel;  self.leftValue  = leftValue
        self.rightLabel = rightLabel; self.rightValue = rightValue
        self.leftAlert  = leftAlert;  self.rightAlert = rightAlert
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(leftLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(leftAlert ? .red : .gray)
                Text(leftValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(leftAlert ? .red : .black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(rightLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(rightAlert ? .red : .gray)
                Text(rightValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(rightAlert ? .red : .black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct TSOwnerField: View {
    let label: String
    let value: String
    init(_ label: String, _ value: String) { self.label = label; self.value = value }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Font.custom("Inter", size: 10).weight(.semibold))
                .tracking(0.5)
                .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
            Text(value)
                .font(Font.custom("Inter", size: 13).weight(.semibold))
                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.10))
        }
    }
}

private struct TSOwnerFieldFull: View {
    let label: String
    let value: String
    init(_ label: String, _ value: String) { self.label = label; self.value = value }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Font.custom("Inter", size: 10).weight(.semibold))
                .tracking(0.5)
                .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
            Text(value)
                .font(Font.custom("Inter", size: 13).weight(.semibold))
                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.10))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TSKeyValue: View {
    let label: String
    let value: String
    init(_ label: String, _ value: String) { self.label = label; self.value = value }

    var body: some View {
        HStack {
            Text(label).font(.system(size: 14, weight: .medium))
            Spacer()
            Text(value).font(.system(size: 14, weight: .bold))
                .foregroundColor(label.contains("Theft") && value == "Not Stolen" ? .green : .primary)
        }
    }
}

#Preview {
    TSVehicleScreen()
        .environmentObject(TabBarState())
}
