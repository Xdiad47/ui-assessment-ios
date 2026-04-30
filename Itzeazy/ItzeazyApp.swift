import SwiftUI

@main
struct ItzeazyApp: App {
    init() {
        UIScrollView.appearance().keyboardDismissMode = .onDrag
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
