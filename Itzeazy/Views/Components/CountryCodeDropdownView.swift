import SwiftUI

struct CountryCodeDropdownView: View {
    @Binding var selectedCountry: CountryInfo
    @Binding var isPresented: Bool
    let width: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(countries) { country in
                        Button {
                            selectedCountry = country
                            isPresented = false
                        } label: {
                            HStack(spacing: 12) {
                                Text(country.isoCode)
                                    .font(Font.custom("Inter", size: 14).weight(.semibold))
                                    .foregroundColor(Color(hex: "#191c1d"))
                                    .frame(width: 32, alignment: .leading)

                                Text(country.name)
                                    .font(Font.custom("Inter", size: 14))
                                    .foregroundColor(Color(hex: "#191c1d"))
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(country.phoneCode)
                                    .font(Font.custom("Inter", size: 14).weight(.medium))
                                    .foregroundColor(Color(hex: "#5f5e5e"))
                            }
                            .padding(.horizontal, 16)
                            .frame(width: width, height: 44, alignment: .leading)
                            .background(selectedCountry == country ? Color.red.opacity(0.08) : Color.white)
                        }
                        .buttonStyle(.plain)

                        Rectangle()
                            .fill(Color(hex: "#e1e3e4"))
                            .frame(width: width, height: 1)
                    }
                }
            }
        }
        .frame(width: width, height: 260)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "#b7b7b7"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 12)
    }
}
