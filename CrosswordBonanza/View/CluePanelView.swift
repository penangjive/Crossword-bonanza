import SwiftUI

/// The clue for the word the child is currently on.
///
/// This panel is where the difficulty ramp actually lives:
///   tier 1  a huge emoji and nothing to read
///   tier 2  a smaller emoji beside a short sentence
///   tier 3  the sentence alone
/// The speaker button never goes away, at any tier.
struct CluePanelView: View {
    let level: Level
    let entry: LevelEntry
    let solvedLetters: Int
    let onSpeak: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text(positionLabel)
                    .font(Theme.font(15, .heavy))
                    .foregroundStyle(Theme.softInk)

                Spacer(minLength: 8)

                progressDots
            }

            HStack(alignment: .center, spacing: 14) {
                if level.showsPictureClue {
                    Text(entry.emoji)
                        .font(.system(size: level.tier == 1 ? 82 : 44))
                        .scaleEffect(pulse ? 1.06 : 1)
                        .accessibilityHidden(true)
                }

                if level.showsTextClue {
                    Text(entry.clue)
                        .font(Theme.font(level.tier == 2 ? 21 : 23, .semibold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: onSpeak) {
                    Image(systemName: "speaker.wave.2.fill")
                }
                .buttonStyle(CircleIconButtonStyle(diameter: 52))
                .accessibilityLabel("Hear the clue")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .fill(Theme.paper)
                .shadow(color: Theme.ink.opacity(0.18), radius: 10, x: 0, y: 5)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: entry.id)
        .onAppear(perform: startPulse)
        .accessibilityElement(children: .combine)
    }

    /// How long the word is, and how much of it is already in. Reading this as
    /// dots rather than "3 of 5" keeps it usable before a child can count well.
    private var progressDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<entry.length, id: \.self) { index in
                Circle()
                    .fill(index < solvedLetters ? Theme.mint : Theme.softInk.opacity(0.25))
                    .frame(width: 9, height: 9)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: solvedLetters)
            }
        }
        .accessibilityLabel("\(solvedLetters) of \(entry.length) letters filled in")
    }

    private var positionLabel: String {
        entry.direction == .across ? "ACROSS" : "DOWN"
    }

    /// A slow breath on the picture, so a child who has stopped and stared knows
    /// the app is still alive and waiting for them.
    private func startPulse() {
        guard level.showsPictureClue, !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }
}
