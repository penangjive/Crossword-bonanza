import SwiftUI

/// The in-app letter keyboard. The system keyboard is never shown anywhere in
/// this app: its keys are too small for small fingers, it covers half the grid,
/// and the globe, emoji and dictation keys are all traps for a child.
///
/// Keys are in **alphabetical** order, not QWERTY. A six-year-old knows the
/// alphabet song; they do not know where Q is.
///
/// There is no delete key on purpose. Wrong letters never make it into the grid,
/// and a correct letter should never be taken back out.
///
/// Keys size themselves from the available width rather than a fixed point size,
/// so the row always fits: on the narrowest device iOS 17 supports that still
/// leaves keys comfortably above Apple's 44pt minimum.
struct KeyboardView: View {
    let letters: [Character]
    let onTap: (Character) -> Void
    let onHint: () -> Void

    /// Tier 1's cut-down keyboard is laid out narrower so its keys come out
    /// bigger still.
    private var columns: Int { letters.count <= 12 ? 5 : 7 }

    private let spacing: CGFloat = 8

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { column in
                        if column < rows[index].count {
                            LetterKey(letter: rows[index][column]) {
                                onTap(rows[index][column])
                            }
                        } else {
                            // Keeps a short last row aligned with the rows above
                            // instead of stretching its keys across the width.
                            Color.clear
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            HintButton(action: onHint)
                .padding(.top, 2)
        }
        // Without a cap the keys become comically large on an iPad.
        .frame(maxWidth: 460)
        .frame(maxWidth: .infinity)
    }

    private var rows: [[Character]] {
        stride(from: 0, to: letters.count, by: columns).map { start in
            Array(letters[start..<min(start + columns, letters.count)])
        }
    }
}

private struct LetterKey: View {
    let letter: Character
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(String(letter))
                .font(Theme.font(27, .heavy))
                .minimumScaleFactor(0.6)
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.paper)
                        .shadow(color: Theme.ink.opacity(0.22), radius: 4, x: 0, y: 3)
                )
        }
        .buttonStyle(KeyPressStyle())
        .accessibilityLabel("Letter \(String(letter))")
    }
}

private struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// Always enabled, never limited. A child who is stuck must always have a way
/// forward -- the cost of a hint is a star, never a dead end.
private struct HintButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Give me a letter", systemImage: "lightbulb.fill")
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .buttonStyle(
            ChunkyButtonStyle(
                tint: Theme.sunshine,
                horizontalPadding: 22,
                verticalPadding: 12
            )
        )
        .accessibilityHint("Fills in one letter of the word you are on")
    }
}
