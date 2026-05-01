import SwiftUI

struct RTOServicesView: View {
    @StateObject private var viewModel = RTOServicesViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToVehicleSearch = false

    var body: some View {
        ZStack {
            Color(white: 0.98).edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // ── Dark top card ──────────────────────────────────────────
                VStack(spacing: 0) {
                    // Header row
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

                            Text("RTO Services")
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
                    .padding(EdgeInsets(top: 10, leading: 24, bottom: 10, trailing: 24))
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                            .mask(
                                VStack(spacing: 0) {
                                    Color.clear.frame(height: 42)
                                    Color.black
                                }
                            )
                    )

                    // Subtitle
                    Text("Citizen services at doorstep")
                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 20))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)

                    // Input fields
                    VStack(spacing: 12) {
                        // Location
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                                .frame(width: 16)
                            TextField("Choose location", text: $viewModel.selectedLocation)
                                .font(Font.custom("Inter", size: 14))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 46)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))

                        // Service + Type
                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 16)
                                TextField("Service", text: $viewModel.selectedService)
                                    .font(Font.custom("Inter", size: 14))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 46)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))

                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 16)
                                TextField("Type", text: $viewModel.selectedType)
                                    .font(Font.custom("Inter", size: 14))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 46)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Get Started — full-width, inside dark section
                    ZStack {
                        NavigationLink(
                            destination: VehicleSearchResultsView(),
                            isActive: $navigateToVehicleSearch
                        ) { EmptyView() }
                            .hidden()

                        Button(action: {
                            navigateToVehicleSearch = true
                        }) {
                            Text("Get Started")
                                .font(Font.custom("Inter", size: 16).weight(.semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.red)
                                .cornerRadius(12)
                                .shadow(color: Color.red.opacity(0.3), radius: 6, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
                .background(
                    Color(red: 0.1, green: 0.11, blue: 0.11)
                        .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                        .edgesIgnoringSafeArea(.top)
                )
                .zIndex(1)

                // ── Services grid ──────────────────────────────────────────
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("RTO Services in Bangalore")
                            .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                            .foregroundColor(Color(red: 0.1, green: 0.11, blue: 0.11))
                            .padding(.bottom, 8)
                            .overlay(
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(.red),
                                alignment: .bottom
                            )
                            .padding(.horizontal, 15)
                            .padding(.top, 20)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                            spacing: 8
                        ) {
                            ForEach(viewModel.rtoServices) { service in
                                RTOServiceGridCell(service: service)
                            }
                        }
                        .padding(.horizontal, 15)
                    }
                    .padding(.bottom, 100)
                }
                .background(Color.white)
                .zIndex(0)
            }
        }
        .navigationBarHidden(true)
    }
}

struct RTOServiceGridCell: View {
    let service: ServiceItem

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: service.iconName)
                .font(.system(size: 20))
                .foregroundColor(.red)
                .frame(width: 40, height: 40)

            Text(service.title)
                .font(Font.custom("Inter", size: 9).weight(.semibold))
                .foregroundColor(Color(red: 0.1, green: 0.11, blue: 0.11))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(height: 84)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
