import SwiftUI

struct MyAddressView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var userSession: UserSessionViewModel
    @EnvironmentObject private var tabBarState: TabBarState
    @StateObject private var viewModel = MyAddressViewModel()
    @State private var naturalHeight: CGFloat = 0
    @State private var addressToDelete: UserAddress? = nil
    @State private var showDeleteConfirm = false
    @State private var navigateToAdd = false
    let onBackToHome: (() -> Void)?

    private let bgColor     = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)
    private let dark        = Color(red: 0.10, green: 0.11, blue: 0.11)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                dark.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        myAddressHeader

                        accountStrip
                            .padding(.horizontal, 16)

                        profileCard
                            .padding(.horizontal, 16)

                        addressesHeader
                            .padding(.horizontal, 16)

                        addressesSection
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24 + tabBarState.height)
                    }
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
                    })
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
                    .background(bgColor)
                }
                .scrollDisabled(naturalHeight <= proxy.size.height)
                .onPreferenceChange(ContentHeightKey.self) { naturalHeight = $0 }
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.fetchAddresses() }
        .confirmationDialog(
            "Delete Address",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let addr = addressToDelete {
                    viewModel.deleteAddress(id: addr.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove this address?")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Retry") { viewModel.fetchAddresses() }
            Button("Cancel", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Addresses Section

    @ViewBuilder
    private var addressesSection: some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
        } else if viewModel.addresses.isEmpty {
            Text("No addresses saved yet.\nTap \"Add New Address\" to get started.")
                .font(Font.custom("Inter", size: 14))
                .foregroundColor(Color(red: 0.50, green: 0.50, blue: 0.50))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
        } else {
            VStack(spacing: 12) {
                ForEach(viewModel.addresses) { address in
                    AddressCardView(
                        address: address,
                        strokeColor: strokeColor,
                        isDeleting: viewModel.deletingId == address.id,
                        onEdit: {
                            // navigated via NavigationLink inside the card
                        },
                        onDelete: {
                            addressToDelete = address
                            showDeleteConfirm = true
                        }
                    )
                }
            }
        }
    }

    // MARK: - Top Nav Bar

    private var myAddressHeader: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(strokeColor)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            dark
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 12) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                }

                Text("My Account")
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }

    // MARK: - Account Strip

    private var accountStrip: some View {
        HStack {
            Text(viewModel.pageTitle)
                .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                .foregroundColor(.white)

            Spacer()

            Button(action: { onBackToHome?() }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Book Service")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 12))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(Color.red)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(dark)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 16) {
            Image("profile_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .background(Color(red: 0.93, green: 0.93, blue: 0.94))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(userSession.displayFullName)
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(dark)

                Text(userSession.displayEmail)
                    .font(Font.custom("Inter", size: 14).weight(.medium))
                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))

                Text(userSession.displayPhone)
                    .font(Font.custom("Inter", size: 14).weight(.medium))
                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Addresses Header Row

    private var addressesHeader: some View {
        HStack {
            Text(viewModel.addressesTitle)
                .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                .foregroundColor(dark)

            Spacer()

            NavigationLink(destination: EditAddressView(mode: .create)) {
                HStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 17, height: 17)
                        Text("+")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("Add New Address")
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(strokeColor, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private struct ContentHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

// MARK: - Address Card

private struct AddressCardView: View {
    let address: UserAddress
    let strokeColor: Color
    let isDeleting: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    private let dark = Color(red: 0.10, green: 0.11, blue: 0.11)

    var body: some View {
        VStack(spacing: 0) {
            if address.isDefault {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("DEFAULT ADDRESS")
                        .font(Font.custom("Inter", size: 14).weight(.bold))
                        .foregroundColor(.white)
                        .tracking(0.8)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .frame(height: 52)
                .background(dark)
            }

            VStack(alignment: .leading, spacing: 4) {
                if !address.userName.isEmpty && address.userName != "string" {
                    Text(address.userName)
                        .font(Font.custom("PlusJakartaSans-Bold", size: 15))
                        .foregroundColor(dark)
                        .padding(.bottom, 2)
                }
                if !address.mobile.isEmpty && address.mobile != "string" {
                    AddressDetailRow(label: "Mobile", value: address.mobile)
                }
                if !address.flatHouse.isEmpty && address.flatHouse != "string" {
                    AddressDetailRow(label: "Flat/House", value: address.flatHouse)
                }
                if !address.area.isEmpty && address.area != "string" {
                    AddressDetailRow(label: "Area", value: address.area)
                }
                if !address.landmark.isEmpty && address.landmark != "string" {
                    AddressDetailRow(label: "Landmark", value: address.landmark)
                }
                let cityState = [address.city, address.state]
                    .filter { !$0.isEmpty && $0 != "string" }
                    .joined(separator: ", ")
                if !cityState.isEmpty {
                    AddressDetailRow(label: "City/State", value: cityState)
                }
                if address.pinCode > 0 {
                    AddressDetailRow(label: "Pin Code", value: "\(address.pinCode)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            HStack(spacing: 0) {
                NavigationLink(destination: EditAddressView(mode: .edit(id: address.id))) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Edit")
                            .font(Font.custom("Inter", size: 15).weight(.bold))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(strokeColor)
                    .frame(width: 1, height: 28)

                Button(action: onDelete) {
                    Group {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                .scaleEffect(0.8)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Remove")
                                    .font(Font.custom("Inter", size: 15).weight(.bold))
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .disabled(isDeleting)
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Address Detail Row

private struct AddressDetailRow: View {
    let label: String
    let value: String

    private let grey = Color(red: 0.50, green: 0.50, blue: 0.50)
    private let dark = Color(red: 0.10, green: 0.11, blue: 0.11)

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text("\(label):")
                .font(Font.custom("Inter", size: 13).weight(.semibold))
                .foregroundColor(grey)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(Font.custom("Inter", size: 13).weight(.medium))
                .foregroundColor(dark)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationView {
        MyAddressView(onBackToHome: nil)
    }
    .environmentObject(UserSessionViewModel())
    .environmentObject(TabBarState())
}
