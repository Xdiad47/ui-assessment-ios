import SwiftUI

struct SectionHeaderView: View {
    let title: String
    var showViewAll: Bool = false
    var onViewAllTapped: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            if showViewAll {
                Button(action: {
                    onViewAllTapped?()
                }) {
                    Text("VIEW ALL")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct SectionHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SectionHeaderView(title: "Services", showViewAll: true)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
