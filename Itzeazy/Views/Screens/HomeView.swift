import SwiftUI

//Enable navigation logic on tap on the profile icons in all top bar

// MARK: - HomeView

struct HomeView: View {

    var body: some View {
        ZStack(alignment: .top) {
            // Base background: completely dark for status bar and bounce area. Prevents white gaps.
            Color(red: 0.11, green: 0.11, blue: 0.11).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // Dark Section (Header & Hero)
                    VStack(spacing: 24) {
                        HomeHeaderView()
                            .padding(.horizontal, 0)
                        HomeHeroCardView()
                        .padding(.horizontal, 10)
                        .padding(.bottom, 25)
                    }
                    .background(Color(red: 0.11, green: 0.11, blue: 0.11))
                    .clipShape(RoundedCorner(radius: 20, corners: [.bottomRight, .bottomLeft]))

                    // White Section (Services & Utilities)
                    VStack(spacing: 32) {
                        HomeServicesGridView()
                            .padding(.top, 32)

                        HomeUtilitiesGridView()

                        HomeWorkflowView()

                        HomeValuePropositionView()
                    }
                }
                .background(Color.white)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

// MARK: - Subviews

struct HomeHeaderView: View {
    @EnvironmentObject private var userSession: UserSessionViewModel
    @EnvironmentObject private var authGate: AuthGateController
    @State private var navigateToProfile = false

    var body: some View {
        ZStack(alignment: .top) {
            NavigationLink(destination: ProfileView(onBackToHome: nil), isActive: $navigateToProfile) {
                EmptyView()
            }.hidden()
            // Back card: grey, slightly taller — peeks below the dark card
            Rectangle()
                .fill(Color(red: 0.72, green: 0.72, blue: 0.72))
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            // Front card: dark header — sits on top, grey peeks below
            Color(red: 0.10, green: 0.11, blue: 0.11)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            // Content on top
            HStack(spacing: 0) {
                Button(action: {
                    // Menu action
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.red)
                }

                Spacer().frame(width: 12)

                Text(userSession.displayName.isEmpty ? "Home" : "Hi, \(userSession.displayName)!")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 16) {
                    Image(systemName: "bell")
                        .font(.system(size: 18))
                        .foregroundColor(.white)

                    Button(action: {
                        guard authGate.requireAuth() else { return }
                        navigateToProfile = true
                    }) {
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
}

struct HomeHeroCardView: View {

    @StateObject private var vm = HomeHeroViewModel()
    @EnvironmentObject private var authGate: AuthGateController

    @State private var showCityPicker    = false
    @State private var showServicePicker = false
    @State private var showTypePicker    = false
    @StateObject private var webLoginVM  = WebLoginViewModel()

    private let accentRed = Color(red: 0.85, green: 0.2, blue: 0.2)
    private let fieldGray = Color(red: 0.55, green: 0.55, blue: 0.55)

    var body: some View {
        VStack(spacing: 20) {
            Text("Citizen services at doorstep")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            VStack(spacing: 12) {

                // --- Location (Full Width) ---
                Button(action: {
                    if !vm.isVisaSelected { showCityPicker = true }
                }) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(vm.isVisaSelected ? fieldGray.opacity(0.5) : fieldGray)
                        Text(vm.isVisaSelected
                             ? "Not required for Visa"
                             : (vm.selectedCity?.display ?? "Choose location"))
                            .foregroundColor(
                                vm.isVisaSelected
                                ? fieldGray.opacity(0.5)
                                : (vm.selectedCity != nil ? .black : fieldGray)
                            )
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(vm.isVisaSelected ? fieldGray.opacity(0.4) : fieldGray)
                    }
                    .padding()
                    .background(vm.isVisaSelected ? Color(red: 0.93, green: 0.93, blue: 0.93) : Color.white)
                    .cornerRadius(12)
                }
                .disabled(vm.isVisaSelected)

                // --- Service & Type - Side by Side ---
                HStack(spacing: 12) {

                    // Service picker
                    Button(action: { showServicePicker = true }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(fieldGray)
                            Text(vm.selectedService?.display ?? "Service")
                                .foregroundColor(vm.selectedService != nil ? .black : fieldGray)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(fieldGray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }

                    // Type / Sub-service picker
                    Button(action: {
                        if vm.selectedService != nil { showTypePicker = true }
                    }) {
                        HStack {
                            Image(systemName: vm.isVisaSelected ? "globe" : "doc.plaintext")
                                .foregroundColor(vm.selectedService == nil ? fieldGray.opacity(0.5) : fieldGray)
                            Text(vm.selectedSubService?.display ?? (vm.isVisaSelected ? "Country" : "Type"))
                                .foregroundColor(
                                    vm.selectedSubService != nil ? .black
                                    : (vm.selectedService == nil ? fieldGray.opacity(0.5) : fieldGray)
                                )
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(vm.selectedService == nil ? fieldGray.opacity(0.4) : fieldGray)
                        }
                        .padding()
                        .background(vm.selectedService == nil ? Color(red: 0.96, green: 0.96, blue: 0.96) : Color.white)
                        .cornerRadius(12)
                    }
                    .disabled(vm.selectedService == nil)
                }
            }

            // --- Get Started Button ---
            ZStack {
                NavigationLink(
                    destination: CitizenServicesWebView(
                        url: webLoginVM.generatedURL ?? "",
                        title: "Citizen Services"
                    ),
                    isActive: Binding(
                        get: { webLoginVM.generatedURL != nil },
                        set: { if !$0 { webLoginVM.reset() } }
                    )
                ) { EmptyView() }
                .hidden()

                Button(action: {
                    guard authGate.requireAuth() else { return }
                    if let url = vm.buildUrl() {
                        webLoginVM.generateToken(urlString: url, title: "Citizen Services")
                    }
                }) {
                    Group {
                        if webLoginVM.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.isGetStartedEnabled ? accentRed : accentRed.opacity(0.45))
                    .cornerRadius(12)
                }
                .disabled(!vm.isGetStartedEnabled || webLoginVM.isLoading)
            }
        }
        .padding(.horizontal)

        // MARK: - Sheet Pickers

        // City picker
        .sheet(isPresented: $showCityPicker) {
            PickerSheetView(
                title: "Choose Location",
                items: vm.cities,
                displayText: { $0.display },
                onSelect: { vm.selectedCity = $0 }
            )
        }

        // Service picker
        .sheet(isPresented: $showServicePicker) {
            PickerSheetView(
                title: "Choose Service",
                items: vm.services,
                displayText: { $0.display },
                onSelect: { vm.selectedService = $0 }
            )
        }

        // Sub-service / Type picker
        .sheet(isPresented: $showTypePicker) {
            PickerSheetView(
                title: vm.isVisaSelected ? "Choose Country" : "Choose Type",
                items: vm.availableSubServices,
                displayText: { $0.display },
                isSearchable: vm.isVisaSelected,
                onSelect: { vm.selectedSubService = $0 }
            )
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { webLoginVM.errorMessage != nil },
            set: { if !$0 { webLoginVM.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(webLoginVM.errorMessage ?? "")
        }
    }
}

// MARK: - Generic Picker Sheet

struct PickerSheetView<T: Identifiable>: View {
    let title: String
    let items: [T]
    let displayText: (T) -> String
    var isSearchable: Bool = false
    let onSelect: (T) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @State private var query: String = ""

    private var filtered: [T] {
        guard isSearchable, !query.trimmingCharacters(in: .whitespaces).isEmpty else { return items }
        return items.filter { displayText($0).localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // Search bar — shown only for searchable pickers (e.g. country list)
                if isSearchable {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                        TextField("Search country…", text: $query)
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                        if !query.isEmpty {
                            Button(action: { query = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider()
                }

                if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))
                        Text("No results for \"\(query)\"")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                    }
                    Spacer()
                } else {
                    List(filtered) { item in
                        Button(action: {
                            onSelect(item)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(displayText(item))
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
        // Every color in this sheet is hardcoded for a light background;
        // pinning the color scheme keeps text/backgrounds from mismatching in Dark Mode.
        .colorScheme(.light)
    }
}

// MARK: - HomeServicesGridView
// "Services We Provide" section — service buttons that open a WebView use CitizenServicesWebView

struct HomeServicesGridView: View {

    @StateObject private var vm = HomeServicesViewModel()
    @StateObject private var webLoginVM = WebLoginViewModel()
    @EnvironmentObject private var authGate: AuthGateController
    @State private var showComingSoonToast = false

    // Non-web service items kept inline (RTO, Visa, Attestation)
    private let allServices: [(String, String)] = [
        ("RTO\nServices", "rto_service"),
        ("Passport",      "passport"),
        ("Marriage\nReg.", "marriage_reg"),
        ("Birth Cert.",   "birth_certi"),
        ("IT Returns",    "it_returns"),
        ("Visa",          "visa"),
        ("Affidavit",     "affidavit"),
        ("POI/FRRO",      "poi_frro"),
        ("Attestation",   "attestation"),
        ("Pan Card",      "pan_card")
    ]

    // Not functional yet — tapping these shows a "coming soon" toast instead of navigating.
    private let comingSoonLabels: Set<String> = ["IT Returns", "Affidavit", "POI/FRRO", "Attestation"]

    // 5 Columns as per Figma
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                NavigationLink(
                    destination: CitizenServicesWebView(
                        url: webLoginVM.generatedURL ?? "",
                        title: webLoginVM.generatedTitle
                    ),
                    isActive: Binding(
                        get: { webLoginVM.generatedURL != nil },
                        set: { if !$0 { webLoginVM.reset() } }
                    )
                ) { EmptyView() }
                .hidden()

                VStack(alignment: .leading, spacing: 1) {
                    Text("Services We Provide")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Rectangle()
                        .fill(Color(red: 0.85, green: 0.2, blue: 0.2))
                        .frame(width: 203, height: 3)
                }
                .padding(.horizontal, 16)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(allServices, id: \.0) { service in
                        serviceCell(label: service.0, icon: service.1)
                    }
                }
                .padding(12)
                .padding(.bottom, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.894, green: 0.894, blue: 0.894),
                                    Color(red: 0.729, green: 0.729, blue: 0.729)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { webLoginVM.errorMessage != nil },
                set: { if !$0 { webLoginVM.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(webLoginVM.errorMessage ?? "")
            }

            if showComingSoonToast {
                ToastView(icon: "hourglass", message: "Coming soon! We're working hard to bring this to you.")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 12)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showComingSoonToast)
    }

    // MARK: - Cell builder
    @ViewBuilder
    private func serviceCell(label: String, icon: String) -> some View {
        // RTO — existing native screen
        if label.contains("RTO") {
            NavigationLink(destination: RTOServiceInitialView()) {
                ServiceBoxView(title: label, iconName: icon)
            }
            .buttonStyle(PlainButtonStyle())

        // Visa — existing native screen
        } else if label == "Visa" {
            NavigationLink(destination: VisaViewInitial()) {
                ServiceBoxView(title: label, iconName: icon)
            }
            .buttonStyle(PlainButtonStyle())

        // IT Returns, Affidavit, POI/FRRO, Attestation — not functional yet
        } else if comingSoonLabels.contains(label) {
            Button {
                showComingSoonToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showComingSoonToast = false
                }
            } label: {
                ServiceBoxView(title: label, iconName: icon)
            }
            .buttonStyle(NoHighlightButtonStyle())

        // All other service items — call token API then open WebView
        } else if let item = vm.webItems.first(where: { $0.label == label }) {
            Button {
                guard authGate.requireAuth() else { return }
                webLoginVM.generateToken(urlString: item.url, title: item.label)
            } label: {
                ServiceBoxView(title: label, iconName: icon)
            }
            .buttonStyle(NoHighlightButtonStyle())
            .disabled(webLoginVM.isLoading)

        } else {
            ServiceBoxView(title: label, iconName: icon)
        }
    }
}

// MARK: - HomeUtilitiesGridView
// "Utilities" section — some buttons open native screens, others open a WebView

struct HomeUtilitiesGridView: View {

    @StateObject private var vm = HomeUtilitiesViewModel()
    @StateObject private var webLoginVM = WebLoginViewModel()
    @EnvironmentObject private var authGate: AuthGateController
    @State private var showComingSoonToast = false

    private let allUtilities: [(String, String)] = [
        ("Vehicle\nInfo", "vehicle_info"),
        ("Challan\nInfo", "challan_info"),
        ("DL Info",       "dl_info"),
        ("TS Vehicle",    "ts_vehicle"),
        ("TS DL\nInfo",   "dl_info"),
        ("Road Tax",      "road_tax"),
        ("EV Charge",     "ev_charge"),
        ("Petrol\nPump",  "petrol_pump"),
        ("LL QB",         "ll_qb"),
        ("LL Mock",       "llmock")
    ]

    // 5 Columns as per Figma
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                NavigationLink(
                    destination: CitizenServicesWebView(
                        url: webLoginVM.generatedURL ?? "",
                        title: webLoginVM.generatedTitle
                    ),
                    isActive: Binding(
                        get: { webLoginVM.generatedURL != nil },
                        set: { if !$0 { webLoginVM.reset() } }
                    )
                ) { EmptyView() }
                .hidden()

                VStack(alignment: .leading, spacing: 1) {
                    Text("Utilities")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Rectangle()
                        .fill(Color(red: 0.85, green: 0.2, blue: 0.2))
                        .frame(width: 80, height: 3)
                }
                .padding(.horizontal, 16)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(allUtilities, id: \.0) { utility in
                        utilityCell(label: utility.0, icon: utility.1)
                    }
                }
                .padding(12)
                .padding(.bottom, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.894, green: 0.894, blue: 0.894),
                                    Color(red: 0.729, green: 0.729, blue: 0.729)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { webLoginVM.errorMessage != nil },
                set: { if !$0 { webLoginVM.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(webLoginVM.errorMessage ?? "")
            }

            if showComingSoonToast {
                ToastView(icon: "hourglass", message: "Coming soon! We're working hard to bring this to you.")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 12)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showComingSoonToast)
    }

    // MARK: - Cell builder
    @ViewBuilder
    private func utilityCell(label: String, icon: String) -> some View {
        switch label {
        case "Vehicle\nInfo":
            NavigationLink(destination: VehicleSearchResultsView()) {
                ServiceBoxView(title: label, iconName: icon)
            }
            .buttonStyle(PlainButtonStyle())

        case "Challan\nInfo":
            NavigationLink(destination: ChallanDetailsView()) {
                ServiceBoxView(title: label, iconName: icon)
            }
            .buttonStyle(PlainButtonStyle())

        case "DL Info":
            NavigationLink(destination: DLInfoView()) {
                ServiceBoxView(title: label, iconName: icon)
            }
            .buttonStyle(PlainButtonStyle())

        case "TS Vehicle":
            NavigationLink(destination: TSVehicleScreen()) {
                ServiceBoxView(title: label, iconName: icon)
            }
            .buttonStyle(PlainButtonStyle())

        case "TS DL\nInfo":
            NavigationLink(destination: TSDLInfoScreen()) {
                ServiceBoxView(title: label, iconName: icon)
            }
            .buttonStyle(PlainButtonStyle())

        case "EV Charge":
            NavigationLink(destination: EVChargeRouter()) {
                ServiceBoxView(title: label, iconName: icon)
            }
            .buttonStyle(PlainButtonStyle())

        case "Petrol\nPump":
            Button {
                showComingSoonToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showComingSoonToast = false
                }
            } label: {
                ServiceBoxView(title: label, iconName: icon)
            }
            .buttonStyle(NoHighlightButtonStyle())

        default:
            // Road Tax, LL QB, LL Mock — call token API then open WebView
            if let item = vm.webItems.first(where: { $0.label == label }) {
                Button {
                    guard authGate.requireAuth() else { return }
                    webLoginVM.generateToken(urlString: item.url, title: item.label)
                } label: {
                    ServiceBoxView(title: label, iconName: icon)
                }
                .buttonStyle(NoHighlightButtonStyle())
                .disabled(webLoginVM.isLoading)
            } else {
                ServiceBoxView(title: label, iconName: icon)
            }
        }
    }
}

struct ServiceBoxView: View {
    let title: String
    let iconName: String

    var body: some View {
        VStack(spacing: 6) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

            Text(title)
                .font(.system(size: 9))
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 66)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
