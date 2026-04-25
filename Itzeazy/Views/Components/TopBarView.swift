import SwiftUI

struct TopBarView: View {
    var body: some View {
        HStack {
            Button(action: {
                // Menu action
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.gray)
            }
            
            Text("Itzeazy")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.red)
                .italic()
                .padding(.leading, 8)
            
            Spacer()
            
            Button(action: {
                // Location action
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle")
                        .foregroundColor(.red)
                    Text("New Delhi")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

struct TopBarView_Previews: PreviewProvider {
    static var previews: some View {
        TopBarView()
            .previewLayout(.sizeThatFits)
            .background(Color(white: 0.98))
    }
}
