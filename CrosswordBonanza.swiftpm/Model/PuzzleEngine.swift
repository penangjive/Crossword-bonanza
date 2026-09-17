import Foundation
import Observation

/// All the state of one puzzle in progress.
///
/// Design rule that shapes this whole type: **there is no fail state.** A wrong
/// letter is never written into the grid. It bounces off, the cell shakes, and
/// play continues. So `filled` only ever holds correct letters, which also means
/// the puzzle is solved exactly when `filled.count == solution.count`.
@Observable
final class PuzzleEngine {

    let level: Level

    /// The answer key, cell by cell.
    let solution: [Cell: Character]
    /// Every cell that is part of some word, in reading order.
    let allCells: [Cell]
    /// Crossword numbering, on the cells that start a word.
    let numbers: [Cell: Int]
    /// Which letters the on-screen keyboard offers.
    let keyboardLetters: [Character]

    /// Correct letters the player has placed (or been given by a hint).
    private(set) var filled: [Cell: Character] = [:]
    /// Cells filled by a hint rather than by the player, drawn in a softer colour.
    private(set) var hintedCells: Set<Cell> = []
    private(set) var hintsUsed = 0

    private(set) var selectedEntryIndex: Int = 0
    private(set) var cursor: Int = 0

    private(set) var solvedEntryIDs: Set<String> = []
    private(set) var isSolved = false

    /// Animation triggers. The nonce changes on every rejection so that repeating
    /// the same wrong letter in the same cell still restarts the shake.
    private(set) var wrongCell: Cell?
    /// The letter that was just rejected, so the cell can show it for a beat
    /// before it shakes loose. Seeing what you typed is the whole feedback.
    private(set) var wrongLetter: Character?
    private(set) var wrongNonce = 0
    /// Set briefly when a word is completed, so the grid can run a letter wave.
    private(set) var celebratingEntryID: String?

    init(level: Level) {
        self.level = level

        var solution: [Cell: Character] = [:]
        for entry in level.entries {
            for (index, letter) in entry.letters.enumerated() {
                solution[entry.cell(at: index)] = letter
            }
        }
        self.solution = solution

        let ordered = solution.keys.sorted { lhs, rhs in
            lhs.row == rhs.row ? lhs.col < rhs.col : lhs.row < rhs.row
        }
        self.allCells = ordered

        // Standard crossword numbering: a cell is numbered when a word starts
        // there, counting in reading order.
        let starts = Set(level.entries.map(\.startCell))
        var numbers: [Cell: Int] = [:]
        var next = 1
        for cell in ordered where starts.contains(cell) {
            numbers[cell] = next
            next += 1
        }
        self.numbers = numbers

        self.keyboardLetters = Self.keyboard(for: level, solution: solution)

        selectFirstUnsolvedEntry()
    }

    // MARK: - Derived state

    var selectedEntry: LevelEntry {
        level.entries[selectedEntryIndex]
    }

    var currentCell: Cell {
        selectedEntry.cell(at: min(cursor, selectedEntry.length - 1))
    }

    /// 0...1, for the progress bar at the top of the puzzle screen.
    var completion: Double {
        guard !solution.isEmpty else { return 1 }
        return Double(filled.count) / Double(solution.count)
    }

    /// 3 stars for solving unaided, down to 1 for leaning on hints.
    var stars: Int {
        switch hintsUsed {
        case 0: return 3
        case 1...2: return 2
        default: return 1
        }
    }

    func letter(at cell: Cell) -> Character? { filled[cell] }

    func isSolved(_ entry: LevelEntry) -> Bool { solvedEntryIDs.contains(entry.id) }

    /// Entries crossing a cell, used for tap-to-toggle between across and down.
    func entryIndices(containing cell: Cell) -> [Int] {
        level.entries.indices.filter { level.entries[$0].contains(cell) }
    }

    // MARK: - Selection

    /// Tapping a cell moves the cursor there. Tapping the cell you are already
    /// on flips between the across and the down word through it -- the gesture
    /// every crossword app uses.
    func select(cell: Cell) {
        let candidates = entryIndices(containing: cell)
        guard !candidates.isEmpty else { return }

        if currentCell == cell, candidates.count > 1 {
            let position = candidates.firstIndex(of: selectedEntryIndex) ?? 0
            let next = candidates[(position + 1) % candidates.count]
            selectedEntryIndex = next
            cursor = level.entries[next].index(of: cell) ?? 0
            return
        }

        if let stillHere = candidates.first(where: { $0 == selectedEntryIndex }) {
            selectedEntryIndex = stillHere
        } else {
            // Prefer a word that still has blanks in it.
            selectedEntryIndex = candidates.first { !isSolved(level.entries[$0]) } ?? candidates[0]
        }
        cursor = selectedEntry.index(of: cell) ?? 0
    }

    func selectEntry(at index: Int) {
        guard level.entries.indices.contains(index) else { return }
        selectedEntryIndex = index
        cursor = firstBlankIndex(in: level.entries[index]) ?? 0
    }

