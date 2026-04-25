import SwiftUI

struct PopularSectionView: View {
    let items: [PopularItem]
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(items) { item in
                switch item.type {
                case .banner(let tag, let title, let subtitle, let buttonText, let backgroundImage):
                    BannerCardView(
                        tag: tag,
                        title: title,
                        subtitle: subtitle,
                        buttonText: buttonText,
                        backgroundImage: backgroundImage
                    )
                case .info(let title, let description, let price, let iconName):
                    InfoCardView(
                        title: title,
                        description: description,
                        price: price,
                        iconName: iconName
                    )
                }
            }
        }
        .padding(.bottom, 30)
    }
}

struct PopularSectionView_Previews: PreviewProvider {
    static var previews: some View {
        PopularSectionView(items: MockRepository.shared.getPopularItems())
            .previewLayout(.sizeThatFits)
            .background(Color(white: 0.95))
    }
}
