import SwiftUI

// MARK: - AttestationInitialView
// Figma: "attestation-landing-iphone-16-mobile" (node 7844:9647) — the Attestation service's entry
// screen, reached from the home screen's Attestation tile. Hero heading over the Figma background
// photo, then a white search card (destination search, popular destination chips, the two document
// dropdowns, Continue), then a trust strip.
//
// Continue has no next screen designed yet, so it shows the coming-soon toast used for every other
// unbuilt destination in this app.
//
// The search field and the popular destination chips drive the same selectedCountry, and the field
// shows that country's name once one is selected. Figma's sample shows the field as an empty
// placeholder while UAE is highlighted in the chips — here the two always agree instead.

private struct PopularDestination: Identifiable {
    let label: String
    let isoCode: String
    var id: String { isoCode }
}

private let popularDestinations: [PopularDestination] = [
    PopularDestination(label: "UAE", isoCode: "AE"),
    PopularDestination(label: "Saudi Arabia", isoCode: "SA"),
    PopularDestination(label: "Qatar", isoCode: "QA"),
    PopularDestination(label: "USA", isoCode: "US"),
    PopularDestination(label: "Germany", isoCode: "DE"),
    PopularDestination(label: "Australia", isoCode: "AU")
]

// Only the values shown in the Figma frame — the full option lists aren't in the design yet.
private let attestationNeedOptions = ["Educational Certificate"]
private let attestationDocumentOptions = ["Degree Certificate"]