    /// Moves to the next word that still has blanks, wrapping around.
    func selectNextEntry() {
        let total = level.entries.count
        guard total > 0 else { return }
        for step in 1...total {
            let candidate = (selectedEntryIndex + step) % total
            if !isSolved(level.entries[candidate]) {
                selectEntry(at: candidate)
                return
            }
        }
    }

    // MARK: - Play

    enum TypeResult {
        case correct(completedEntry: LevelEntry?, solvedPuzzle: Bool)
        case wrong
        case ignored
    }

    /// The only way a letter ever enters the grid.
    @discardableResult
    func type(_ letter: Character) -> TypeResult {
        guard !isSolved else { return .ignored }
        let cell = currentCell
        guard filled[cell] == nil else {
            // Cursor was parked on a solved cell; move along and try again.
            advanceCursor()
            return .ignored
        }

        guard solution[cell] == letter else {
            wrongCell = cell
            wrongLetter = letter
            wrongNonce &+= 1
            return .wrong
        }

        return .correct(
            completedEntry: place(letter, at: cell, viaHint: false),
            solvedPuzzle: isSolved
        )
    }

    /// Reveals one letter of the current word. Always available, never limited --
    /// a stuck child must always have a way forward.
    @discardableResult
    func useHint() -> TypeResult {
        guard !isSolved else { return .ignored }
        let target = firstBlankCell(in: selectedEntry)
            ?? allCells.first { filled[$0] == nil }
        guard let cell = target, let letter = solution[cell] else { return .ignored }

        hintsUsed += 1
        hintedCells.insert(cell)
        if let index = selectedEntry.index(of: cell) {
            cursor = index
        }
        return .correct(
            completedEntry: place(letter, at: cell, viaHint: true),
            solvedPuzzle: isSolved
        )
    }

    func clearWrongCell() {
        wrongCell = nil
        wrongLetter = nil
    }

    func clearCelebration() {
        celebratingEntryID = nil
    }

    // MARK: - Internals

    /// Writes a known-correct letter and updates everything that follows from it.
    private func place(_ letter: Character, at cell: Cell, viaHint: Bool) -> LevelEntry? {
        filled[cell] = letter
        wrongCell = nil
        wrongLetter = nil

        // A single letter can finish both an across and a down word at once;
        // report the one the player is looking at, and mark both solved.
        var completed: LevelEntry?
        for index in entryIndices(containing: cell) {
            let entry = level.entries[index]
            guard !solvedEntryIDs.contains(entry.id) else { continue }
            guard entry.cells.allSatisfy({ filled[$0] != nil }) else { continue }
            solvedEntryIDs.insert(entry.id)
            if completed == nil || index == selectedEntryIndex {
                completed = entry
            }
        }

        if filled.count == solution.count {
            isSolved = true
            celebratingEntryID = completed?.id
            return completed
        }

        if let completed {
            celebratingEntryID = completed.id
            // Only jump away if the word the player was working on is finished.
            if completed.id == selectedEntry.id {
                selectNextEntry()
            } else {
                advanceCursor()
            }
        } else {
            advanceCursor()
        }
        return completed
    }

    /// Moves the cursor to the next blank in the current word, or to the next
    /// unfinished word if this one is done.
    private func advanceCursor() {
        if let next = firstBlankIndex(in: selectedEntry, startingAt: cursor + 1) {
            cursor = next
        } else if let wrapped = firstBlankIndex(in: selectedEntry) {
            cursor = wrapped
        } else {
            selectNextEntry()
        }
    }

    private func firstBlankIndex(in entry: LevelEntry, startingAt start: Int = 0) -> Int? {
        guard start < entry.length else { return nil }
        return (start..<entry.length).first { filled[entry.cell(at: $0)] == nil }
    }

    private func firstBlankCell(in entry: LevelEntry) -> Cell? {
        firstBlankIndex(in: entry).map(entry.cell(at:))
    }

    private func selectFirstUnsolvedEntry() {
        selectedEntryIndex = 0
        cursor = 0
    }

    /// Tier 1 shows only the letters this puzzle needs plus two decoys, so a
    /// five-year-old scans about eight keys instead of twenty-six. Later tiers
    /// get the full alphabet.
    private static func keyboard(for level: Level, solution: [Cell: Character]) -> [Character] {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        guard level.usesReducedKeyboard else { return alphabet }

        let needed = Set(solution.values)
        var letters = needed
        // Seeded by level id so the keyboard is the same every time a child
        // replays a level -- muscle memory matters at this age.
        var generator = SeededGenerator(seed: UInt64(level.id) &* 2_654_435_761)
        let decoys = alphabet.filter { !needed.contains($0) }.shuffled(using: &generator)
        for decoy in decoys.prefix(2) {
            letters.insert(decoy)
        }
        return letters.sorted()
    }
}

/// Tiny deterministic PRNG so keyboard layouts are stable across launches.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
