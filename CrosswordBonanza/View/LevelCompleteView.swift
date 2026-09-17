import SwiftUI

/// The reward screen. It appears over the finished puzzle rather than replacing
/// it, so the child can still see the grid they just filled in.
struct LevelCompleteView: View {
    @Environment(AppModel.self) private var app

    let celebration: AppModel.Celebration

    @State private var cardScale: CGFloat = 0.7
    @State private var titleBounce = false

    var body: some View {
        ZStack {
            Theme.ink.opacity(0.42)
                .ignoresSafeArea()
                .onTapGesture { }  // swallow taps on the puzzle underneath

            ConfettiView()
                .ignoresSafeArea()

            card
                .scaleEffect(cardScale)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) {
                        cardScale = 1
                    }
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        titleBounce = true
                    }
                }
        }
    }

    private var card: some View {
        VStack(spacing: 18) {
            Text(headline)
                .font(Theme.font(34, .black))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .scaleEffect(titleBounce ? 1.04 : 1)

            StarRow(earned: celebration.stars, size: 46, animated: true)

            Text(subtitle)
                .font(Theme.font(17, .semibold))
                .foregroundStyle(Theme.softInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                if celebration.isFinalLevel {
                    Button("Back to the map") { app.showMap() }
                        .buttonStyle(ChunkyButtonStyle(tint: Theme.mint, textColor: .white))
                } else {
                    Button("Next puzzle") { app.advanceAfterCelebration() }
                        .buttonStyle(ChunkyButtonStyle(tint: Theme.mint, textColor: .white))
                }

                HStack(spacing: 12) {
                    Button {
                        app.replayCurrentLevel()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(CircleIconButtonStyle(diameter: 52))
                    .accessibilityLabel("Play this puzzle again")

                    Button {
                        app.showMap()
                    } label: {
                        Image(systemName: "map.fill")
                    }
                    .buttonStyle(CircleIconButtonStyle(diameter: 52))
                    .accessibilityLabel("Back to the map")
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 30)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .fill(Theme.paper)
                .shadow(color: Theme.ink.opacity(0.3), radius: 22, x: 0, y: 12)
        )
        .padding(.horizontal, 28)
    }

    private var headline: String {
        if celebration.isFinalLevel { return "You finished\nthe whole game!" }
        switch celebration.stars {
        case 3: return "Perfect!"
        case 2: return "Well done!"
        default: return "You did it!"
        }
    }

    /// The wording never scolds. Using hints is a choice, not a failure --
    /// the message just points at what three stars would take.
    private var subtitle: String {
        if celebration.isFinalLevel {
            return "Every puzzle solved. You are a crossword champion!"
        }
        if celebration.hintsUsed {
            return "Try it again without any hints to win all three stars."
        }
        return "Level \(celebration.levelID + 1) is unlocked!"
    }
}
