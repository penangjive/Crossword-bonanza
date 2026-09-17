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
            if LevelLibrary.levels.isEmpty {
                // Without puzzle data every button is a no-op, which on a device
                // looks like the app is simply broken. Say so instead.
                NoLevelDataView()
            } else {
                gameFlow
            }
        }
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

    @ViewBuilder
    private var gameFlow: some View {
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

/// Shown when `levels.json` could not be found at all.
///
/// This is a build/packaging failure, not a gameplay state. Without it the app
/// launches to a title screen whose Play button silently does nothing, which is
/// indistinguishable from a hang. Naming the cause on screen turns a mystery
/// into a one-line bug report.
private struct NoLevelDataView: View {
    var body: some View {
        ZStack {
            Theme.titleBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Theme.paper)
                Text("No puzzles found")
                    .font(Theme.font(26, .heavy))
                    .foregroundStyle(Theme.paper)
                Text("levels.json did not make it into the app bundle, so there is nothing to play.")
                    .font(Theme.font(16, .semibold))
                    .foregroundStyle(Theme.paper.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 36)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
