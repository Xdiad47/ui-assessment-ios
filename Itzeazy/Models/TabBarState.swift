import Foundation
import Combine

/// Shared state that publishes the measured height of the custom tab bar.
/// Injected at the root via .environmentObject() so any screen can read it
/// without hardcoding pixel values.
final class TabBarState: ObservableObject {
    @Published var height: CGFloat = 0
}
