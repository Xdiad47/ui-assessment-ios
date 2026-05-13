import SwiftUI

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
                    .background(Color.white) // Entire scrollable area gets white bg, sitting behind dark header's corners
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
    }
}

// MARK: - Subviews

struct HomeHeaderView: View {
    var body: some View {
        ZStack(alignment: .top) {
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

                Text("Home")
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
}

struct HomeHeroCardView: View {
    @State private var location = ""
    @State private var service = ""
    @State private var type = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Citizen services at doorstep")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Location - Full Width
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.gray)
                    TextField("Choose location", text: $location)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                
                // Service & Type - Side by Side
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.gray)
                        TextField("Service", text: $service)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    HStack {
                        Image(systemName: "doc.plaintext")
                            .foregroundColor(.gray)
                        TextField("Type", text: $type)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
            
            Button(action: {
                // Get Started action
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.85, green: 0.2, blue: 0.2)) // Red action button
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}

struct HomeServicesGridView: View {
    let services = [
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
    
    // 5 Columns as per Figma
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Services We Provide")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Rectangle()
                    .fill(Color(red: 0.85, green: 0.2, blue: 0.2))
                    .frame(width: 203, height: 3)
            }
            .padding(.horizontal,16)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(services, id: \.0) { service in
                    if service.0.contains("RTO") {
                        NavigationLink(destination: RTOServicesView()) {
                            ServiceBoxView(title: service.0, iconName: service.1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        ServiceBoxView(title: service.0, iconName: service.1)
                    }
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
    }
}

struct HomeUtilitiesGridView: View {
    let utilities = [
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
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Utilities")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Rectangle()
                    .fill(Color(red: 0.85, green: 0.2, blue: 0.2))
                    .frame(width: 80, height: 3)
            }
            .padding(.horizontal,16)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(utilities, id: \.0) { utility in
                    if utility.0 == "Vehicle\nInfo" {
                        NavigationLink(destination: VehicleSearchResultsView()) {
                            ServiceBoxView(title: utility.0, iconName: utility.1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else if utility.0.contains("Challan") {
                        NavigationLink(destination: ChallanDetailsView()) {
                            ServiceBoxView(title: utility.0, iconName: utility.1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else if utility.0 == "DL Info" {
                        NavigationLink(destination: DLInfoView()) {
                            ServiceBoxView(title: utility.0, iconName: utility.1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        ServiceBoxView(title: utility.0, iconName: utility.1)
                    }
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
