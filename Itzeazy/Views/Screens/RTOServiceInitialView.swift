import SwiftUI

struct RTOServiceInitialView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = RTOServiceInitialViewModel()
    @State private var navigateToServices = false
    @State private var isLocationDropdownExpanded = false

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
                    destination: RTOServicesView(selectedLocation: viewModel.selectedLocation),
                    isActive: $navigateToServices
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .ignoresSafeArea()
        }
        .navigationBarHidden(true)
    }

    private var backgroundLayer: some View {
        ZStack {
            Image("services_bg_img")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            overlayColor
                .ignoresSafeArea()

            Circle()
                .fill(Color(red: 0.73, green: 0.0, blue: 0.07).opacity(0.30))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -80, y: 60)

            Circle()
                .fill(Color(red: 0.73, green: 0.0, blue: 0.07).opacity(0.20))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 100, y: 500)
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

                Text("RTO Services")
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
                Text("Unparalleled RTO\nservice")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 36))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("Hassle free door step service")
                    .font(Font.custom("Inter", size: 18))
                    .foregroundColor(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 80)

            locationSelectionCard
                .padding(.top, 44)

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var locationSelectionCard: some View {
        // ZStack so the dropdown can float over the Get Started button without shifting it
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // White top section
                VStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isLocationDropdownExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text(viewModel.selectedLocation.isEmpty ? "Choose Location" : viewModel.selectedLocation)
                                .font(Font.custom("Inter", size: 16).weight(.medium))
                                .foregroundColor(viewModel.selectedLocation.isEmpty ? Color(red: 0.48, green: 0.48, blue: 0.48) : Color(red: 0.10, green: 0.11, blue: 0.11))

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(isLocationDropdownExpanded ? activeButtonColor : Color(red: 0.38, green: 0.38, blue: 0.38))
                                .rotationEffect(.degrees(isLocationDropdownExpanded ? 180 : 0))
                                .animation(.easeInOut(duration: 0.2), value: isLocationDropdownExpanded)
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 58)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isLocationDropdownExpanded ? activeButtonColor.opacity(0.55) : Color(red: 0.72, green: 0.72, blue: 0.72),
                                    lineWidth: 1.5
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(Color.white)
                .clipShape(RoundedCorner(radius: 28, corners: [.topLeft, .topRight]))

                // Get Started button — stays in place regardless of dropdown state
                Button(action: {
                    guard viewModel.hasSelectedLocation else { return }
                    navigateToServices = true
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
                            if viewModel.hasSelectedLocation {
                                activeButtonColor
                            } else {
                                Color(red: 0.82, green: 0.82, blue: 0.82)
                                inactiveButtonColor.opacity(0.78)
                            }
                        }
                    )
                    .shadow(
                        color: viewModel.hasSelectedLocation ? activeButtonColor.opacity(0.35) : .clear,
                        radius: 10,
                        x: 0,
                        y: 6
                    )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasSelectedLocation)
                .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))
            }

            // Floating dropdown — overlays the Get Started button, never moves it
            // Offset: 20pt (top pad) + 58pt (button height) + 8pt (gap) = 86pt
            if isLocationDropdownExpanded {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(viewModel.locations, id: \.self) { location in
                            Button(action: {
                                viewModel.selectedLocation = location
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isLocationDropdownExpanded = false
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Text(location)
                                        .font(Font.custom("Inter", size: 15).weight(.medium))
                                        .foregroundColor(
                                            location == viewModel.selectedLocation
                                                ? activeButtonColor
                                                : Color(red: 0.12, green: 0.12, blue: 0.12)
                                        )

                                    Spacer()

                                    if location == viewModel.selectedLocation {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 15))
                                            .foregroundColor(activeButtonColor)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 40)
                                .background(
                                    location == viewModel.selectedLocation
                                        ? activeButtonColor.opacity(0.06)
                                        : Color.clear
                                )
                            }
                            .buttonStyle(.plain)

                            if location != viewModel.locations.last {
                                Rectangle()
                                    .fill(Color(red: 0.92, green: 0.92, blue: 0.92))
                                    .frame(height: 1)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.14), radius: 20, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .offset(y: 86)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isLocationDropdownExpanded)
    }
}

#Preview {
    NavigationView {
        RTOServiceInitialView()
    }
}
