import Foundation

/// Lightweight wrapper so a URL string works as an Identifiable item
/// (e.g. with .fullScreenCover(item:) or .sheet(item:)).
struct IdentifiableURL: Identifiable {
    let id  = UUID()
    let url: String
}
