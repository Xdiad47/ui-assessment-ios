import SwiftUI

struct MyAddressView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = MyAddressViewModel()
    @State private var naturalHeight: CGFloat = 0

    private let backgroundColor = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        myAddressHeader

                        accountStrip
                            .padding(.horizontal, 16)

                        profileCard
                            .padding(.horizontal, 16)

                        addressesHeader
                            .padding(.horizontal, 16)

                        VStack(spacing: 12) {
                            ForEach(viewModel.addresses) { item in
                                AddressCardView(address: item, strokeColor: strokeColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
                    })
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
                    .background(backgroundColor)
                }
                .scrollDisabled(naturalHeight <= proxy.size.height)
                .onPreferenceChange(ContentHeightKey.self) { naturalHeight = $0 }
            }
        }
        .navigationBarHidden(true)
    }

    private var myAddressHeader: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(strokeColor)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            Color(red: 0.10, green: 0.11, blue: 0.11)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 12) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
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

    private var accountStrip: some View {
        HStack {
            Text(viewModel.pageTitle)
                .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                // Book Service action
            }) {
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
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
        .background(Color(red: 0.10, green: 0.11, blue: 0.11))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var profileCard: some View {
        HStack(spacing: 16) {
            Image("profile_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .background(Color(red: 0.93, green: 0.93, blue: 0.94))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.accountName)
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))

                Text(viewModel.accountEmail)
                    .font(Font.custom("Inter", size: 14).weight(.medium))
                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))

                Text(viewModel.accountPhone)
                    .font(Font.custom("Inter", size: 14).weight(.medium))
                    .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var addressesHeader: some View {
        HStack {
            Text(viewModel.addressesTitle)
                .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))

            Spacer()

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
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private struct ContentHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

private struct AddressCardView: View {
    let address: AddressItem
    let strokeColor: Color

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
                .background(Color(red: 0.10, green: 0.11, blue: 0.11))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(address.title)
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 14))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))

                Text("Phone Number : \(address.phoneNumber)")
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 14))
                    .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

//            Rectangle()
//                .fill(strokeColor.opacity(0.5))
//                .frame(height: 1)

            HStack(spacing: 0) {
                Button(action: {
                    // Edit action
                }) {
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

                Rectangle()
                    .fill(strokeColor)
                    .frame(width: 1, height: 28)

                Button(action: {
                    // Remove action
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Remove")
                            .font(Font.custom("Inter", size: 15).weight(.bold))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
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

#Preview {
    NavigationView {
        MyAddressView()
    }
}
