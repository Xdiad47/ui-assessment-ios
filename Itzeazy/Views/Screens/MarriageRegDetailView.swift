import SwiftUI

// The live site's Marriage Registration page for Bangalore is spelled "banglore" (verified
// against the actual URL) — every other city uses normal spelling. Mirrors Android's
// marriageRegRedirectPath() in MainScreen.kt exactly.
private func marriageRegRedirectPath(city: String) -> String {
    let slug = city.caseInsensitiveCompare("Bangalore") == .orderedSame ? "banglore" : city.lowercased()
    return "https://itzeazy.in/order/marriage-registration-\(slug)"
}

struct MarriageRegDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var authGate: AuthGateController
    @StateObject private var viewModel = MarriageRegDetailViewModel()
    @StateObject private var webLoginVM = WebLoginViewModel()
    @StateObject private var disclaimerGate = GovDisclaimerGate(serviceKey: "marriage_reg")
    @State private var selectedService: String
    @State private var showWebView = false

    let location: String
    let showEntryDisclaimer: Bool

    init(location: String, service: String, showEntryDisclaimer: Bool = false) {
        self.location = location
        self._selectedService = State(initialValue: service)
        self.showEntryDisclaimer = showEntryDisclaimer
    }

    var body: some View {
        ZStack(alignment: .top) {
            NavigationLink(
                destination: Group {
                    if let url = webLoginVM.generatedURL {
                        CitizenServicesWebView(
                            url: url,
                            title: webLoginVM.generatedTitle,
                            onBack: { showWebView = false },
                            showGovBanner: true
                        )
                    }
                },
                isActive: $showWebView
            ) {
                EmptyView()
            }.hidden()

            Color.white.edgesIgnoringSafeArea(.all)

            if disclaimerGate.isPresented {
                GovDisclaimerPopupView(
                    onAcknowledge: disclaimerGate.acknowledge,
                    onDismiss: { presentationMode.wrappedValue.dismiss() }
                )
                .zIndex(30)
            }

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image("back_arrow")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }

                        Text("Marriage Reg. / \(location)")
                            .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)

                    HStack(spacing: 12) {
                        ServiceToggleChip(label: "Marriage Registration", isSelected: selectedService == "Marriage Registration") {
                            selectedService = "Marriage Registration"
                        }
                        ServiceToggleChip(label: "Court Marriage", isSelected: selectedService == "Court Marriage") {
                            selectedService = "Court Marriage"
                        }
                    }
                    .padding(.top, 18)
                    .padding(.bottom, 18)
                }
                .background(
                    Color(red: 0.10, green: 0.11, blue: 0.11)
                        .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                        .edgesIgnoringSafeArea(.top)
                )
                .zIndex(1)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {

                        HStack(spacing: 16) {
                            GovFeeMetricCard(icon: "ic_card_processing", label: "PROCESSING", value: viewModel.processing)
                            GovFeeMetricCard(icon: "ic_card_govt_fee", label: "GOVT. FEE", value: viewModel.govtFee)
                            GovFeeMetricCard(icon: "ic_card_service_fee", label: "ITZEAZY FEE", value: viewModel.itzeazyFee)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 28)

                        Button(action: {
                            guard authGate.requireAuth() else { return }
                            let url = marriageRegRedirectPath(city: location)
                            webLoginVM.generateToken(urlString: url, title: "Marriage Registration")
                        }) {
                            ZStack {
                                if webLoginVM.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("GET ASSISTANCE")
                                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 14))
                                        .foregroundColor(.white)
                                        .tracking(0.35)

                                    HStack {
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .bold))
                                            .padding(.trailing, 24)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.red)
                            .cornerRadius(16)
                            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(webLoginVM.isLoading)
                        .padding(.horizontal, 48)
                        .padding(.bottom, 24)

                        GovDisclaimerJustificationCard(
                            text: "Itzeazy fee covers document verification, form filling guidance, " +
                                "registration appointment booking, and doorstep support."
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))

                                Text("Required Documents")
                                    .font(Font.custom("PlusJakartaSans-Bold", size: 20))
                                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                            }
                            .padding(.bottom, 4)

                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.documents, id: \.self) { doc in
                                    HStack(alignment: .top, spacing: 12) {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 8)

                                        Text(doc)
                                            .font(Font.custom("Inter", size: 14))
                                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if showEntryDisclaimer { disclaimerGate.checkOnAppear() }
        }
        .onChange(of: webLoginVM.generatedURL) { _, url in
            if url != nil { showWebView = true }
        }
        .onChange(of: showWebView) { _, isActive in
            if !isActive { webLoginVM.reset() }
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

#Preview {
    MarriageRegDetailView(location: "Bangalore", service: "Marriage Registration")
}
