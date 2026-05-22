import SwiftUI

struct MyOrdersView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = MyOrdersViewModel()
    @State private var naturalHeight: CGFloat = 0

    private let backgroundColor = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        MyOrdersHeaderView(strokeColor: strokeColor) {
                            presentationMode.wrappedValue.dismiss()
                        }

                        welcomeCard
                            .padding(.horizontal, 16)

                        sectionHeaderCard
                            .padding(.horizontal, 16)

                        VStack(spacing: 16) {
                            ForEach(viewModel.orders) { order in
                                MyOrderCardView(order: order, strokeColor: strokeColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
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

    private struct ContentHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

    private var welcomeCard: some View {
        HStack {
            Text("Welcome, \(viewModel.welcomeName)")
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
        .frame(height: 58)
        .background(Color(red: 0.10, green: 0.11, blue: 0.11))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var sectionHeaderCard: some View {
        HStack {
            Text(viewModel.sectionTitle)
                .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct MyOrdersHeaderView: View {
    let strokeColor: Color
    let onBack: () -> Void

    var body: some View {
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
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                }

                Text("My Orders")
                    .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }
}

private struct MyOrderCardView: View {
    let order: OrderItem
    let strokeColor: Color

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.95, green: 0.96, blue: 0.96))
                        .frame(width: 64, height: 64)

                    Image(systemName: order.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.red)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(order.serviceName)
                            .font(Font.custom("PlusJakartaSans-Bold", size: 18))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))

                        Spacer()

                        Text(order.amountText)
                            .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                            .foregroundColor(.red)
                    }

                    Text("Order ID: \(order.orderId)")
                        .font(Font.custom("Inter", size: 12))
                        .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))

                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)

                        Text(order.statusText)
                            .font(Font.custom("Inter", size: 14).weight(.semibold))
                            .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
                    }

                    Text(order.placedOnText)
                        .font(Font.custom("Inter", size: 11))
                        .foregroundColor(Color(red: 0.37, green: 0.37, blue: 0.37))
                }
            }
            .padding(16)

            Button(action: {
                // Get order details action
            }) {
                HStack {
                    Text("Get Order Details")
                        .font(Font.custom("PlusJakartaSans-Bold", size: 14))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .frame(height: 52)
                .background(Color.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    NavigationView {
        MyOrdersView()
    }
}
