import AVFoundation
import Foundation

/// Reads clues out loud.
///
/// This is not a decoration -- it is the feature that lets a five-year-old who
/// cannot yet read a clue play the game at all. Speech is slowed and pitched up
/// slightly, which tests far better with young children than the default voice.
final class SpeechNarrator {

    static let shared = SpeechNarrator()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    func say(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        stop()

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.88
        utterance.pitchMultiplier = 1.08
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0.1
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        synthesizer.speak(utterance)
    }

    /// Spells a word out letter by letter, then says it whole. Used when a word
    /// is completed, so the child hears the letters they just placed.
    func spellThenSay(_ word: String) {
        let spaced = word.map(String.init).joined(separator: ", ")
        say("\(spaced). \(word.capitalized)")
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
