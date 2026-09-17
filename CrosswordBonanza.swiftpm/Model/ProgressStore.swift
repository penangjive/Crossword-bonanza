import Foundation
import Observation

/// Saved progress. Deliberately tiny: a star count per finished level plus two
/// audio switches, in UserDefaults. No account, no network, no analytics --
/// nothing about the child leaves the device.
@Observable
final class ProgressStore {

    private static let storageKey = "com.crosswordbonanza.progress.v1"

    private(set) var starsByLevel: [Int: Int] = [:]

    // Deliberately not `didSet` observers: the @Observable macro rewrites stored
    // properties into computed ones, so property observers on them are a trap.
    // Explicit setters keep the save in one obvious place.
    private(set) var musicEnabled: Bool = true
    private(set) var soundEnabled: Bool = true

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    // MARK: - Queries

    /// Level 1 is always open; every other level opens when the one before it
    /// has been finished.
    func isUnlocked(_ levelID: Int) -> Bool {
        levelID <= 1 || starsByLevel[levelID - 1] != nil
    }

    func isCompleted(_ levelID: Int) -> Bool {
        starsByLevel[levelID] != nil
    }

    func stars(for levelID: Int) -> Int {
        starsByLevel[levelID] ?? 0
    }

    var totalStars: Int {
        starsByLevel.values.reduce(0, +)
    }

    var maximumStars: Int {
        LevelLibrary.count * 3
    }

    /// The level the "Play" button should drop the child into: the first one
    /// they have not finished, or the last one if they have finished them all.
    var nextLevelID: Int {
        for level in LevelLibrary.levels where !isCompleted(level.id) {
            return level.id
        }
        return LevelLibrary.levels.last?.id ?? 1
    }

    var hasFinishedEverything: Bool {
        !LevelLibrary.levels.isEmpty && LevelLibrary.levels.allSatisfy { isCompleted($0.id) }
    }

    // MARK: - Mutation

    /// Replaying a level can raise its star count but never lower it, so a child
    /// can never lose a star they have already earned.
    func record(stars: Int, for levelID: Int) {
        let clamped = max(1, min(3, stars))
        if let existing = starsByLevel[levelID], existing >= clamped { return }
        starsByLevel[levelID] = clamped
        save()
    }

    func setMusicEnabled(_ enabled: Bool) {
        musicEnabled = enabled
        save()
    }

    func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
        save()
    }

    func resetEverything() {
        starsByLevel = [:]
        save()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var stars: [String: Int]
        var musicEnabled: Bool
        var soundEnabled: Bool
    }

    private func load() {
        guard let data = defaults.data(forKey: Self.storageKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return }

        var restored: [Int: Int] = [:]
        for (key, value) in snapshot.stars {
            if let id = Int(key) {
                restored[id] = value
            }
        }
        starsByLevel = restored
        musicEnabled = snapshot.musicEnabled
        soundEnabled = snapshot.soundEnabled
    }

    private func save() {
        var stars: [String: Int] = [:]
        for (id, value) in starsByLevel {
            stars[String(id)] = value
        }
        let snapshot = Snapshot(
            stars: stars,
            musicEnabled: musicEnabled,
            soundEnabled: soundEnabled
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
