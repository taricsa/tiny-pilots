import Foundation
import AVFoundation
import UIKit

/// Implementation of AudioServiceProtocol
class AudioService: AudioServiceProtocol {
    
    // MARK: - Properties
    
    /// Sound effect players
    private var soundEffectPlayers: [String: AVAudioPlayer] = [:]
    
    /// Background music player
    private var musicPlayer: AVAudioPlayer?
    
    /// Current sound effects volume (0.0 to 1.0)
    var soundVolume: Float {
        get { _soundVolume }
        set {
            _soundVolume = max(0, min(1, newValue))
            updateSoundVolumes()
            UserDefaults.standard.set(Double(_soundVolume), forKey: "soundVolume")
        }
    }
    private var _soundVolume: Float = 0.7
    
    /// Current music volume (0.0 to 1.0)
    var musicVolume: Float {
        get { _musicVolume }
        set {
            _musicVolume = max(0, min(1, newValue))
            musicPlayer?.volume = _musicVolume
            UserDefaults.standard.set(Double(_musicVolume), forKey: "musicVolume")
        }
    }
    private var _musicVolume: Float = 0.5
    
    /// Whether sound effects are enabled
    var soundEnabled: Bool {
        get { _soundEnabled }
        set {
            _soundEnabled = newValue
            if !newValue {
                stopAllSounds()
            }
            UserDefaults.standard.set(newValue, forKey: "soundEnabled")
        }
    }
    private var _soundEnabled: Bool = true
    
    /// Whether background music is enabled
    var musicEnabled: Bool {
        get { _musicEnabled }
        set {
            _musicEnabled = newValue
            if !newValue {
                stopMusic(fadeOut: 0)
            } else if let track = currentMusicTrack {
                playMusic(track, volume: nil, loop: true, fadeIn: 0)
            }
            UserDefaults.standard.set(newValue, forKey: "musicEnabled")
        }
    }
    private var _musicEnabled: Bool = true
    
    /// Currently playing music track name
    private(set) var currentMusicTrack: String?
    
    // MARK: - Initialization
    
    init() {
        setupAudioSession()
        loadSettings()
    }
    
    /// Set up the audio session
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    /// Load audio settings from UserDefaults
    private func loadSettings() {
        _soundVolume = Float(UserDefaults.standard.double(forKey: "soundVolume"))
        _musicVolume = Float(UserDefaults.standard.double(forKey: "musicVolume"))
        _soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        _musicEnabled = UserDefaults.standard.bool(forKey: "musicEnabled")
        
        // Use defaults if not set
        if _soundVolume == 0 {
            _soundVolume = 0.7
            UserDefaults.standard.set(Double(_soundVolume), forKey: "soundVolume")
        }
        
        if _musicVolume == 0 {
            _musicVolume = 0.5
            UserDefaults.standard.set(Double(_musicVolume), forKey: "musicVolume")
        }
        
        // Set default enabled states if not previously set
        if UserDefaults.standard.object(forKey: "soundEnabled") == nil {
            _soundEnabled = true
            UserDefaults.standard.set(true, forKey: "soundEnabled")
        }
        
        if UserDefaults.standard.object(forKey: "musicEnabled") == nil {
            _musicEnabled = true
            UserDefaults.standard.set(true, forKey: "musicEnabled")
        }
    }
    
    // MARK: - Sound Effects
    
