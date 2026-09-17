import SwiftUI

/// The playing screen: status bar, clue, grid, keyboard.
struct PuzzleView: View {
    @Environment(AppModel.self) private var app

    let engine: PuzzleEngine

    var body: some View {
        ZStack {
            Theme.background(tier: engine.level.tier)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                topBar

                CluePanelView(
                    level: engine.level,
                    entry: engine.selectedEntry,
                    solvedLetters: solvedLetterCount,
                    onSpeak: { app.speakCurrentClue() }
                )
                .padding(.horizontal, 16)

                grid

                Spacer(minLength: 0)

                KeyboardView(
                    letters: engine.keyboardLetters,
                    onTap: { app.type($0) },
                    onHint: { app.useHint() }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
            .padding(.top, 4)

            if let celebration = app.celebration {
                LevelCompleteView(celebration: celebration)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .zIndex(2)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: app.celebration)
    }

    // MARK: - Pieces

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                app.showMap()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(CircleIconButtonStyle())
            .accessibilityLabel("Back to the map")

            VStack(spacing: 5) {
                Text("Level \(engine.level.id)")
                    .font(Theme.font(19, .heavy))
                    .foregroundStyle(Theme.paper)

                ProgressBar(value: engine.completion)
                    .frame(height: 9)
            }

            Button {
                app.toggleMusic()
            } label: {
                Image(systemName: app.progress.musicEnabled ? "music.note" : "music.note.slash")
            }
            .buttonStyle(CircleIconButtonStyle())
            .accessibilityLabel(app.progress.musicEnabled ? "Turn the music off" : "Turn the music on")
        }
        .padding(.horizontal, 16)
    }

    private var grid: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 4
            let columns = CGFloat(engine.level.cols)
            let rows = CGFloat(engine.level.rows)
            let byWidth = (proxy.size.width - spacing * (columns - 1)) / columns
            let byHeight = (proxy.size.height - spacing * (rows - 1)) / rows
            // Cap the cell size so a two-word tier 1 puzzle does not end up with
            // comically huge squares on an iPad.
            let size = max(28, min(min(byWidth, byHeight), 74))

            GridView(
                engine: engine,
                cellSize: size,
                onTapCell: { app.tapCell($0) }
            )
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxHeight: gridMaxHeight)
        .padding(.horizontal, 16)
    }

    private var gridMaxHeight: CGFloat {
        // Roughly square, but never so tall that it crowds the keyboard.
        CGFloat(engine.level.rows) * 78
    }

    private var solvedLetterCount: Int {
        engine.selectedEntry.cells.filter { engine.letter(at: $0) != nil }.count
    }
}

/// The thin bar under the level number.
private struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.ink.opacity(0.18))
                Capsule()
                    .fill(Theme.sunshine)
                    .frame(width: max(0, min(1, value)) * proxy.size.width)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: value)
        .accessibilityLabel("Puzzle progress")
        .accessibilityValue("\(Int(value * 100)) percent")
    }
}
