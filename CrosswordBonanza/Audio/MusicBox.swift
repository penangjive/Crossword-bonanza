import Foundation

/// The looping background music.
///
/// The melody is written entirely in the C major pentatonic scale. That is a
/// deliberate safety net: no two notes of a pentatonic scale clash, so the loop
/// cannot come out sounding wrong however the steps line up against the bass.
/// It is quiet, slow, and has plenty of rests, because it plays for a long time
/// behind a child who is concentrating.
final class MusicBox {

    static let shared = MusicBox()

    /// MIDI notes; `nil` is a rest.
    private let melody: [Int?] = [
        72, nil, 76, 74, 72, nil, 69, nil,
        67, nil, 69, 72, 74, nil, nil, nil,
        76, nil, 79, 76, 74, nil, 72, nil,
        69, nil, 72, 69, 67, nil, nil, nil,
    ]

    /// One bass note per bar of four steps, walking around the same scale.
    private let bass: [Int] = [48, 55, 53, 52, 48, 55, 57, 55]

    private let stepDuration: Double = 0.34

    private var timer: Timer?
    private var step = 0

    private(set) var isPlaying = false

    private init() {}

    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        step = 0
        SynthAudioEngine.shared.start()

        let timer = Timer(timeInterval: stepDuration, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // .common keeps the music going while the player is scrolling the map.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }

    func setEnabled(_ enabled: Bool) {
        if enabled {
            start()
        } else {
            stop()
        }
    }

    private func tick() {
        let engine = SynthAudioEngine.shared

        if let note = melody[step % melody.count] {
            engine.play(
                midiNote: note,
                duration: stepDuration * 1.6,
                amplitude: 0.075,
                waveform: .sine
            )
        }

        if step % 4 == 0 {
            let note = bass[(step / 4) % bass.count]
            engine.play(
                midiNote: note,
                duration: stepDuration * 3.2,
                amplitude: 0.055,
                waveform: .triangle
            )
        }

        step = (step + 1) % (melody.count * 4)
    }
}