    func playSound(_ name: String, volume: Float? = nil, pitch: Float = 1.0, completion: (() -> Void)? = nil) {
        guard soundEnabled else {
            completion?()
            return
        }
        
        // Check if we already have this sound loaded
        if let player = soundEffectPlayers[name] {
            player.volume = volume ?? soundVolume
            player.rate = pitch
            player.currentTime = 0
            player.play()
            
            // Call completion handler when done
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + player.duration) {
                    completion()
                }
            }
            return
        }
        
        // Load the sound
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            print("Sound file not found: \(name)")
            completion?()
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume ?? soundVolume
            player.rate = pitch
            player.prepareToPlay()
            player.play()
            
            // Store for reuse
            soundEffectPlayers[name] = player
            
            // Call completion handler when done
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + player.duration) {
                    completion()
                }
            }
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
            completion?()
        }
    }
    
    func stopSound(_ name: String) {
        soundEffectPlayers[name]?.stop()
    }
    
    func stopAllSounds() {
        for (_, player) in soundEffectPlayers {
            player.stop()
        }
    }
    
    /// Update volumes for all sound effect players
    private func updateSoundVolumes() {
        for (_, player) in soundEffectPlayers {
            player.volume = soundVolume
        }
    }
    
    // MARK: - Background Music
    
    func playMusic(_ name: String, volume: Float? = nil, loop: Bool = true, fadeIn: TimeInterval = 0) {
        guard musicEnabled else { return }
        
        // Don't restart if already playing this track
        if currentMusicTrack == name && musicPlayer?.isPlaying == true {
            return
        }
        
        // Stop current music
        stopMusic(fadeOut: fadeIn > 0 ? fadeIn : 0)
        
        // Load the music
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("Music file not found: \(name)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loop ? -1 : 0
            player.volume = fadeIn > 0 ? 0 : (volume ?? musicVolume)
            player.prepareToPlay()
            player.play()
            
            // Store reference
            musicPlayer = player
            currentMusicTrack = name
            
            // Fade in if needed
            if fadeIn > 0 {
                fadeInMusic(to: volume ?? musicVolume, duration: fadeIn)
            }
        } catch {
            print("Failed to play music: \(error.localizedDescription)")
        }
    }
    
    func stopMusic(fadeOut: TimeInterval = 0) {
        guard let player = musicPlayer, player.isPlaying else { return }
        
        if fadeOut > 0 {
            fadeOutMusic(duration: fadeOut) { [weak self] in
                self?.musicPlayer?.stop()
                self?.currentMusicTrack = nil
            }
        } else {
            player.stop()
            currentMusicTrack = nil
        }
    }
    
    func pauseMusic() {
        musicPlayer?.pause()
    }
    
    func resumeMusic() {
        guard musicEnabled else { return }
        musicPlayer?.play()
    }
    
    /// Fade in music to target volume
    private func fadeInMusic(to targetVolume: Float, duration: TimeInterval) {
        guard let player = musicPlayer else { return }
        
        let fadeSteps = 20
        let stepDuration = duration / TimeInterval(fadeSteps)
        let volumeIncrement = targetVolume / Float(fadeSteps)
        
        for i in 1...fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * TimeInterval(i)) {
                player.volume = min(targetVolume, volumeIncrement * Float(i))
            }
        }
    }
    
    /// Fade out music
    private func fadeOutMusic(duration: TimeInterval, completion: @escaping () -> Void) {
        guard let player = musicPlayer else {
            completion()
            return
        }
        
        let initialVolume = player.volume
        let fadeSteps = 20
        let stepDuration = duration / TimeInterval(fadeSteps)
        let volumeDecrement = initialVolume / Float(fadeSteps)
        
        for i in 1...fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * TimeInterval(i)) {
                player.volume = max(0, initialVolume - volumeDecrement * Float(i))
                
                // Call completion after last step
                if i == fadeSteps {
                    completion()
                }
            }
        }
    }
    
    // MARK: - Preloading
    
    func preloadSounds(_ names: [String]) {
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
                print("Sound file not found for preloading: \(name)")
                continue
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                soundEffectPlayers[name] = player
            } catch {
                print("Failed to preload sound: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Master Volume
    
    func setMasterVolume(_ volume: Float) {
        let clampedVolume = max(0, min(1, volume))
        
        // Update both sound and music volumes proportionally
        let soundRatio = soundVolume / 1.0
        let musicRatio = musicVolume / 1.0
        
        soundVolume = clampedVolume * soundRatio
        musicVolume = clampedVolume * musicRatio
    }
}