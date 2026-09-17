import AVFoundation
import Foundation
import os

/// A tiny software synthesiser.
///
/// The game ships with no audio files at all -- every sound, from the background
/// music to the win fanfare, is generated sample by sample here. That keeps the
/// repository free of licensed media, keeps the app small, and means the sound
/// design lives in code where it can be tuned.
///
/// The render block runs on the real-time audio thread. Everything it touches is
/// guarded by an `os_unfair_lock` and does no allocation beyond the occasional
/// array compaction, which is acceptable at this voice count.
final class SynthAudioEngine {

    static let shared = SynthAudioEngine()

    enum Waveform {
        case sine
        case triangle
    }

    /// One sounding note with a linear attack/release envelope.
    private struct Voice {
        var phase: Double
        var phaseIncrement: Double
        var amplitude: Double
        var waveform: Waveform
        var elapsed: Int
        var attackSamples: Int
        var releaseSamples: Int
        var totalSamples: Int

        var isFinished: Bool { elapsed >= totalSamples }

        mutating func nextSample() -> Double {
            guard !isFinished else { return 0 }

            let raw: Double
            switch waveform {
            case .sine:
                raw = sin(phase)
            case .triangle:
                let turn = phase / (2 * .pi)
                raw = 4 * abs(turn - 0.5) - 1
            }

            let envelope: Double
            if elapsed < attackSamples {
                envelope = Double(elapsed) / Double(max(1, attackSamples))
            } else if elapsed > totalSamples - releaseSamples {
                envelope = Double(totalSamples - elapsed) / Double(max(1, releaseSamples))
            } else {
                envelope = 1
            }

            phase += phaseIncrement
            if phase > 2 * .pi {
                phase -= 2 * .pi
            }
            elapsed += 1
            return raw * envelope * amplitude
        }
    }

    private let sampleRate: Double = 44_100
    private let maximumVoices = 24
    /// Headroom so several simultaneous voices cannot clip.
    private let masterGain: Double = 0.55

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var voices: [Voice] = []
    private var isRunning = false

    private let lock: UnsafeMutablePointer<os_unfair_lock> = {
        let pointer = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        pointer.initialize(to: os_unfair_lock())
        return pointer
    }()

    private init() {
        configureSession()
        buildGraph()
        observeInterruptions()
    }

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            isRunning = true
        } catch {
            // Audio is a nice-to-have, never a reason to break the game.
            isRunning = false
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.pause()
        stopAllVoices()
        isRunning = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func stopAllVoices() {
        os_unfair_lock_lock(lock)
        voices.removeAll()
        os_unfair_lock_unlock(lock)
    }

    /// `.ambient` is the right category for a children's game: the hardware mute
    /// switch silences it, and it never interrupts music the family already has
    /// playing.
    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
    }

    private func buildGraph() {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 2,
            interleaved: false
        ) else { return }

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let self else {
                for buffer in buffers {
                    if let data = buffer.mData {
                        memset(data, 0, Int(buffer.mDataByteSize))
                    }
                }
                return noErr
            }
            self.render(frameCount: Int(frameCount), into: buffers)
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1
        sourceNode = node
    }

    private func observeInterruptions() {
        let center = NotificationCenter.default
        _ = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw)
            else { return }
            switch type {
            case .began:
                self.stopAllVoices()
                self.isRunning = false
            case .ended:
                self.start()
            @unknown default:
                break
            }
        }

        _ = center.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.isRunning = false
            self.configureSession()
            self.start()
        }
    }

    // MARK: - Rendering

    private func render(frameCount: Int, into buffers: UnsafeMutableAudioBufferListPointer) {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }

        for frame in 0..<frameCount {
            var mixed = 0.0
            for index in voices.indices {
                mixed += voices[index].nextSample()
            }
            mixed = max(-1, min(1, mixed * masterGain))
            let value = Float(mixed)
            for buffer in buffers {
                if let data = buffer.mData {
                    data.assumingMemoryBound(to: Float.self)[frame] = value
                }
            }
        }

        voices.removeAll { $0.isFinished }
    }

    // MARK: - Playing notes

    /// Schedules one note. `delay` lets a caller lay out an arpeggio in a single
    /// call without blocking.
    func play(
        frequency: Double,
        duration: Double,
        amplitude: Double = 0.22,
        waveform: Waveform = .sine,
        delay: Double = 0
    ) {
        guard frequency > 0, duration > 0 else { return }
        guard delay <= 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.play(
                    frequency: frequency,
                    duration: duration,
                    amplitude: amplitude,
                    waveform: waveform
                )
            }
            return
        }

        start()
        guard isRunning else { return }

        let total = Int(duration * sampleRate)
        let attack = min(total / 4, Int(0.012 * sampleRate))
        let release = min(total - attack, Int(max(0.05, duration * 0.5) * sampleRate))

        let voice = Voice(
            phase: 0,
            phaseIncrement: 2 * .pi * frequency / sampleRate,
            amplitude: amplitude,
            waveform: waveform,
            elapsed: 0,
            attackSamples: max(1, attack),
            releaseSamples: max(1, release),
            totalSamples: max(2, total)
        )

        os_unfair_lock_lock(lock)
        if voices.count >= maximumVoices {
            voices.removeFirst()
        }
        voices.append(voice)
        os_unfair_lock_unlock(lock)
    }

    /// MIDI note number to hertz. 69 is concert A at 440 Hz.
    static func frequency(forMIDINote note: Int) -> Double {
        440 * pow(2, (Double(note) - 69) / 12)
    }

    func play(
        midiNote: Int,
        duration: Double,
        amplitude: Double = 0.22,
        waveform: Waveform = .sine,
        delay: Double = 0
    ) {
        play(
            frequency: Self.frequency(forMIDINote: midiNote),
            duration: duration,
            amplitude: amplitude,
            waveform: waveform,
            delay: delay
        )
    }
}
