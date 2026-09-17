import SwiftUI

/// Colours, type and shapes for the whole game.
///
/// The palette is fixed rather than semantic (`.primary`, `.systemBackground`)
/// on purpose: every screen sits on one of our own coloured gradients, so dark
/// ink on light cards reads identically in light and dark mode, with no
/// half-legible in-between states. Type is SF Pro Rounded throughout -- Apple's
/// own playful register, so no font file ships with the app.
enum Theme {

    // MARK: - Palette

    static let sky = Color(red: 0.36, green: 0.71, blue: 0.98)
    static let deepSky = Color(red: 0.23, green: 0.48, blue: 0.90)
    static let grape = Color(red: 0.60, green: 0.45, blue: 0.93)
    static let deepGrape = Color(red: 0.43, green: 0.30, blue: 0.80)
    static let mint = Color(red: 0.30, green: 0.82, blue: 0.62)
    static let deepMint = Color(red: 0.16, green: 0.64, blue: 0.50)
    static let sunshine = Color(red: 1.00, green: 0.79, blue: 0.25)
    static let coral = Color(red: 0.97, green: 0.42, blue: 0.40)
    static let ink = Color(red: 0.15, green: 0.17, blue: 0.28)
    static let softInk = Color(red: 0.45, green: 0.48, blue: 0.60)
    static let paper = Color.white
    static let blank = Color.white.opacity(0.14)

    /// Each tier gets its own backdrop, so the child can see at a glance that
    /// the puzzles have changed character.
    static func background(tier: Int) -> LinearGradient {
        let colors: [Color]
        switch tier {
        case 1: colors = [sky, deepSky]
        case 2: colors = [grape, deepGrape]
        default: colors = [mint, deepMint]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    static var titleBackground: LinearGradient {
        LinearGradient(
            colors: [sky, grape, deepGrape],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Type

    static func font(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // MARK: - Shapes

    static let cellCorner: CGFloat = 9
    static let cardCorner: CGFloat = 26
    static let buttonCorner: CGFloat = 20

    /// The smallest tappable size anywhere in the app. Apple's guideline is
    /// 44pt; a five-year-old's aim is worse than an adult's, so nothing here
    /// goes below it and most things sit well above.
    static let minimumTouchTarget: CGFloat = 44
}

/// Side-to-side shake, used when a wrong letter bounces out of a cell.
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 9
    var shakes: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = travel * sin(animatableData * .pi * shakes)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

/// The big, friendly button style used for every primary action.
struct ChunkyButtonStyle: ButtonStyle {
    var tint: Color = Theme.sunshine
    var textColor: Color = Theme.ink
    var horizontalPadding: CGFloat = 32
    var verticalPadding: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(23, .heavy))
            .foregroundStyle(textColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: Theme.minimumTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: Theme.buttonCorner, style: .continuous)
                    .fill(tint)
                    .shadow(color: Theme.ink.opacity(0.25), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A small circular icon button (back, speaker, mute).
struct CircleIconButtonStyle: ButtonStyle {
    var diameter: CGFloat = Theme.minimumTouchTarget

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(diameter * 0.42, .bold))
            .foregroundStyle(Theme.ink)
            .frame(width: diameter, height: diameter)
            .background(
                Circle()
                    .fill(Theme.paper.opacity(0.92))
                    .shadow(color: Theme.ink.opacity(0.2), radius: 5, x: 0, y: 3)
            )
            .scaleEffect(configuration.isPressed ? 0.90 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// A row of stars, used on the map and the results screen.
struct StarRow: View {
    let earned: Int
    var size: CGFloat = 22
    var animated: Bool = false
    @State private var shown = 0

    var body: some View {
        HStack(spacing: size * 0.18) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < displayed ? "star.fill" : "star")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(index < displayed ? Theme.sunshine : Theme.softInk.opacity(0.45))
                    .scaleEffect(index < displayed ? 1 : 0.82)
                    .animation(.spring(response: 0.45, dampingFraction: 0.55), value: displayed)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(earned) out of 3 stars")
        .onAppear {
            guard animated else { return }
            for index in 0..<earned {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(index) * 0.32) {
                    shown = index + 1
                }
            }
        }
    }

    private var displayed: Int { animated ? shown : earned }
}
