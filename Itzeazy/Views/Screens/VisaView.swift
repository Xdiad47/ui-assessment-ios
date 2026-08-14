import SwiftUI

struct VisaView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var authGate: AuthGateController
    @StateObject private var viewModel: VisaViewModel
    @StateObject private var webLoginVM = WebLoginViewModel()
    @StateObject private var disclaimerGate = GovDisclaimerGate(serviceKey: "visa")

    // True only when this screen is entered directly (e.g. the Home hero card's "Get
    // Started"), bypassing VisaViewInitial's own disclaimer — the gate above uses the same
    // "visa" key so both entry paths share one daily counter.
    let showEntryDisclaimer: Bool

    init(selectedCountry: String = "Singapore", showEntryDisclaimer: Bool = false) {
        _viewModel = StateObject(wrappedValue: VisaViewModel(selectedCountry: selectedCountry))
        self.showEntryDisclaimer = showEntryDisclaimer
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(white: 0.98).edgesIgnoringSafeArea(.all)

            NavigationLink(
                destination: CitizenServicesWebView(
                    url: webLoginVM.generatedURL ?? "",
                    title: viewModel.selectedCountry,
                    showGovDisclaimer: true
                ),
                isActive: Binding(
                    get: { webLoginVM.generatedURL != nil },
                    set: { if !$0 { webLoginVM.reset() } }
                )
            ) { EmptyView() }
            .hidden()

            if disclaimerGate.isPresented {
                GovDisclaimerPopupView(
                    onAcknowledge: disclaimerGate.acknowledge,
                    onDismiss: { presentationMode.wrappedValue.dismiss() }
                )
                .zIndex(30)
            }

            VStack(spacing: 0) {
                // ── Dark Header Section ───────────
                VStack(spacing: 0) {
                    
                    // Header matching other screens
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
                            HStack(spacing: 12) {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image("back_arrow")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                }
                                
                                // Flag and Title
                                HStack(spacing: 8) {
                                    Text(viewModel.countryFlag)
                                        .font(.system(size: 20))
                                    Text(viewModel.selectedCountry)
                                        .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                                        .foregroundColor(.white)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 60)
                    }
                    
                    // Tabs
                    HStack(spacing: 12) {
                        ForEach(VisaCategory.allCases, id: \.self) { category in
                            Button(action: {
                                withAnimation {
                                    viewModel.selectedCategory = category
                                }
                            }) {
                                Text(category.rawValue)
                                    .font(Font.custom("Inter", size: 14))
                                    .foregroundColor(viewModel.selectedCategory == category ? .white : Color.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(
                                        Group {
                                            if viewModel.selectedCategory == category {
                                                Color.red
                                            } else {
                                                Color.clear
                                            }
                                        }
                                    )
                                    .cornerRadius(18)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(viewModel.selectedCategory == category ? Color.clear : Color.white, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                    
                }
                .background(
                    Color(red: 0.10, green: 0.11, blue: 0.11)
                        .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                        .edgesIgnoringSafeArea(.top)
                )
                .zIndex(1)
                
                // ── Content Area ───────────
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        // 3 Metrics cards
                        HStack(spacing: 12) {
                            MetricCardView(
                                icon: "clock", 
                                title: "PROCESSING", 
                                value: viewModel.processingTime,
                                subtitle: ""
                            )
                            
                            MetricCardView(
                                icon: "creditcard",
                                title: "VISA FEE",
                                value: viewModel.visaFee,
                                subtitle: ""
                            )
                            
                            MetricCardView(
                                icon: "person.crop.circle.badge.checkmark",
                                title: "VISIT REQUIRED",
                                value: viewModel.visitRequired,
                                subtitle: ""
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // Apply Now Button
                        Button(action: {
                            guard authGate.requireAuth() else { return }
                            guard let encodedCountry = viewModel.selectedCountry.addingPercentEncoding(
                                withAllowedCharacters: .urlPathAllowed
                            ) else { return }
                            let url = "https://itzeazy.in/order/visa/\(encodedCountry)"
                            webLoginVM.generateToken(urlString: url, title: viewModel.selectedCountry)
                        }) {
                            ZStack {
                                if webLoginVM.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("GET ASSISTANCE")
                                        .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                                        .foregroundColor(.white)

                                    HStack {
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .foregroundColor(.white)
                                            .font(.system(size: 18, weight: .bold))
                                            .padding(.trailing, 24)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .disabled(webLoginVM.isLoading)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                        GovDisclaimerJustificationCard(
                            text: "Itzeazy fee covers document verification, form filling guidance, " +
                                "appointment booking assistance, and doorstep support."
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Required Documents List
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                                Text("Required Documents")
                                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                            }
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            } else if let documentsMessage = viewModel.documentsMessage {
                                Text(documentsMessage)
                                    .font(Font.custom("Inter", size: 14))
                                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(viewModel.requiredDocuments) { doc in
                                        HStack(alignment: .top, spacing: 12) {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 6, height: 6)
                                                .offset(y: 8)

                                            Text(doc.name)
                                                .font(Font.custom("Inter", size: 14))
                                                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                                                .lineSpacing(4)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 80)
                        
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if showEntryDisclaimer { disclaimerGate.checkOnAppear() }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { webLoginVM.errorMessage != nil },
            set: { if !$0 { webLoginVM.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(webLoginVM.errorMessage ?? "")
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Retry") { viewModel.fetchRequiredDocuments() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Subviews

struct MetricCardView: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.red)
                .padding(.bottom, 4)
            
            Text(title)
                .font(Font.custom("Inter", size: 10).weight(.semibold))
                .foregroundColor(Color(white: 0.4))
            
            if !value.isEmpty {
                Text(value)
                    .font(Font.custom("PlusJakartaSans-Bold", size: 12))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
            }
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(Font.custom("Inter", size: 10))
                    .foregroundColor(Color(white: 0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.94, green: 0.94, blue: 0.94),
                            Color(red: 0.85, green: 0.85, blue: 0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VisaView()
}
