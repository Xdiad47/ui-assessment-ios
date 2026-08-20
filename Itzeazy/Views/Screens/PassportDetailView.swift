import SwiftUI

struct PassportDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var authGate: AuthGateController
    @StateObject private var viewModel = PassportDetailViewModel()
    @StateObject private var webLoginVM = WebLoginViewModel()
    @StateObject private var disclaimerGate = GovDisclaimerGate(serviceKey: "passport")
    @State private var selectedService: String
    @State private var showWebView = false

    let location: String

    // True only when this screen is entered directly (e.g. the Home hero card's "Get
    // Started"), bypassing PassportInitialView's own disclaimer — the gate above uses the
    // same "passport" key so both entry paths share one daily counter.
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
                // ── Dark header + New/Renewal toggle ──────────────
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image("back_arrow")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }

                        Text("Passport / \(location)")
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
                        ServiceToggleChip(label: "New", isSelected: selectedService == "New Passport") {
                            selectedService = "New Passport"
                        }
                        ServiceToggleChip(label: "Renewal", isSelected: selectedService == "Passport Renewal") {
                            selectedService = "Passport Renewal"
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

                // ── Scrollable content ────────────────────────────
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {

                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .padding(.top, 32)
                                .padding(.bottom, 28)
                        } else {
                            // A pill only renders when the backend actually has a value for it.
                            HStack(spacing: 16) {
                                if !viewModel.processing.isEmpty {
                                    GovFeeMetricCard(icon: "ic_card_processing", label: "PROCESSING", value: viewModel.processing)
                                }
                                if !viewModel.govtFee.isEmpty {
                                    GovFeeMetricCard(icon: "ic_card_govt_fee", label: "GOVT. FEE", value: viewModel.govtFee)
                                }
                                if !viewModel.itzeazyFee.isEmpty {
                                    GovFeeMetricCard(icon: "ic_card_service_fee", label: "ITZEAZY FEE", value: viewModel.itzeazyFee)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 32)
                            .padding(.bottom, 28)
                        }

                        Button(action: {
                            guard authGate.requireAuth() else { return }
                            let url = "https://itzeazy.in/order/apply-pp"
                            webLoginVM.generateToken(urlString: url, title: "Passport")
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
                                "appointment booking assistance, and doorstep support."
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

                            if viewModel.documents.isEmpty && !viewModel.isLoading {
                                Text("No documents available for this service at the moment.")
                                    .font(Font.custom("Inter", size: 14))
                                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            } else {
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
        .onChange(of: selectedService) { _, newService in
            viewModel.loadDocuments(type: newService, city: location)
        }
        .task {
            viewModel.loadDocuments(type: selectedService, city: location)
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

// MARK: - Shared subviews (also used by Marriage/Birth/PAN detail screens)

struct ServiceToggleChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Font.custom(isSelected ? "PlusJakartaSans-Bold" : "PlusJakartaSans-SemiBold", size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 11)
                .background(isSelected ? Color.red : Color.clear)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct GovFeeMetricCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)

            Text(label)
                .font(Font.custom("Inter", size: 9).weight(.semibold))
                .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                .multilineTextAlignment(.center)
                .tracking(0.5)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .font(Font.custom("PlusJakartaSans-Bold", size: 11))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color.white, location: 0.0),
                    .init(color: Color(white: 0.60), location: 1.28)
                ],
                startPoint: .init(x: 0.5, y: 0.0),
                endPoint: .init(x: 0.5, y: 1.0)
            )
        )
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color(red: 0.72, green: 0.72, blue: 0.72), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
    }
}

#Preview {
    PassportDetailView(location: "Bangalore", service: "New Passport")
}
