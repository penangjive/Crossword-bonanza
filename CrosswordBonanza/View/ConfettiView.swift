import SwiftUI

/// Falling confetti, drawn in a single `Canvas` rather than as hundreds of
/// views, so it stays smooth on an old iPad. No image assets are involved.
///
/// It respects Reduce Motion: with that setting on, nothing is drawn at all.
struct ConfettiView: View {
    var pieceCount: Int = 90
    var duration: Double = 4.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    private struct Piece {
        let x: Double          // 0...1 across the width
        let delay: Double
        let fallSpeed: Double  // screen heights per second
        let drift: Double
        let wobble: Double
        let spin: Double
        let size: Double
        let color: Color
    }

    private let pieces: [Piece]

    init(pieceCount: Int = 90, duration: Double = 4.5) {
        self.pieceCount = pieceCount
        self.duration = duration

        let palette: [Color] = [
            Theme.sunshine, Theme.coral, Theme.mint,
            Theme.sky, Theme.grape, Color(red: 1.0, green: 0.55, blue: 0.75),
        ]
        // Seeded so the confetti pattern is identical on every launch; it is
        // decoration, and a stable pattern is easier to eyeball for bugs.
        var generator = SeededGenerator(seed: 0xC0FFEE)
        var built: [Piece] = []
        built.reserveCapacity(pieceCount)
        for index in 0..<pieceCount {
            built.append(
                Piece(
                    x: Double.random(in: 0...1, using: &generator),
                    delay: Double.random(in: 0...1.2, using: &generator),
                    fallSpeed: Double.random(in: 0.28...0.55, using: &generator),
                    drift: Double.random(in: -0.12...0.12, using: &generator),
                    wobble: Double.random(in: 0.6...2.2, using: &generator),
                    spin: Double.random(in: -3.4...3.4, using: &generator),
                    size: Double.random(in: 7...14, using: &generator),
                    color: palette[index % palette.count]
                )
            )
        }
        self.pieces = built
    }

    var body: some View {
        if reduceMotion {
            Color.clear
        } else {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSince(start)
                    for piece in pieces {
                        draw(piece, elapsed: elapsed, in: size, context: &context)
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { start = Date() }
        }
    }

    private func draw(
        _ piece: Piece,
        elapsed: Double,
        in size: CGSize,
        context: inout GraphicsContext
    ) {
        let t = elapsed - piece.delay
        guard t > 0, t < duration else { return }

        let progress = t * piece.fallSpeed
        guard progress < 1.2 else { return }

        let y = -0.1 + progress
        let x = piece.x + piece.drift * t + 0.02 * sin(t * piece.wobble * 2 * .pi)

        // Fade out over the last second so pieces don't vanish mid-air.
        let remaining = duration - t
        let opacity = remaining < 1 ? max(0, remaining) : 1

        let point = CGPoint(x: x * size.width, y: y * size.height)
        let width = piece.size
        let height = piece.size * 0.62

        context.drawLayer { layer in
            layer.translateBy(x: point.x, y: point.y)
            layer.rotate(by: .radians(t * piece.spin))
            layer.opacity = opacity
            let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
            layer.fill(
                Path(roundedRect: rect, cornerRadius: 2),
                with: .color(piece.color)
            )
        }
    }
}
