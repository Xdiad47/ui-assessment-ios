import SwiftUI

struct TSDLInfoScreen: View {
    @StateObject private var viewModel = ULIPTGDLViewModel()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.11, green: 0.11, blue: 0.11).ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else if viewModel.hasSearched, let data = viewModel.dlData {
                    resultsView(data: data)
                } else {
                    initialView
                }
            }
        }
        .navigationTitle("")
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

            Color(red: 0.10, green: 0.11, blue: 0.11)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 0) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.red)
                }

                Spacer().frame(width: 12)

                Text("TS DL Info")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

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

    // MARK: - Search Card

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DRIVING LICENCE NO")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))

            TextField("", text: $viewModel.dlNumber,
                      prompt: Text("e.g. TS00920200012345")
                          .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60)))
                .foregroundColor(.black)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(10)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)

            let canSearch = !viewModel.dlNumber.trimmingCharacters(in: .whitespaces).isEmpty

            HStack(spacing: 12) {
                Button(action: { viewModel.reset() }) {
                    Text("Reset")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(red: 0.88, green: 0.88, blue: 0.88))
                        .cornerRadius(25)
                }

                Button(action: { viewModel.search() }) {
                    Text("Check Status")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(canSearch && !viewModel.isLoading
                            ? Color(red: 0.85, green: 0.15, blue: 0.15)
                            : Color(red: 0.50, green: 0.15, blue: 0.15))
                        .cornerRadius(25)
                }
                .disabled(!canSearch || viewModel.isLoading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color(red: 0.11, green: 0.11, blue: 0.11))
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 0) {
            navHeader
            searchCard
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.4)
            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 0) {
            navHeader
            searchCard
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(red: 0.85, green: 0.15, blue: 0.15))
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }

    private var initialView: some View {
        VStack(spacing: 0) {
            navHeader
            searchCard

            ZStack {
                Color.white
                Text("Enter a Telangana DL number, then tap Check Status")
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }

    private func resultsView(data: TSDLData) -> some View {
        VStack(spacing: 0) {
            navHeader
            searchCard

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    TSDLHeaderCard(data: data)
                    TSDLPersonalCard(data: data)
                    TSDLAddressCard(data: data)
                    TSDLLicenceCard(data: data)
                    TSDLCOVCard(data: data)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 95)
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

// MARK: - Header Card

private struct TSDLHeaderCard: View {
    let data: TSDLData

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(red: 0.85, green: 0.15, blue: 0.15))
                .frame(height: 4)
                .cornerRadius(2)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(data.dlNumber)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)

                    Text(data.fullName)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))

                    HStack(spacing: 6) {
                        Circle()
                            .fill(data.dlStatus.uppercased() == "ACTIVE"
                                  ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(data.dlStatus)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(data.dlStatus.uppercased() == "ACTIVE"
                                             ? .green : .orange)
                    }
                }

                Spacer()

                Image(systemName: "creditcard.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(Color(red: 0.85, green: 0.15, blue: 0.15).opacity(0.25))
            }
            .padding(14)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Personal Details Card

private struct TSDLPersonalCard: View {
    let data: TSDLData

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Personal Details")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 0.13, green: 0.13, blue: 0.13))
            .cornerRadius(12, corners: [.topLeft, .topRight])

            VStack(spacing: 0) {
                TSDLRow(label: "Date of Birth",   value: data.dateOfBirth)
                TSDLDivider()
                TSDLRow(label: "Gender",          value: data.genderDescription)
                TSDLDivider()
                TSDLRow(label: "Blood Group",     value: data.bloodGroupName)
                TSDLDivider()
                TSDLRow(label: "Qualification",   value: data.qualificationDescription)
                TSDLDivider()
                TSDLRow(label: "Father / Husband", value: data.swdFullName)
                TSDLDivider()
                TSDLRow(label: "Mobile",          value: data.mobileNumber)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Address Card

private struct TSDLAddressCard: View {
    let data: TSDLData

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Address")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 0.13, green: 0.13, blue: 0.13))
            .cornerRadius(12, corners: [.topLeft, .topRight])

            VStack(spacing: 0) {
                TSDLRowFull(label: "Permanent Address",  value: data.permanentAddress)
                TSDLDivider()
                TSDLRow(label: "Permanent District", value: data.permanentDistrictName)
                TSDLDivider()
                TSDLRowFull(label: "Temporary Address",  value: data.temporaryAddress)
                TSDLDivider()
                TSDLRow(label: "Temporary District", value: data.temporaryDistrictName)
                TSDLDivider()
                TSDLRow(label: "State",              value: data.stateName)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Licence Details Card

private struct TSDLLicenceCard: View {
    let data: TSDLData

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Licence Details")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 0.13, green: 0.13, blue: 0.13))
            .cornerRadius(12, corners: [.topLeft, .topRight])

            VStack(spacing: 0) {
                TSDLRow(label: "Issue Date",           value: data.dlIssueDate)
                TSDLDivider()
                TSDLRow(label: "RTO Code",             value: data.dlRtoCode)
                TSDLDivider()
                TSDLRowFull(label: "RTO Name",         value: data.rtoFullName)
                TSDLDivider()
                TSDLRow(label: "Non-Transport Valid From", value: data.dlNonTransportValidFrom)
                TSDLDivider()
                TSDLRow(label: "Transport Valid From", value: data.dlTransportValidFrom)
                TSDLDivider()
                TSDLRow(label: "Transport Valid To",   value: data.dlTransportValidTo)
                TSDLDivider()
                TSDLRow(label: "Hazardous From",       value: data.dlHazardousFrom)
                TSDLDivider()
                TSDLRow(label: "Hazardous To",         value: data.dlHazardousTo)
                TSDLDivider()
                TSDLRow(label: "Hill Valid From",      value: data.dlHillFrom)
                TSDLDivider()
                TSDLRow(label: "Hill Valid To",        value: data.dlHillTo)
                TSDLDivider()
                TSDLRow(label: "Endorsement Date",     value: data.dlEndorseDate)
                TSDLDivider()
                TSDLRow(label: "Endorsement Time",     value: data.dlEndorseTime)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

// MARK: - COV Card

private struct TSDLCOVCard: View {
    let data: TSDLData

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Class of Vehicle (COV)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(red: 0.13, green: 0.13, blue: 0.13))
            .cornerRadius(12, corners: [.topLeft, .topRight])

            VStack(spacing: 0) {
                TSDLRow(label: "COV Code",        value: data.covAbbreviation)
                TSDLDivider()
                TSDLRowFull(label: "Description", value: data.covDescription)
                TSDLDivider()
                TSDLRow(label: "Issue Date",      value: data.covIssueDate)
                TSDLDivider()
                TSDLRow(label: "COV Status",      value: data.dlCovStatus)
                TSDLDivider()
                TSDLRow(label: "Objection",       value: data.objectionType)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Row helpers

private struct TSDLRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.50, green: 0.50, blue: 0.50))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }
}

private struct TSDLRowFull: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.50, green: 0.50, blue: 0.50))
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

private struct TSDLDivider: View {
    var body: some View {
        Divider()
            .background(Color(red: 0.93, green: 0.93, blue: 0.93))
    }
}

// MARK: - Preview

struct TSDLInfoScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TSDLInfoScreen()
        }
    }
}

