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
                if service.title == "RTO Services" {
                    NavigationLink(destination: VehicleSearchResultsView()) {
                        ServiceCardView(service: service)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    ServiceCardView(service: service)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
}


