import SwiftUI

/// The level ladder, drawn as a winding path climbing up the screen.
///
/// The path makes the progression physical: you can see how far you have come
/// and exactly which puzzle is open next. Locked levels stay visible rather than
/// hidden, because "the next one" is the thing that keeps a child playing.
struct LevelMapView: View {
    @Environment(AppModel.self) private var app

    private let nodeSpacing: CGFloat = 108
    private let nodeSize: CGFloat = 72
    private let topInset: CGFloat = 40

    var body: some View {
        ZStack {
            Theme.titleBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollViewReader { scroller in
                    ScrollView {
                        trail
                            .padding(.bottom, 48)
                    }
                    .onAppear {
                        // Drop the child at the level they are about to play.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                scroller.scrollTo(app.progress.nextLevelID, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                app.showTitle()
            } label: {
                Image(systemName: "house.fill")
            }
            .buttonStyle(CircleIconButtonStyle())
            .accessibilityLabel("Back to the start screen")

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Theme.sunshine)
                Text("\(app.progress.totalStars) / \(app.progress.maximumStars)")
                    .font(Theme.font(19, .heavy))
                    .foregroundStyle(Theme.paper)
            }
            .accessibilityLabel("\(app.progress.totalStars) stars out of \(app.progress.maximumStars)")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    // MARK: - The winding trail

    private var trail: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let levels = LevelLibrary.levels

            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    guard levels.count > 1 else { return }
                    var path = Path()
                    path.move(to: position(index: 0, width: width))
                    for index in 1..<levels.count {
                        path.addLine(to: position(index: index, width: width))
                    }
                    context.stroke(
                        path,
                        with: .color(Theme.paper.opacity(0.35)),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round, dash: [2, 18])
                    )
                }

                ForEach(levels) { level in
                    // Level ids run 1...n with no gaps -- Tools/validate_levels.py
                    // enforces that -- so the id doubles as the trail position.
                    let index = level.id - 1
                    LevelNode(
                        level: level,
                        stars: app.progress.stars(for: level.id),
                        isUnlocked: app.progress.isUnlocked(level.id),
                        isNext: level.id == app.progress.nextLevelID,
                        isNewlyUnlocked: level.id == app.newlyUnlockedLevelID,
                        size: nodeSize
                    ) {
                        app.play(levelID: level.id)
                    }
                    .id(level.id)
                    .position(position(index: index, width: width))
                }
            }
        }
        .frame(height: trailHeight)
    }

    private var trailHeight: CGFloat {
        topInset + CGFloat(max(1, LevelLibrary.count)) * nodeSpacing
    }

    /// Nodes weave left and right as they climb, which is far easier to follow
    /// than a straight column of 30 identical circles.
    private func position(index: Int, width: CGFloat) -> CGPoint {
        let weave = sin(Double(index) * 0.85)
        let amplitude = min(width * 0.27, 110)
        return CGPoint(
            x: width / 2 + CGFloat(weave) * amplitude,
            y: topInset + CGFloat(index) * nodeSpacing
        )
    }
}

/// One stop on the trail.
private struct LevelNode: View {
    let level: Level
    let stars: Int
    let isUnlocked: Bool
    let isNext: Bool
    let isNewlyUnlocked: Bool
    let size: CGFloat
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var beckon = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(fill)
                        .frame(width: size, height: size)
                        .shadow(color: Theme.ink.opacity(0.28), radius: 7, x: 0, y: 4)

                    Circle()
                        .strokeBorder(Theme.paper.opacity(isNext ? 0.95 : 0.4), lineWidth: isNext ? 4 : 2)
                        .frame(width: size, height: size)

                    if isUnlocked {
                        Text("\(level.id)")
                            .font(Theme.font(size * 0.42, .black))
                            .foregroundStyle(Theme.ink)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: size * 0.32, weight: .bold))
                            .foregroundStyle(Theme.paper.opacity(0.85))
                    }
                }
                .scaleEffect(beckon ? 1.07 : 1)

                if stars > 0 {
                    StarRow(earned: stars, size: 13)
                } else {
                    // Keeps every node the same height so the trail stays even.
                    Color.clear.frame(height: 13)
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear(perform: startBeckoning)
        .onChange(of: isNext) { _, _ in startBeckoning() }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var fill: Color {
        guard isUnlocked else { return Theme.ink.opacity(0.35) }
        if stars > 0 { return Theme.sunshine }
        return Theme.paper
    }

    /// The level you are up to breathes gently, so a child's eye lands on it
    /// without needing to read anything.
    private func startBeckoning() {
        guard (isNext || isNewlyUnlocked), !reduceMotion else {
            beckon = false
            return
        }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            beckon = true
        }
    }

    private var accessibilityLabel: String {
        guard isUnlocked else { return "Level \(level.id), locked" }
        let starText = stars > 0 ? ", \(stars) of 3 stars" : ", not finished yet"
        return "Level \(level.id), \(level.tierName)\(starText)"
    }
}
