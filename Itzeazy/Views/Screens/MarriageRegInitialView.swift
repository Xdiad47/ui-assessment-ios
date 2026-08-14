import SwiftUI

struct MarriageRegInitialView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = MarriageRegInitialViewModel()
    @StateObject private var disclaimerGate = GovDisclaimerGate(serviceKey: "marriage_reg")
    @State private var navigateToDetail = false
    @State private var showLocationPicker = false
    @State private var showServicePicker = false

    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let overlayColor = Color.black.opacity(0.85)
    private let activeButtonColor = Color(red: 0.93, green: 0.13, blue: 0.14)
    private let inactiveButtonColor = Color(red: 0.95, green: 0.77, blue: 0.78)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                backgroundLayer

                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        header(safeAreaTop: proxy.safeAreaInsets.top)
                        heroContent
                    }

                    Spacer()
                }

                NavigationLink(
                    destination: MarriageRegDetailView(
                        location: viewModel.selectedLocation,
                        service: viewModel.selectedService
                    ),
                    isActive: $navigateToDetail
                ) {
                    EmptyView()
                }
                .hidden()

                if disclaimerGate.isPresented {
                    GovDisclaimerPopupView(
                        onAcknowledge: disclaimerGate.acknowledge,
                        onDismiss: { presentationMode.wrappedValue.dismiss() }
                    )
                    .zIndex(30)
                }
            }
            .ignoresSafeArea()
        }
        .navigationBarHidden(true)
        .onAppear {
            disclaimerGate.checkOnAppear()
            viewModel.fetchCities()
        }
        .sheet(isPresented: $showLocationPicker) {
            PickerSheetView(
                title: "Choose Location",
                items: viewModel.locations.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                onSelect: { viewModel.selectedLocation = $0.value }
            )
        }
        .sheet(isPresented: $showServicePicker) {
            PickerSheetView(
                title: "Choose Service",
                items: viewModel.serviceOptions.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                onSelect: { viewModel.selectedService = $0.value }
            )
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            Image("services_bg_img")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            overlayColor
                .ignoresSafeArea()
        }
    }

    private func header(safeAreaTop: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(strokeColor)
                .frame(maxWidth: .infinity)
                .frame(height: safeAreaTop + 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            Color(red: 0.10, green: 0.11, blue: 0.11)
                .frame(maxWidth: .infinity)
                .frame(height: safeAreaTop + 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 12) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image("back_arrow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }

                Text("Marriage Registration")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
            .padding(.top, safeAreaTop)
        }
    }

    private var heroContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("Hassle free marriage\ncertificate service")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 36))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("We make Marriage Registration process faster")
                    .font(Font.custom("Inter", size: 16))
                    .foregroundColor(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.top, 80)

            selectionCard
                .padding(.top, 44)

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var selectionCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                pickerField(
                    placeholder: "Choose Location",
                    value: viewModel.selectedLocation,
                    isLoading: viewModel.isLoading,
                    action: { showLocationPicker = true }
                )
                pickerField(
                    placeholder: "Choose Service",
                    value: viewModel.selectedService,
                    isLoading: false,
                    action: { showServicePicker = true }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(Color.white)
            .clipShape(RoundedCorner(radius: 28, corners: [.topLeft, .topRight]))

            Button(action: {
                guard viewModel.hasSelectedLocationAndService else { return }
                navigateToDetail = true
            }) {
                HStack(spacing: 8) {
                    Text("Get Started")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                        .foregroundColor(.white)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 68)
                .background(
                    ZStack {
                        if viewModel.hasSelectedLocationAndService {
                            activeButtonColor
                        } else {
                            Color(red: 0.82, green: 0.82, blue: 0.82)
                            inactiveButtonColor.opacity(0.78)
                        }
                    }
                )
                .shadow(
                    color: viewModel.hasSelectedLocationAndService ? activeButtonColor.opacity(0.35) : .clear,
                    radius: 10,
                    x: 0,
                    y: 6
                )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.hasSelectedLocationAndService)
            .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))
        }
        .frame(maxWidth: .infinity)
        .colorScheme(.light)
    }

    private func pickerField(placeholder: String, value: String, isLoading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: activeButtonColor))
                        .frame(maxWidth: .infinity)
                } else {
                    Text(value.isEmpty ? placeholder : value)
                        .font(Font.custom("Inter", size: 16).weight(.medium))
                        .foregroundColor(value.isEmpty ? Color(red: 0.48, green: 0.48, blue: 0.48) : Color(red: 0.10, green: 0.11, blue: 0.11))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.38, green: 0.38, blue: 0.38))
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 58)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        value.isEmpty ? Color(red: 0.72, green: 0.72, blue: 0.72) : activeButtonColor.opacity(0.55),
                        lineWidth: 1.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationView {
        MarriageRegInitialView()
    }
}
