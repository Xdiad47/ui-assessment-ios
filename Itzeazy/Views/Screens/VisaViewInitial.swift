import SwiftUI

struct VisaViewInitial: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = VisaViewInitialViewModel()
    @FocusState private var isSearchFocused: Bool
    @State private var navigateToVisa = false
    @State private var keyboardHeight: CGFloat = 0

    private var isKeyboardPresented: Bool { keyboardHeight > 0 }

    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let overlayColor = Color.black.opacity(0.85)
    private let activeButtonColor = Color(red: 0.93, green: 0.13, blue: 0.14)
    private let inactiveButtonBase = Color(red: 0.82, green: 0.82, blue: 0.82)
    private let inactiveButtonTint = Color(red: 0.95, green: 0.77, blue: 0.78)

    var body: some View {
        GeometryReader { proxy in
            let headerHeight = proxy.safeAreaInsets.top + 60

            ZStack(alignment: .top) {
                backgroundLayer

                // ── Dismiss overlay (catches taps on empty areas) ─────────────
                if viewModel.isResultsVisible {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.isResultsVisible = false
                            isSearchFocused = false
                        }
                        .zIndex(1)
                }

                // ── Content (slides up when keyboard appears) ─────────────────
                VStack(spacing: 0) {
                    Color.clear.frame(height: headerHeight)
                    heroContent
                    Spacer()
                }
                .offset(y: isKeyboardPresented
                    ? -max(keyboardHeight - proxy.safeAreaInsets.bottom - 20, 0)
                    : 0
                )
                .animation(.easeInOut(duration: 0.28), value: isKeyboardPresented)
                .zIndex(2)

                // ── Header (always pinned, never moves) ───────────────────────
                VStack(spacing: 0) {
                    header(safeAreaTop: proxy.safeAreaInsets.top)
                    Spacer()
                }
                .zIndex(20)

                NavigationLink(
                    destination: VisaView(selectedCountry: viewModel.selectedCountry),
                    isActive: $navigateToVisa
                ) {
                    EmptyView()
                }
                .hidden()
                .zIndex(21)
            }
            .ignoresSafeArea()
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            ) { notification in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                else { return }
                withAnimation(.easeInOut(duration: 0.28)) {
                    keyboardHeight = frame.height
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            ) { _ in
                withAnimation(.easeInOut(duration: 0.28)) {
                    keyboardHeight = 0
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Background

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

    // MARK: - Header

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

            HStack(spacing: 10) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(activeButtonColor)
                        .frame(width: 32, height: 32)
                }

                Text("Visa")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                }

                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.22, green: 0.22, blue: 0.22))
                            .frame(width: 32, height: 32)
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .padding(.top, safeAreaTop)
        }
    }

    // MARK: - Hero content

    private var heroContent: some View {
        VStack(spacing: 0) {
            if !isKeyboardPresented {
                VStack(spacing: 12) {
                    Text("Get hassle free\nvisa")
                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 36))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("Apply For Visa Like You Have Done It 1000 Times Before, 100% success rate")
                        .font(Font.custom("Inter", size: 16))
                        .foregroundColor(Color.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 80)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            searchCard
                .padding(.top, isKeyboardPresented ? 16 : 44)

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(.easeInOut(duration: 0.28), value: isKeyboardPresented)
    }

    // MARK: - Search card

    private var searchCard: some View {
        // ZStack so the results dropdown floats over Get Started without pushing it
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // White top section
                VStack {
                    searchField
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(Color.white)
                .clipShape(RoundedCorner(radius: 28, corners: [.topLeft, .topRight]))

                // Get Started — stays fixed regardless of dropdown state
                Button(action: {
                    guard viewModel.buttonEnabled else { return }
                    navigateToVisa = true
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
                            if viewModel.buttonEnabled {
                                activeButtonColor
                            } else {
                                inactiveButtonBase
                                inactiveButtonTint.opacity(0.78)
                            }
                        }
                    )
                    .shadow(
                        color: viewModel.buttonEnabled ? activeButtonColor.opacity(0.35) : .clear,
                        radius: 10, x: 0, y: 6
                    )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.buttonEnabled)
                .clipShape(RoundedCorner(radius: 28, corners: [.bottomLeft, .bottomRight]))
            }

            // Floating results — overlays Get Started, never moves it
            // Offset: 20pt (top pad) + 58pt (field height) + 8pt (gap) = 86pt
            if viewModel.isResultsVisible && !viewModel.filteredCountries.isEmpty {
                resultsDropdown
                    .padding(.horizontal, 16)
                    .offset(y: 86)
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                    .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isResultsVisible)
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "location")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(
                    viewModel.isResultsVisible
                        ? activeButtonColor
                        : Color(red: 0.48, green: 0.48, blue: 0.48)
                )

            TextField("Search Country", text: $viewModel.searchText)
                .font(Font.custom("Inter", size: 16).weight(.medium))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                .focused($isSearchFocused)
                .autocorrectionDisabled()
                .onChange(of: isSearchFocused) { _, focused in
                    if focused {
                        if !viewModel.selectedCountry.isEmpty {
                            viewModel.searchText = ""
                            viewModel.selectedCountry = ""
                        }
                        viewModel.isResultsVisible = true
                    }
                }
                .onChange(of: viewModel.searchText) { _, newValue in
                    if newValue != viewModel.selectedCountry {
                        viewModel.isResultsVisible = true
                        viewModel.selectedCountry = ""
                    }
                }

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if viewModel.isResultsVisible {
                        viewModel.isResultsVisible = false
                        isSearchFocused = false
                    } else {
                        viewModel.isResultsVisible = true
                        isSearchFocused = true
                    }
                }
            }) {
                Image(systemName: viewModel.isResultsVisible ? "chevron.up" : "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(
                        viewModel.isResultsVisible
                            ? activeButtonColor
                            : Color(red: 0.38, green: 0.38, blue: 0.38)
                    )
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isResultsVisible)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    viewModel.isResultsVisible
                        ? activeButtonColor.opacity(0.65)
                        : Color(red: 0.72, green: 0.72, blue: 0.72),
                    lineWidth: 1.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Results dropdown

    private var resultsDropdown: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(viewModel.filteredCountries, id: \.self) { country in
                    HStack(spacing: 12) {
                        Text(country)
                            .font(Font.custom("Inter", size: 15).weight(.medium))
                            .foregroundColor(
                                country == viewModel.selectedCountry
                                    ? activeButtonColor
                                    : Color(red: 0.12, green: 0.12, blue: 0.12)
                            )
                        Spacer()
                        if country == viewModel.selectedCountry {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundColor(activeButtonColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(
                        country == viewModel.selectedCountry
                            ? activeButtonColor.opacity(0.06)
                            : Color.white
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.select(country: country)
                        isSearchFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }

                    if country != viewModel.filteredCountries.last {
                        Rectangle()
                            .fill(Color(red: 0.92, green: 0.92, blue: 0.92))
                            .frame(height: 1)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.never)
        .frame(height: 160)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.14), radius: 20, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationView {
        VisaViewInitial()
    }
}
