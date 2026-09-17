import Foundation

/// Every game sound, synthesised on the spot.
///
/// The tuning rule throughout: rewards are bright, high and rising; the
/// wrong-letter sound is low, short and soft. It must read as "not that one,
/// try again", never as a buzzer. Nothing here is loud enough to startle.
enum SoundEffects {

    private static var engine: SynthAudioEngine { .shared }

    /// A soft click as a key goes down.
    static func keyTap() {
        engine.play(frequency: 880, duration: 0.05, amplitude: 0.07, waveform: .sine)
    }

    /// A correct letter lands: a quick bright two-note lift.
    static func correctLetter() {
        engine.play(midiNote: 79, duration: 0.10, amplitude: 0.16)
        engine.play(midiNote: 84, duration: 0.14, amplitude: 0.13, delay: 0.055)
    }

    /// A wrong letter bounces off. Low, gentle, over almost before it starts.
    static func wrongLetter() {
        engine.play(frequency: 146.8, duration: 0.16, amplitude: 0.13, waveform: .triangle)
    }

    /// A whole word finished: a rising arpeggio that lands an octave up.
    static func wordComplete() {
        let notes = [72, 76, 79, 84]
        for (index, note) in notes.enumerated() {
            engine.play(
                midiNote: note,
                duration: 0.20,
                amplitude: 0.15,
                delay: Double(index) * 0.075
            )
        }
    }

    /// A hint being spent: a little sparkle, not a penalty noise.
    static func hint() {
        engine.play(midiNote: 88, duration: 0.09, amplitude: 0.11)
        engine.play(midiNote: 91, duration: 0.12, amplitude: 0.09, delay: 0.06)
    }

    /// The whole puzzle solved.
    static func levelComplete() {
        let fanfare = [72, 76, 79, 84, 88]
        for (index, note) in fanfare.enumerated() {
            engine.play(
                midiNote: note,
                duration: 0.26,
                amplitude: 0.17,
                delay: Double(index) * 0.09
            )
        }
        // A sustained chord underneath the run, so it ends on something warm.
        for note in [60, 64, 67, 72] {
            engine.play(
                midiNote: note,
                duration: 1.1,
                amplitude: 0.10,
                waveform: .triangle,
                delay: 0.45
            )
        }
    }

    /// A star popping onto the results screen.
    static func star(_ index: Int) {
        let notes = [76, 79, 84]
        engine.play(
            midiNote: notes[min(index, notes.count - 1)],
            duration: 0.22,
            amplitude: 0.15
        )
    }

    /// Moving between screens.
    static func uiTap() {
        engine.play(midiNote: 74, duration: 0.07, amplitude: 0.09)
    }

    /// A locked level being tapped: a polite "not yet".
    static func locked() {
        engine.play(frequency: 196, duration: 0.12, amplitude: 0.09, waveform: .triangle)
    }
}
