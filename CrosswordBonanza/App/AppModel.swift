import Foundation
import Observation

/// The one object the whole app talks to.
///
/// It owns navigation, saved progress, and -- importantly -- every sound, spoken
/// clue and haptic. Funnelling feedback through here means the mute switches are
/// honoured in exactly one place instead of being checked in a dozen views.
@Observable
final class AppModel {

    enum Screen: Hashable {
        case title
        case map
        case puzzle(levelID: Int)
    }

    /// Shown over the puzzle when it is solved.
    struct Celebration: Identifiable, Equatable {
        let levelID: Int
        let stars: Int
        let hintsUsed: Bool
        let isFinalLevel: Bool
        var id: Int { levelID }
    }

    var screen: Screen = .title
    let progress: ProgressStore
    /// Non-nil exactly while a puzzle is on screen.
    private(set) var engine: PuzzleEngine?
    var celebration: Celebration?
    /// Bumped when a level is newly unlocked, so the map can animate to it.
    private(set) var newlyUnlockedLevelID: Int?

    init(progress: ProgressStore = ProgressStore()) {
        self.progress = progress
    }

    // MARK: - Lifecycle

    func appDidAppear() {
        Haptics.prepare()
        if progress.musicEnabled {
            MusicBox.shared.start()
        }
    }

    func appDidEnterBackground() {
        MusicBox.shared.stop()
        SpeechNarrator.shared.stop()
        SynthAudioEngine.shared.stop()
    }

    func appWillEnterForeground() {
        if progress.musicEnabled {
            MusicBox.shared.start()
        }
    }

    // MARK: - Navigation

    func showMap() {
        uiTap()
        SpeechNarrator.shared.stop()
        engine = nil
        celebration = nil
        screen = .map
    }

    func showTitle() {
        uiTap()
        SpeechNarrator.shared.stop()
        engine = nil
        celebration = nil
        screen = .title
    }

    /// Drops straight into the first unfinished level.
    func playNext() {
        play(levelID: progress.nextLevelID)
    }

    func play(levelID: Int) {
        guard let level = LevelLibrary.level(withID: levelID) else { return }
        guard progress.isUnlocked(levelID) else {
            if progress.soundEnabled { SoundEffects.locked() }
            Haptics.wrong()
            return
        }
        uiTap()
        newlyUnlockedLevelID = nil
        celebration = nil
        let engine = PuzzleEngine(level: level)
        self.engine = engine
        screen = .puzzle(levelID: levelID)
        // Give the child a moment to see the board before the first clue is read.
        speakCurrentClue(after: 0.6)
    }

    /// Called from the celebration overlay.
    func advanceAfterCelebration() {
        guard let celebration else { return }
        if let next = LevelLibrary.level(after: celebration.levelID),
           progress.isUnlocked(next.id) {
            play(levelID: next.id)
        } else {
            showMap()
        }
    }

    func replayCurrentLevel() {
        guard let levelID = engine?.level.id else { return }
        celebration = nil
        play(levelID: levelID)
    }

    func clearNewlyUnlocked() {
        newlyUnlockedLevelID = nil
    }

    // MARK: - Play

    func tapCell(_ cell: Cell) {
        guard let engine else { return }
        let previousEntry = engine.selectedEntry.id
        engine.select(cell: cell)
        if progress.soundEnabled { SoundEffects.uiTap() }
        Haptics.tap()
        // Moving to a different word means a different clue, so read it.
        if engine.selectedEntry.id != previousEntry {
            speakCurrentClue()
        }
    }

    func type(_ letter: Character) {
        guard let engine else { return }
        if progress.soundEnabled { SoundEffects.keyTap() }

        switch engine.type(letter) {
        case .correct(let completedEntry, let solvedPuzzle):
            handleCorrect(completedEntry: completedEntry, solvedPuzzle: solvedPuzzle)
        case .wrong:
            if progress.soundEnabled { SoundEffects.wrongLetter() }
            Haptics.wrong()
        case .ignored:
            break
        }
    }

    func useHint() {
        guard let engine else { return }
        if progress.soundEnabled { SoundEffects.hint() }
        Haptics.tap()
        switch engine.useHint() {
        case .correct(let completedEntry, let solvedPuzzle):
            handleCorrect(completedEntry: completedEntry, solvedPuzzle: solvedPuzzle, silent: true)
        case .wrong, .ignored:
            break
        }
    }

    private func handleCorrect(
        completedEntry: LevelEntry?,
        solvedPuzzle: Bool,
        silent: Bool = false
    ) {
        guard let engine else { return }

        if solvedPuzzle {
            if progress.soundEnabled { SoundEffects.levelComplete() }
            Haptics.success()
            finish(engine: engine)
            return
        }

        if let completedEntry {
            if progress.soundEnabled { SoundEffects.wordComplete() }
            Haptics.success()
            // Hearing the letters they just placed is the main reading payoff.
            SpeechNarrator.shared.spellThenSay(completedEntry.word)
            // Then move on to the clue for the word the cursor jumped to.
            speakCurrentClue(after: 2.2)
        } else {
            if !silent, progress.soundEnabled { SoundEffects.correctLetter() }
            Haptics.correct()
        }
    }

    private func finish(engine: PuzzleEngine) {
        let levelID = engine.level.id
        let stars = engine.stars
        let wasLocked = !progress.isUnlocked(levelID + 1)

        progress.record(stars: stars, for: levelID)
        if wasLocked, LevelLibrary.level(after: levelID) != nil {
            newlyUnlockedLevelID = levelID + 1
        }

        celebration = Celebration(
            levelID: levelID,
            stars: stars,
            hintsUsed: engine.hintsUsed > 0,
            isFinalLevel: LevelLibrary.level(after: levelID) == nil
        )
    }

    // MARK: - Voice

    func speakCurrentClue(after delay: Double = 0) {
        guard let engine else { return }
        let text = engine.selectedEntry.spoken
        guard delay > 0 else {
            SpeechNarrator.shared.say(text)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            // Don't talk over a screen the child has already left.
            guard let self, self.engine === engine, self.celebration == nil else { return }
            SpeechNarrator.shared.say(text)
        }
    }

    // MARK: - Settings

    func toggleMusic() {
        progress.setMusicEnabled(!progress.musicEnabled)
        MusicBox.shared.setEnabled(progress.musicEnabled)
        if progress.musicEnabled { uiTap() }
    }

    func toggleSound() {
        progress.setSoundEnabled(!progress.soundEnabled)
        if progress.soundEnabled { uiTap() }
    }

    private func uiTap() {
        if progress.soundEnabled { SoundEffects.uiTap() }
        Haptics.tap()
    }
}
