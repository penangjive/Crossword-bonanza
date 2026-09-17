import SwiftUI

/// The start screen.
struct TitleView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var float = false

    private let title = Array("CROSSWORD")

    var body: some View {
        ZStack {
            Theme.titleBackground.ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer(minLength: 20)

                titleBlock

                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    Button(app.progress.totalStars > 0 ? "Keep playing" : "Play") {
                        app.playNext()
                    }
                    .buttonStyle(ChunkyButtonStyle(tint: Theme.sunshine))

                    Button("Choose a puzzle") {
                        app.showMap()
                    }
                    .buttonStyle(
                        ChunkyButtonStyle(tint: Theme.paper.opacity(0.9), textColor: Theme.ink)
                    )
                }

                if app.progress.totalStars > 0 {
                    HStack(spacing: 7) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Theme.sunshine)
                        Text("\(app.progress.totalStars) stars collected")
                            .font(Theme.font(17, .semibold))
                            .foregroundStyle(Theme.paper)
                    }
                }

                Spacer(minLength: 10)

                audioToggles
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 28)
        }
    }

    /// Each letter of the title bobs on its own delay, which gives the screen
    /// life without any assets or a particle system.
    private var titleBlock: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(title.indices, id: \.self) { index in
                    Text(String(title[index]))
                        .font(Theme.font(34, .black))
                        .foregroundStyle(Theme.paper)
                        .offset(y: float ? -7 : 7)
                        .animation(
                            reduceMotion
                                ? nil
                                : .easeInOut(duration: 1.3)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.07),
                            value: float
                        )
                }
            }

            Text("BONANZA")
                .font(Theme.font(46, .black))
                .foregroundStyle(Theme.sunshine)
                .shadow(color: Theme.ink.opacity(0.3), radius: 6, x: 0, y: 4)

            Text("Puzzles for brand new readers")
                .font(Theme.font(16, .semibold))
                .foregroundStyle(Theme.paper.opacity(0.9))
                .padding(.top, 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Crossword Bonanza. Puzzles for brand new readers.")
        .onAppear { float = true }
    }

    private var audioToggles: some View {
        HStack(spacing: 18) {
            Button {
                app.toggleMusic()
            } label: {
                Image(systemName: app.progress.musicEnabled ? "music.note" : "music.note.slash")
            }
            .buttonStyle(CircleIconButtonStyle(diameter: 54))
            .accessibilityLabel(app.progress.musicEnabled ? "Turn the music off" : "Turn the music on")

            Button {
                app.toggleSound()
            } label: {
                Image(systemName: app.progress.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
            .buttonStyle(CircleIconButtonStyle(diameter: 54))
            .accessibilityLabel(app.progress.soundEnabled ? "Turn the sounds off" : "Turn the sounds on")
        }
    }
}
