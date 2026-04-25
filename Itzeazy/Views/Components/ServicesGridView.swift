import SwiftUI

struct ServicesGridView: View {
    let services: [ServiceItem]
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(services) { service in
                ServiceCardView(service: service)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
}

struct ServicesGridView_Previews: PreviewProvider {
    static var previews: some View {
        ServicesGridView(services: MockRepository.shared.getServices())
            .previewLayout(.sizeThatFits)
            .background(Color(white: 0.95))
    }
}
