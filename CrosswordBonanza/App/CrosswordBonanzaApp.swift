import SwiftUI

@main
struct CrosswordBonanzaApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                // The palette is designed as dark ink on light cards over our
                // own gradients, so the app looks the same either way. Pinning
                // it keeps a child from seeing two different-looking games.
                .preferredColorScheme(.light)
                // Clues and buttons are already large; letting them scale to
                // the accessibility sizes would break the grid layout.
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
    }
}
