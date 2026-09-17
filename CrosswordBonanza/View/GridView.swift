import SwiftUI

/// The crossword board.
struct GridView: View {
    let engine: PuzzleEngine
    let cellSize: CGFloat
    let onTapCell: (Cell) -> Void

    private var spacing: CGFloat { max(2, cellSize * 0.06) }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<engine.level.rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<engine.level.cols, id: \.self) { col in
                        let cell = Cell(row: row, col: col)
                        if engine.solution[cell] != nil {
                            CellView(
                                engine: engine,
                                cell: cell,
                                size: cellSize,
                                onTap: { onTapCell(cell) }
                            )
                        } else {
                            // Blocked square. Kept as a faint tile rather than a
                            // hole so the grid still reads as a single shape.
                            RoundedRectangle(cornerRadius: Theme.cellCorner, style: .continuous)
                                .fill(Theme.blank)
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Crossword grid")
    }
}

/// One square of the board.
///
/// Four things animate here, and they are the heart of how the game feels:
/// a correct letter pops in, a wrong letter appears in red and shakes itself
/// out, the selected word glows, and a finished word runs a wave down its
/// letters.
private struct CellView: View {
    let engine: PuzzleEngine
    let cell: Cell
    let size: CGFloat
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shake: CGFloat = 0
    @State private var rejected: Character?
    @State private var pop: CGFloat = 1
    @State private var waveLift: CGFloat = 0

    private var letter: Character? { engine.letter(at: cell) }
    private var number: Int? { engine.numbers[cell] }
    private var isCurrent: Bool { engine.currentCell == cell }
    private var isInSelectedWord: Bool { engine.selectedEntry.contains(cell) }
    private var isHinted: Bool { engine.hintedCells.contains(cell) }
    private var isRejecting: Bool { rejected != nil }

    /// How far down the celebrating word this cell sits, for the stagger.
    private var waveIndex: Int? {
        guard let id = engine.celebratingEntryID,
              let entry = engine.level.entries.first(where: { $0.id == id })
        else { return nil }
        return entry.index(of: cell)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cellCorner, style: .continuous)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cellCorner, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: isCurrent ? 3 : 1)
                )
                .shadow(color: Theme.ink.opacity(0.14), radius: 3, x: 0, y: 2)

            if let number {
                Text("\(number)")
                    .font(Theme.font(size * 0.22, .semibold))
                    .foregroundStyle(Theme.softInk)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, size * 0.09)
                    .padding(.top, size * 0.05)
                    .allowsHitTesting(false)
            }

            if let shown = rejected ?? letter {
                Text(String(shown))
                    .font(Theme.font(size * 0.56, .heavy))
                    .foregroundStyle(isRejecting ? Theme.coral : (isHinted ? Theme.softInk : Theme.ink))
                    .scaleEffect(pop)
                    .opacity(isRejecting ? 0.85 : 1)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .offset(y: waveLift)
        .modifier(ShakeEffect(animatableData: shake))
        .contentShape(RoundedRectangle(cornerRadius: Theme.cellCorner, style: .continuous))
        .onTapGesture(perform: onTap)
        .onChange(of: engine.wrongNonce) { _, _ in handleRejection() }
        .onChange(of: letter) { oldValue, newValue in handleFill(from: oldValue, to: newValue) }
        .onChange(of: engine.celebratingEntryID) { _, _ in handleWave() }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Appearance

    private var fillColor: Color {
        if isRejecting { return Theme.coral.opacity(0.22) }
        if isCurrent { return Theme.sunshine.opacity(0.55) }
        if isInSelectedWord { return Theme.sunshine.opacity(0.22) }
        return Theme.paper
    }

    private var borderColor: Color {
        if isRejecting { return Theme.coral }
        if isCurrent { return Theme.coral }
        return Theme.softInk.opacity(0.25)
    }

    private var accessibilityLabel: String {
        var parts: [String] = []
        if let number { parts.append("Square \(number)") }
        if let letter {
            parts.append("contains \(String(letter))")
        } else {
            parts.append("empty")
        }
        if isCurrent { parts.append("selected") }
        return parts.joined(separator: ", ")
    }

    // MARK: - Animation

    /// A wrong letter: show it in red, shake it, then let it fade away. Nothing
    /// is lost and nothing is counted -- the child just tries again.
    private func handleRejection() {
        guard engine.wrongCell == cell, let typed = engine.wrongLetter else { return }
        rejected = typed

        if !reduceMotion {
            withAnimation(.linear(duration: 0.38)) { shake += 1 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeOut(duration: 0.22)) {
                rejected = nil
            }
            if engine.wrongCell == cell {
                engine.clearWrongCell()
            }
        }
    }

    /// A correct letter: a quick overshoot and settle.
    private func handleFill(from oldValue: Character?, to newValue: Character?) {
        guard oldValue == nil, newValue != nil else { return }
        rejected = nil
        guard !reduceMotion else { return }
        pop = 0.45
        withAnimation(.spring(response: 0.34, dampingFraction: 0.5)) {
            pop = 1
        }
    }

    /// A finished word: each letter hops, one after the next along the word.
    private func handleWave() {
        guard let index = waveIndex, !reduceMotion else { return }
        let delay = Double(index) * 0.07
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.45)) {
                waveLift = -size * 0.22
            }
            withAnimation(.spring(response: 0.34, dampingFraction: 0.55).delay(0.16)) {
                waveLift = 0
            }
        }
    }
}