struct AttestationInitialView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var tabBarState: TabBarState

    @State private var selectedCountry: CountryInfo? = countries.first { $0.isoCode == "AE" }
    @State private var selectedNeed: String = attestationNeedOptions[0]
    @State private var selectedDocument: String = attestationDocumentOptions[0]
    @State private var showCountryPicker = false
    @State private var showNeedPicker = false
    @State private var showDocumentPicker = false
    @State private var showComingSoonToast = false

    private let brandRed = Color(red: 1, green: 0, blue: 0)
    private let darkCard = Color(red: 0.10, green: 0.11, blue: 0.11)
    private let heroDark = Color(red: 0.051, green: 0.051, blue: 0.051)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let fieldBorder = Color(red: 0.898, green: 0.906, blue: 0.922)
    private let mutedText = Color(red: 0.420, green: 0.447, blue: 0.502)
    private let labelText = Color(red: 0.384, green: 0.408, blue: 0.431)
    private let darkText = Color(red: 0.118, green: 0.125, blue: 0.149)
    private let chipFill = Color(red: 0.969, green: 0.973, blue: 0.980)
    private let trustText = Color(red: 0.612, green: 0.639, blue: 0.686)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    header(safeAreaTop: proxy.safeAreaInsets.top)

                    ScrollView(showsIndicators: false) {
                        content
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if showComingSoonToast {
                    VStack {
                        Spacer()
                        ToastView(icon: "hourglass", message: "Coming soon! We're working hard to bring this to you.")
                            .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(backgroundLayer)
            .ignoresSafeArea(.container, edges: .vertical)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showComingSoonToast)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCountryPicker) {
            PickerSheetView(
                title: "Choose Country",
                items: countries,
                displayText: { $0.name },
                isSearchable: true,
                onSelect: { selectedCountry = $0 }
            )
        }
        .sheet(isPresented: $showNeedPicker) {
            PickerSheetView(
                title: "What Do You Need?",
                items: attestationNeedOptions.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                onSelect: { selectedNeed = $0.value }
            )
        }
        .sheet(isPresented: $showDocumentPicker) {
            PickerSheetView(
                title: "Select Document",
                items: attestationDocumentOptions.map { IdentifiableString(value: $0) },
                displayText: { $0.value },
                onSelect: { selectedDocument = $0.value }
            )
        }
    }

    private func showComingSoon() {
        showComingSoonToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { showComingSoonToast = false }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            heroDark

            Image("attestation_hero_bg")
                .resizable()
                .scaledToFill()

            LinearGradient(
                colors: [heroDark.opacity(0.25), heroDark],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipped()
        .ignoresSafeArea()
    }

    // MARK: - Header

    private func header(safeAreaTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            darkCard.frame(height: safeAreaTop)

            HStack(spacing: 6) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image("back_arrow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }

                Text("Back")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .tracking(-0.45)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
        .background(darkCard)
        .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 24) {
            heroTitle
            searchCard
            trustStrip
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, max(24, tabBarState.height + 16))
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
    }

    private var heroTitle: some View {
        Text("Get your documents attested with ease")
            .font(Font.custom("PlusJakartaSans-Bold", size: 28))
            .tracking(-0.5)
            .lineSpacing(8)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Search card

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("WHERE WILL YOU USE YOUR DOCUMENT?")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 12))
                    .foregroundColor(mutedText)

                countrySearchField
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Popular destinations")
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 13))
                    .foregroundColor(mutedText)

                FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(popularDestinations) { destination in
                        destinationChip(destination)
                    }
                }
            }

            HStack(alignment: .top, spacing: 24) {
                dropdownField(label: "WHAT DO YOU NEED?", value: selectedNeed) {
                    showNeedPicker = true
                }
                dropdownField(label: "SELECT DOCUMENT", value: selectedDocument) {
                    showDocumentPicker = true
                }
            }

            VStack(spacing: 10) {
                continueButton

                Text("Not sure what type of attestation you need? We'll help you figure it out.")
                    .font(Font.custom("PlusJakartaSans-Regular", size: 12))
                    .foregroundColor(mutedText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
        )
    }

    private var countrySearchField: some View {
        Button(action: { showCountryPicker = true }) {
            HStack(spacing: 10) {
                Image("attestation_search_icon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .foregroundColor(mutedText)

                Text(selectedCountry?.name ?? "Search and select country")
                    .font(Font.custom("PlusJakartaSans-Regular", size: 14))
                    .foregroundColor(selectedCountry == nil ? mutedText : darkText)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(strokeColor, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func destinationChip(_ destination: PopularDestination) -> some View {
        let isSelected = selectedCountry?.isoCode == destination.isoCode
        return Button(action: {
            selectedCountry = countries.first { $0.isoCode == destination.isoCode }
        }) {
            HStack(spacing: 4) {
                Text(flag(for: destination.isoCode))
                    .font(Font.custom("Inter", size: 12))
                Text(destination.label)
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 12))
                    .foregroundColor(darkText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.white : chipFill)
            .overlay(Capsule().stroke(isSelected ? brandRed : fieldBorder, lineWidth: 1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func dropdownField(label: String, value: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Font.custom("Inter-Bold", size: 11))
                .tracking(1)
                .foregroundColor(labelText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Button(action: action) {
                HStack(spacing: 8) {
                    Text(value)
                        .font(Font.custom("Inter", size: 14).weight(.medium))
                        .foregroundColor(mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image("attestation_chevron_up")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(labelText)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(fieldBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var continueButton: some View {
        Button(action: showComingSoon) {
            Text("Continue →")
                .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(brandRed)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func flag(for isoCode: String) -> String {
        isoCode.uppercased().unicodeScalars
            .compactMap { UnicodeScalar(127397 + $0.value) }
            .map { String(Character($0)) }
            .joined()
    }

    // MARK: - Trust strip

    private var trustStrip: some View {
        HStack(alignment: .center, spacing: 16) {
            trustItem(icon: "attestation_users_icon", text: "Trusted by 1000+ customers")
            trustItem(icon: "attestation_shield_icon", text: "End-to-end processing")
            trustItem(icon: "attestation_clock_icon", text: "Track in real-time")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private func trustItem(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(trustText)

            Text(text)
                .font(Font.custom("PlusJakartaSans-SemiBold", size: 13))
                .foregroundColor(trustText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationView {
        AttestationInitialView()
            .environmentObject(TabBarState())
    }
}
