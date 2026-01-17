import Foundation
import AVFoundation

/// Protocol defining audio service functionality
protocol AudioServiceProtocol {
    /// Current sound effects volume (0.0 to 1.0)
    var soundVolume: Float { get set }
    
    /// Current music volume (0.0 to 1.0)
    var musicVolume: Float { get set }
    
    /// Whether sound effects are enabled
    var soundEnabled: Bool { get set }
    
    /// Whether background music is enabled
    var musicEnabled: Bool { get set }
    
    /// Currently playing music track name
    var currentMusicTrack: String? { get }
    
    /// Play a sound effect
    /// - Parameters:
    ///   - name: The name of the sound file (without extension)
    ///   - volume: Optional volume override (0.0 to 1.0)
    ///   - pitch: Optional pitch adjustment (0.5 to 2.0, default 1.0)
    ///   - completion: Optional completion handler
    func playSound(_ name: String, volume: Float?, pitch: Float, completion: (() -> Void)?)
    
    /// Stop a specific sound effect
    /// - Parameter name: The name of the sound to stop
    func stopSound(_ name: String)
    
    /// Stop all currently playing sound effects
    func stopAllSounds()
    
    /// Play background music
    /// - Parameters:
    ///   - name: The name of the music file (without extension)
    ///   - volume: Optional volume override (0.0 to 1.0)
    ///   - loop: Whether to loop the music (default true)
    ///   - fadeIn: Duration of fade-in in seconds (default 0)
    func playMusic(_ name: String, volume: Float?, loop: Bool, fadeIn: TimeInterval)
    
    /// Stop the currently playing music
    /// - Parameter fadeOut: Duration of fade-out in seconds (default 0)
    func stopMusic(fadeOut: TimeInterval)
    
    /// Pause the currently playing music
    func pauseMusic()
    
    /// Resume the paused music
    func resumeMusic()
    
    /// Preload sound effects for faster playback
    /// - Parameter names: Array of sound file names to preload
    func preloadSounds(_ names: [String])
    
    /// Set the master volume for all audio
    /// - Parameter volume: Master volume level (0.0 to 1.0)
    func setMasterVolume(_ volume: Float)
}

/// Audio service errors
enum AudioServiceError: Error, LocalizedError {
    case fileNotFound(String)
    case playbackFailed(String)
    case audioSessionError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Audio file not found: \(filename)"
        case .playbackFailed(let reason):
            return "Audio playback failed: \(reason)"
        case .audioSessionError(let reason):
            return "Audio session error: \(reason)"
        }
    }
}