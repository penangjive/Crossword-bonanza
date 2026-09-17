import Foundation

/// A square on the board, addressed row-then-column from the top left.
struct Cell: Hashable {
    let row: Int
    let col: Int
}

enum Direction: String, Codable, Hashable {
    case across
    case down
}

/// One word in a puzzle, exactly as it appears in `levels.json`.
struct LevelEntry: Codable, Hashable, Identifiable {
    let word: String
    let row: Int
    let col: Int
    let direction: Direction
    /// Picture clue. Shown large in tier 1, as a small badge in tier 2.
    let emoji: String
    /// Text clue. Shown from tier 2 onward.
    let clue: String
    /// What the narrator says out loud. Tier 1 simply names the picture;
    /// later tiers read the clue, because by then the child is reading.
    let spoken: String

    var id: String { "\(row)-\(col)-\(direction.rawValue)" }

    var letters: [Character] { Array(word) }

    var length: Int { word.count }

    var startCell: Cell { Cell(row: row, col: col) }

    func cell(at index: Int) -> Cell {
        direction == .across ? Cell(row: row, col: col + index) : Cell(row: row + index, col: col)
    }

    var cells: [Cell] { (0..<length).map(cell(at:)) }

    func index(of cell: Cell) -> Int? {
        switch direction {
        case .across:
            guard cell.row == row, (col..<(col + length)).contains(cell.col) else { return nil }
            return cell.col - col
        case .down:
            guard cell.col == col, (row..<(row + length)).contains(cell.row) else { return nil }
            return cell.row - row
        }
    }

    func contains(_ cell: Cell) -> Bool { index(of: cell) != nil }
}

/// One puzzle. `rows` and `cols` are already cropped to the letters, so there
/// are never empty edge rows to waste screen space.
struct Level: Codable, Identifiable, Hashable {
    let id: Int
    let tier: Int
    let rows: Int
    let cols: Int
    let entries: [LevelEntry]

    /// How the clue is presented, which is the whole difficulty ramp.
    var showsPictureClue: Bool { tier <= 2 }
    var showsTextClue: Bool { tier >= 2 }
    /// Tier 1 players get a cut-down keyboard so there is far less to scan.
    var usesReducedKeyboard: Bool { tier == 1 }

    var tierName: String {
        switch tier {
        case 1: return "Picture Puzzles"
        case 2: return "Word Builders"
        default: return "Real Crosswords"
        }
    }
}

struct LevelPack: Codable {
    let version: Int
    let levels: [Level]
}

/// Loads `levels.json` out of the app bundle once, at first use.
enum LevelLibrary {
    static let levels: [Level] = loadLevels()

    static var count: Int { levels.count }

    static func level(withID id: Int) -> Level? {
        levels.first { $0.id == id }
    }

    /// The level after `id`, or nil when the player has finished the game.
    static func level(after id: Int) -> Level? {
        level(withID: id + 1)
    }

    private static func loadLevels() -> [Level] {
        guard let url = Bundle.main.url(forResource: "levels", withExtension: "json") else {
            assertionFailure("levels.json is not in the app bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let pack = try JSONDecoder().decode(LevelPack.self, from: data)
            return pack.levels.sorted { $0.id < $1.id }
        } catch {
            assertionFailure("levels.json could not be decoded: \(error)")
            return []
        }
    }
}
