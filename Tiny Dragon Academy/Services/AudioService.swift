//
//  AudioService.swift
//  Tiny Dragon Academy
//
//  Complete 100% offline procedural audio synthesizer for gentle child-friendly sounds.
//  Uses AVFoundation and AVAudioEngine to generate smooth, gentle tones, chimes,
//  magical sparkles, egg cracking, and a soft ambient music box lullaby.
//

import AVFoundation
import Foundation
import Combine

@MainActor
final class AudioService: ObservableObject {
    static let shared = AudioService()
    
    @Published var isSoundEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "sound_effects_enabled")
        }
    }
    
    @Published var isMusicEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "music_enabled")
            if isMusicEnabled {
                startMusic()
            } else {
                stopMusic()
            }
        }
    }
    
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let musicPlayerNode = AVAudioPlayerNode()
    private let audioFormat: AVAudioFormat
    
    private var musicTimer: Timer?
    private var isEngineRunning = false
    
    private init() {
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "sound_effects_enabled") as? Bool ?? true
        self.isMusicEnabled = UserDefaults.standard.object(forKey: "music_enabled") as? Bool ?? true
        
        let sampleRate: Double = 44100.0
        self.audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        setupEngine()
        
        if isMusicEnabled {
            startMusic()
        }
    }
    
    private func setupEngine() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session configuration error: \(error.localizedDescription)")
        }
        #endif
        
        audioEngine.attach(playerNode)
        audioEngine.attach(musicPlayerNode)
        
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        audioEngine.connect(musicPlayerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        
        do {
            try audioEngine.start()
            playerNode.play()
            musicPlayerNode.play()
            isEngineRunning = true
        } catch {
            print("AVAudioEngine start error: \(error.localizedDescription)")
        }
    }
    
    private func ensureEngineRunning() {
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
                if !playerNode.isPlaying { playerNode.play() }
                if !musicPlayerNode.isPlaying { musicPlayerNode.play() }
                isEngineRunning = true
            } catch {
                print("Failed to restart audioEngine: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Procedural Sound Generation
    
    /// Generates a sine-wave based tone with customizable envelope
    private func createToneBuffer(
        frequency: Double,
        duration: Double,
        attackTime: Double = 0.02,
        decayTime: Double = 0.15,
        volume: Float = 0.35,
        vibratoFreq: Double = 0.0,
        vibratoDepth: Double = 0.0
    ) -> AVAudioPCMBuffer? {
        let sampleRate = audioFormat.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        
        let twoPi = 2.0 * Double.pi
        let attackFrames = attackTime * sampleRate
        let decayStartFrame = frameCount - AVAudioFrameCount(decayTime * sampleRate)
        
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            
            // Vibrato calculation
            var currentFreq = frequency
            if vibratoDepth > 0 {
                currentFreq += sin(twoPi * vibratoFreq * t) * vibratoDepth
            }
            
            // Amplitude envelope (smooth attack and release)
            var envelope: Double = 1.0
            if Double(frame) < attackFrames && attackFrames > 0 {
                envelope = Double(frame) / attackFrames
            } else if frame > Int(decayStartFrame) {
                let decayFrames = Double(frameCount) - Double(decayStartFrame)
                let elapsed = Double(frame) - Double(decayStartFrame)
                envelope = max(0.0, 1.0 - (elapsed / decayFrames))
            }
            
            // Harmonic warmth (gentle second harmonic)
            let fundamental = sin(twoPi * currentFreq * t)
            let overtone = 0.25 * sin(twoPi * currentFreq * 2.0 * t)
            let sample = Float((fundamental + overtone) * envelope) * volume
            channelData[frame] = sample
        }
        
        return buffer
    }
    
    // MARK: - Public Sound Effects
    
    /// Gentle tap feedback
    func playPop() {
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        guard let buffer = createToneBuffer(frequency: 520, duration: 0.08, attackTime: 0.005, decayTime: 0.07, volume: 0.3) else { return }
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
    
    /// Soft magical bell chime
    func playChime(frequency: Double = 659.25) { // E5 note
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        guard let buffer = createToneBuffer(frequency: frequency, duration: 0.45, attackTime: 0.01, decayTime: 0.4, volume: 0.35) else { return }
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
    
    /// Sound when a star is collected
    func playStarCollect() {
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        let notes: [Double] = [587.33, 739.99, 880.00, 1174.66] // D5, F#5, A5, D6
        for (index, note) in notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) { [weak self] in
                guard let self = self, self.isSoundEnabled else { return }
                if let buffer = self.createToneBuffer(frequency: note, duration: 0.3, attackTime: 0.01, decayTime: 0.25, volume: 0.25) {
                    self.playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                }
            }
        }
    }
    
    /// Egg tap / crack sound effect
    func playEggCrack(intensity: Int = 1) {
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        let baseFreq = 300.0 + Double(intensity) * 120.0
        guard let buffer = createToneBuffer(frequency: baseFreq, duration: 0.12, attackTime: 0.005, decayTime: 0.1, volume: 0.4, vibratoFreq: 50.0, vibratoDepth: 30.0) else { return }
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
    
    /// Baby dragon giggle reaction when petted
    func playDragonGiggle() {
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        let notes: [Double] = [700, 850, 950, 800, 920, 1050]
        for (index, note) in notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.06) { [weak self] in
                guard let self = self, self.isSoundEnabled else { return }
                if let buffer = self.createToneBuffer(frequency: note, duration: 0.12, attackTime: 0.01, decayTime: 0.08, volume: 0.28, vibratoFreq: 15.0, vibratoDepth: 25.0) {
                    self.playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                }
            }
        }
    }
    
    /// Gentle encouragement sound for non-matching attempts (friendly boing)
    func playEncouragement() {
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        guard let buffer = createToneBuffer(frequency: 349.23, duration: 0.25, attackTime: 0.02, decayTime: 0.2, volume: 0.22) else { return }
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
    
    /// Hatching and game completion fanfare
    func playVictoryFanfare() {
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        // C major celebration arpeggio: C5, E5, G5, C6, G6
        let chords: [(Double, Double)] = [
            (523.25, 0.0),
            (659.25, 0.12),
            (783.99, 0.24),
            (1046.50, 0.38),
            (1318.51, 0.55),
            (1567.98, 0.72)
        ]
        
        for (pitch, delay) in chords {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, self.isSoundEnabled else { return }
                if let buffer = self.createToneBuffer(frequency: pitch, duration: 0.5, attackTime: 0.01, decayTime: 0.45, volume: 0.3) {
                    self.playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                }
            }
        }
    }
    
    // MARK: - Feeding & Raising Sound Effects
    
    /// Playful chewing/eating chime
    func playFeedingSound() {
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        let munchNotes: [Double] = [440.0, 523.25, 659.25, 783.99]
        for (idx, freq) in munchNotes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.07) { [weak self] in
                guard let self = self else { return }
                if let buf = self.createToneBuffer(frequency: freq, duration: 0.12, attackTime: 0.01, decayTime: 0.10, volume: 0.28) {
                    self.playerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
                }
            }
        }
    }
    
    /// Playful crunchy bite / chomp sound when dragon catches food
    func playMunchChompSound() {
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        let bites: [(Double, Double)] = [(587.33, 0.0), (440.0, 0.05)]
        for (freq, delay) in bites {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, self.isSoundEnabled else { return }
                if let buf = self.createToneBuffer(frequency: freq, duration: 0.09, attackTime: 0.005, decayTime: 0.08, volume: 0.35, vibratoFreq: 35.0, vibratoDepth: 20.0) {
                    self.playerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
                }
            }
        }
    }
    
    /// Happy swallow / gulp sound after chewing
    func playSwallowSound() {
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        let gulpTones: [(Double, Double)] = [(349.23, 0.0), (523.25, 0.08)]
        for (freq, delay) in gulpTones {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, self.isSoundEnabled else { return }
                if let buf = self.createToneBuffer(frequency: freq, duration: 0.14, attackTime: 0.01, decayTime: 0.12, volume: 0.30) {
                    self.playerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
                }
            }
        }
    }
    
    /// Level-up fanfare chime
    func playLevelUp() {
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        let notes: [Double] = [523.25, 659.25, 783.99, 1046.50]
        for (i, pitch) in notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) { [weak self] in
                guard let self = self else { return }
                if let buf = self.createToneBuffer(frequency: pitch, duration: 0.35, attackTime: 0.01, decayTime: 0.32, volume: 0.35) {
                    self.playerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
                }
            }
        }
    }
    
    /// Grand evolution ceremony fanfare
    func playEvolutionFanfare() {
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        let notes: [Double] = [392.0, 523.25, 659.25, 783.99, 1046.50, 1318.51]
        for (i, pitch) in notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) { [weak self] in
                guard let self = self else { return }
                if let buf = self.createToneBuffer(frequency: pitch, duration: 0.6, attackTime: 0.02, decayTime: 0.55, volume: 0.4) {
                    self.playerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
                }
            }
        }
    }
    
    /// Procedural elemental power synthesis
    func playElementalPowerSound(element: DragonElement) {
        guard isSoundEnabled else { return }
        ensureEngineRunning()
        
        switch element {
        case .fire:
            // Roaring warm low frequency whoosh
            for (i, freq) in [150.0, 220.0, 310.0, 180.0].enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) { [weak self] in
                    guard let self = self else { return }
                    if let buf = self.createToneBuffer(frequency: freq, duration: 0.25, attackTime: 0.03, decayTime: 0.20, volume: 0.35) {
                        self.playerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
                    }
                }
            }
        case .ice:
            // High sparkling crystal chimes
            for (i, freq) in [1200.0, 1500.0, 1800.0, 2200.0].enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) { [weak self] in
                    guard let self = self else { return }
                    if let buf = self.createToneBuffer(frequency: freq, duration: 0.2, attackTime: 0.01, decayTime: 0.18, volume: 0.25) {
                        self.playerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
                    }
                }
            }
        case .lightning:
            // Crackling rapid zap
            for (i, freq) in [800.0, 300.0, 950.0, 250.0, 1100.0].enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) { [weak self] in
                    guard let self = self else { return }
                    if let buf = self.createToneBuffer(frequency: freq, duration: 0.09, attackTime: 0.005, decayTime: 0.08, volume: 0.35) {
                        self.playerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
                    }
                }
            }
        case .laser:
            // Sci-fi sliding pitch beam
            for (i, freq) in [900.0, 800.0, 700.0, 600.0, 500.0].enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) { [weak self] in
                    guard let self = self else { return }
                    if let buf = self.createToneBuffer(frequency: freq, duration: 0.1, attackTime: 0.01, decayTime: 0.08, volume: 0.3) {
                        self.playerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
                    }
                }
            }
        case .earth:
            // Deep resonant ground thumps
            for (i, freq) in [110.0, 90.0, 130.0, 80.0].enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.09) { [weak self] in
                    guard let self = self else { return }
                    if let buf = self.createToneBuffer(frequency: freq, duration: 0.3, attackTime: 0.02, decayTime: 0.25, volume: 0.4) {
                        self.playerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
                    }
                }
            }
        default:
            // Star / magical swirl chime
            for (i, freq) in [659.25, 783.99, 987.77, 1318.51].enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) { [weak self] in
                    guard let self = self else { return }
                    if let buf = self.createToneBuffer(frequency: freq, duration: 0.3, attackTime: 0.01, decayTime: 0.28, volume: 0.3) {
                        self.playerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Ambient Lullaby Music Box
    
    func startMusic() {
        stopMusic()
        guard isMusicEnabled else { return }
        ensureEngineRunning()
        
        // Pentatonic scale (C, D, E, G, A) - always soothing, harmonious and sweet
        let lullabyScale: [Double] = [
            523.25, // C5
            587.33, // D5
            659.25, // E5
            783.99, // G5
            880.00, // A5
            1046.50 // C6
        ]
        
        var step = 0
        let melodySequence = [0, 2, 4, 3, 1, 3, 5, 4, 2, 4, 3, 1, 0, 2, 4, 5]
        
        musicTimer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true) { [weak self] _ in
            guard let self = self, self.isMusicEnabled else { return }
            let noteIdx = melodySequence[step % melodySequence.count]
            let freq = lullabyScale[noteIdx]
            step += 1
            
            // Soft music-box note
            if let noteBuffer = self.createToneBuffer(
                frequency: freq,
                duration: 1.1,
                attackTime: 0.015,
                decayTime: 0.95,
                volume: 0.12
            ) {
                self.musicPlayerNode.scheduleBuffer(noteBuffer, at: nil, options: [], completionHandler: nil)
            }
        }
    }
    
    func stopMusic() {
        musicTimer?.invalidate()
        musicTimer = nil
        musicPlayerNode.stop()
        if isEngineRunning {
            musicPlayerNode.play()
        }
    }
}
