import SwiftUI

struct FAQsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = FAQsViewModel()
    @State private var expandedFAQID: UUID?

    private let backgroundColor = Color(red: 0.96, green: 0.96, blue: 0.96)
    private let strokeColor = Color(red: 0.72, green: 0.72, blue: 0.72)

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .top) {
                Color(red: 0.10, green: 0.11, blue: 0.11).ignoresSafeArea(edges: .top)
                backgroundColor.ignoresSafeArea(edges: .bottom)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        header

                        titleStrip
                            .padding(.horizontal, 16)

                        questionsHeader
                            .padding(.horizontal, 16)

                        categoriesStrip
                            .padding(.horizontal, 16)

                        faqHeading
                            .padding(.horizontal, 24)

                        faqList
                            .padding(.horizontal, 20)
                            .padding(.bottom, 60)
                    }
                    .background(backgroundColor)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
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

                Text("FAQs")
                    .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
        }
    }

    private var titleStrip: some View {
        HStack {
            Text(viewModel.topTitle)
                .font(Font.custom("PlusJakartaSans-SemiBold", size: 16))
                .foregroundColor(.white)
                .lineLimit(2)

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

    private var questionsHeader: some View {
        HStack {
            Text(viewModel.sectionTitle)
                .font(Font.custom("PlusJakartaSans-Bold", size: 16))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
            Spacer()
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

    private var categoriesStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FAQCategory.allCases) { category in
                    Button(action: {
                        viewModel.selectedCategory = category
                        expandedFAQID = nil
                    }) {
                        Text(category.rawValue)
                            .font(Font.custom("Inter", size: 12).weight(viewModel.selectedCategory == category ? .bold : .medium))
                            .foregroundColor(viewModel.selectedCategory == category ? .white : Color(red: 0.37, green: 0.37, blue: 0.37))
                            .padding(.horizontal, 20)
                            .frame(height: 36)
                            .background(viewModel.selectedCategory == category ? Color.red : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(viewModel.selectedCategory == category ? Color.clear : Color(red: 0.91, green: 0.74, blue: 0.72), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(height: 46)
    }

    private var faqHeading: some View {
        HStack {
            Text(viewModel.headingTitle)
                .font(Font.custom("PlusJakartaSans-ExtraBold", size: 22))
                .foregroundColor(Color(red: 0.10, green: 0.11, blue: 0.11))
            Spacer()
        }
    }

    private var faqList: some View {
        VStack(spacing: 14) {
            ForEach(viewModel.filteredFAQs) { faq in
                FAQRow(
                    item: faq,
                    isExpanded: expandedFAQID == faq.id,
                    strokeColor: strokeColor,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            expandedFAQID = expandedFAQID == faq.id ? nil : faq.id
                        }
                    }
                )
            }
        }
    }
}

private struct FAQRow: View {
    let item: FAQItem
    let isExpanded: Bool
    let strokeColor: Color
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(alignment: .center) {
                    Text(item.question)
                        .font(Font.custom("Inter", size: 12).weight(.semibold))
                        .foregroundColor(isExpanded ? .red : Color(red: 0.10, green: 0.11, blue: 0.11))
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 10)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isExpanded ? .red : Color(red: 0.10, green: 0.11, blue: 0.11))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Rectangle()
                    .fill(strokeColor)
                    .frame(height: 1)

                Text(item.answer)
                    .font(Font.custom("Inter", size: 12))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 15)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationView {
        FAQsView()
    }
}
