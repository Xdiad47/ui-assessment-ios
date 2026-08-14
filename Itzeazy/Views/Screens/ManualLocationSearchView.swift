import SwiftUI
import MapKit

/// "Enter Location Manually" fallback for EV Charge when the user doesn't
/// want to grant device location. Free-text search with live autocomplete;
/// picking a suggestion resolves it to a coordinate and hands it back via
/// `onLocationSelected`.
struct ManualLocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ManualLocationSearchViewModel()
    @FocusState private var isSearchFocused: Bool

    let onLocationSelected: (CLLocationCoordinate2D) -> Void

    private let red = Color(hex: "#E61A20")

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    header(safeAreaTop: proxy.safeAreaInsets.top)

                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    content
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { isSearchFocused = true }
    }

    // MARK: - Header

    private func header(safeAreaTop: CGFloat) -> some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.72, green: 0.72, blue: 0.72))
                .frame(maxWidth: .infinity)
                .frame(height: safeAreaTop + 62)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                .padding(.horizontal, 1)

            Color(hex: "#191C1D")
                .frame(maxWidth: .infinity)
                .frame(height: safeAreaTop + 60)
                .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))

            HStack(spacing: 10) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                }

                Text("Enter Your Location")
                    .font(Font.custom("PlusJakartaSans-ExtraBold", size: 18))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .padding(.top, safeAreaTop)
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#8A8A8A"))

            TextField("", text: $viewModel.query, prompt: Text("Search for a city or area...")
                .foregroundColor(Color(hex: "#8A8A8A"))
                .font(Font.custom("Inter", size: 14))
            )
            .font(Font.custom("Inter", size: 14))
            .foregroundColor(Color(hex: "#0E0F11"))
            .focused($isSearchFocused)
            .autocorrectionDisabled()

            if !viewModel.query.isEmpty {
                Button(action: { viewModel.query = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(hex: "#B5B5B5"))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color(hex: "#F2F2F3"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "#E1E3E4"), lineWidth: 1)
        )
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isResolving {
            statusBlock(icon: nil, title: "Getting location…", showsSpinner: true)
        } else if let error = viewModel.errorMessage {
            statusBlock(icon: "mappin.slash", title: error)
        } else if viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty {
            statusBlock(icon: "location.magnifyingglass", title: "Start typing to search for your city or area.")
        } else if viewModel.suggestions.isEmpty {
            statusBlock(icon: "mappin.slash", title: "No matching places found.")
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.suggestions.enumerated()), id: \.offset) { _, suggestion in
                        Button {
                            isSearchFocused = false
                            viewModel.resolveCoordinate(for: suggestion) { coordinate in
                                onLocationSelected(coordinate)
                            }
                        } label: {
                            suggestionRow(suggestion)
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 56)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func statusBlock(icon: String?, title: String, showsSpinner: Bool = false) -> some View {
        VStack(spacing: 16) {
            if showsSpinner {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: red))
            } else if let icon {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "#B5B5B5"))
            }
            Text(title)
                .font(Font.custom("Inter", size: 14))
                .foregroundColor(Color(hex: "#6B6B6B"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.horizontal, 32)
    }

    private func suggestionRow(_ suggestion: MKLocalSearchCompletion) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(red.opacity(0.10))
                    .frame(width: 36, height: 36)
                Image(systemName: "mappin")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(red)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(Font.custom("PlusJakartaSans-Bold", size: 15))
                    .foregroundColor(Color(hex: "#0E0F11"))
                if !suggestion.subtitle.isEmpty {
                    Text(suggestion.subtitle)
                        .font(Font.custom("Inter", size: 12.5))
                        .foregroundColor(Color(hex: "#8A8A8A"))
                }
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    ManualLocationSearchView { _ in }
}
