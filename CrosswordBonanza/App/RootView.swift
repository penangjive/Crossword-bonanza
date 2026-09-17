import SwiftUI

/// Routes between the three screens.
///
/// A game is one of the few places a custom full-screen flow beats a
/// `NavigationStack`: there is no back-button chrome to inherit and every
/// transition should feel like part of the game rather than part of iOS.
struct RootView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            switch app.screen {
            case .title:
                TitleView()
                    .transition(.opacity)

            case .map:
                LevelMapView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))

            case .puzzle:
                if let engine = app.engine {
                    PuzzleView(engine: engine)
                        .id(engine.level.id)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.94).combined(with: .opacity),
                            removal: .opacity
                        ))
                } else {
                    // Only reachable if a level id went missing from the bundle.
                    MissingLevelView()
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: app.screen)
        .onAppear { app.appDidAppear() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background, .inactive:
                app.appDidEnterBackground()
            case .active:
                app.appWillEnterForeground()
            @unknown default:
                break
            }
        }
    }
}

/// Shown only if `levels.json` failed to load, so the app degrades into an
/// explanation instead of a blank screen.
private struct MissingLevelView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ZStack {
            Theme.titleBackground.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "questionmark.square.dashed")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(Theme.paper)
                Text("That puzzle is missing")
                    .font(Theme.font(24, .heavy))
                    .foregroundStyle(Theme.paper)
                Button("Back to the map") { app.showMap() }
                    .buttonStyle(ChunkyButtonStyle(tint: Theme.sunshine))
            }
        }
    }
}
