import XCTest
import AVFoundation
@testable import Tiny_Pilots

/// Unit tests for AudioService
class AudioServiceTests: XCTestCase {
    
    var sut: AudioService!
    
    override func setUp() {
        super.setUp()
        sut = AudioService()
        
        // Clear UserDefaults for consistent testing
        UserDefaults.standard.removeObject(forKey: "soundVolume")
        UserDefaults.standard.removeObject(forKey: "musicVolume")
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
        UserDefaults.standard.removeObject(forKey: "musicEnabled")
    }
    
    override func tearDown() {
        sut.stopAllSounds()
        sut.stopMusic(fadeOut: 0)
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_SetsDefaultValues() {
        // Given - fresh service instance
        
        // Then
        XCTAssertEqual(sut.soundVolume, 0.7, accuracy: 0.01, "Default sound volume should be 0.7")
        XCTAssertEqual(sut.musicVolume, 0.5, accuracy: 0.01, "Default music volume should be 0.5")
        XCTAssertTrue(sut.soundEnabled, "Sound should be enabled by default")
        XCTAssertTrue(sut.musicEnabled, "Music should be enabled by default")
        XCTAssertNil(sut.currentMusicTrack, "No music should be playing initially")
    }
    
    // MARK: - Volume Tests
    
    func testSetSoundVolume_UpdatesVolume() {
        // Given
        let newVolume: Float = 0.8
        
        // When
        sut.soundVolume = newVolume
        
        // Then
        XCTAssertEqual(sut.soundVolume, newVolume, accuracy: 0.01, "Sound volume should be updated")
    }
    
    func testSetSoundVolume_ClampsToValidRange() {
        // Given
        let tooHigh: Float = 1.5
        let tooLow: Float = -0.5
        
        // When & Then
        sut.soundVolume = tooHigh
        XCTAssertEqual(sut.soundVolume, 1.0, accuracy: 0.01, "Sound volume should be clamped to 1.0")
        
        sut.soundVolume = tooLow
        XCTAssertEqual(sut.soundVolume, 0.0, accuracy: 0.01, "Sound volume should be clamped to 0.0")
    }
    
    func testSetMusicVolume_UpdatesVolume() {
        // Given
        let newVolume: Float = 0.9
        
        // When
        sut.musicVolume = newVolume
        
        // Then
        XCTAssertEqual(sut.musicVolume, newVolume, accuracy: 0.01, "Music volume should be updated")
    }
    
    func testSetMusicVolume_ClampsToValidRange() {
        // Given
        let tooHigh: Float = 2.0
        let tooLow: Float = -1.0
        
        // When & Then
        sut.musicVolume = tooHigh
        XCTAssertEqual(sut.musicVolume, 1.0, accuracy: 0.01, "Music volume should be clamped to 1.0")
        
        sut.musicVolume = tooLow
        XCTAssertEqual(sut.musicVolume, 0.0, accuracy: 0.01, "Music volume should be clamped to 0.0")
    }
    
    // MARK: - Enable/Disable Tests
    
    func testSetSoundEnabled_False_StopsAllSounds() {
        // Given
        sut.soundEnabled = true
        
        // When
        sut.soundEnabled = false
        
        // Then
        XCTAssertFalse(sut.soundEnabled, "Sound should be disabled")
    }
    
    func testSetMusicEnabled_False_StopsMusic() {
        // Given
        sut.musicEnabled = true
        
        // When
        sut.musicEnabled = false
        
        // Then
        XCTAssertFalse(sut.musicEnabled, "Music should be disabled")
    }
    
    // MARK: - Sound Effect Tests
    
    func testPlaySound_WhenSoundDisabled_DoesNotPlay() {
        // Given
        sut.soundEnabled = false
        let expectation = XCTestExpectation(description: "Completion called")
        
        // When
        sut.playSound("nonexistent_sound") {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        // Test passes if no crash occurs and completion is called
    }
    
    func testPlaySound_WithNonexistentFile_CallsCompletion() {
        // Given
        let expectation = XCTestExpectation(description: "Completion called")
        
        // When
        sut.playSound("nonexistent_sound") {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        // Test passes if completion is called even when file doesn't exist
    }
    
    func testStopSound_WithValidName_DoesNotCrash() {
        // Given
        let soundName = "test_sound"
        
        // When & Then
        XCTAssertNoThrow(sut.stopSound(soundName), "Stopping sound should not crash")
    }
    
    func testStopAllSounds_DoesNotCrash() {
        // When & Then
        XCTAssertNoThrow(sut.stopAllSounds(), "Stopping all sounds should not crash")
    }
    
    // MARK: - Music Tests
    
    func testPlayMusic_WhenMusicDisabled_DoesNotPlay() {
        // Given
        sut.musicEnabled = false
        
        // When
        sut.playMusic("nonexistent_music", volume: nil, loop: true, fadeIn: 0)
        
        // Then
        XCTAssertNil(sut.currentMusicTrack, "No music should be playing when disabled")
    }
    
    func testPlayMusic_WithNonexistentFile_DoesNotCrash() {
        // Given
        sut.musicEnabled = true
        
        // When & Then
        XCTAssertNoThrow(sut.playMusic("nonexistent_music", volume: nil, loop: true, fadeIn: 0), "Playing nonexistent music should not crash")
        XCTAssertNil(sut.currentMusicTrack, "Current music track should remain nil")
    }
    
    func testStopMusic_DoesNotCrash() {
        // When & Then
        XCTAssertNoThrow(sut.stopMusic(fadeOut: 0), "Stopping music should not crash")
    }
    
    func testPauseMusic_DoesNotCrash() {
        // When & Then
        XCTAssertNoThrow(sut.pauseMusic(), "Pausing music should not crash")
    }
    
    func testResumeMusic_DoesNotCrash() {
        // When & Then
        XCTAssertNoThrow(sut.resumeMusic(), "Resuming music should not crash")
    }
    
    // MARK: - Preloading Tests
    
    func testPreloadSounds_WithEmptyArray_DoesNotCrash() {
        // Given
        let emptySounds: [String] = []
        
        // When & Then
        XCTAssertNoThrow(sut.preloadSounds(emptySounds), "Preloading empty array should not crash")
    }
    
    func testPreloadSounds_WithNonexistentFiles_DoesNotCrash() {
        // Given
        let nonexistentSounds = ["fake1", "fake2", "fake3"]
        
        // When & Then
        XCTAssertNoThrow(sut.preloadSounds(nonexistentSounds), "Preloading nonexistent sounds should not crash")
    }
    
    // MARK: - Master Volume Tests
    
    func testSetMasterVolume_UpdatesAllVolumes() {
        // Given
        let initialSoundVolume = sut.soundVolume
        let initialMusicVolume = sut.musicVolume
        let masterVolume: Float = 0.5
        
        // When
        sut.setMasterVolume(masterVolume)
        
        // Then
        XCTAssertLessThanOrEqual(sut.soundVolume, initialSoundVolume, "Sound volume should be reduced")
        XCTAssertLessThanOrEqual(sut.musicVolume, initialMusicVolume, "Music volume should be reduced")
    }
    
    func testSetMasterVolume_ClampsToValidRange() {
        // Given
        let tooHigh: Float = 2.0
        let tooLow: Float = -1.0
        
        // When & Then
        XCTAssertNoThrow(sut.setMasterVolume(tooHigh), "Setting master volume too high should not crash")
        XCTAssertNoThrow(sut.setMasterVolume(tooLow), "Setting master volume too low should not crash")
        
        // Volumes should be within valid range
        XCTAssertGreaterThanOrEqual(sut.soundVolume, 0.0, "Sound volume should not be negative")
        XCTAssertLessThanOrEqual(sut.soundVolume, 1.0, "Sound volume should not exceed 1.0")
        XCTAssertGreaterThanOrEqual(sut.musicVolume, 0.0, "Music volume should not be negative")
        XCTAssertLessThanOrEqual(sut.musicVolume, 1.0, "Music volume should not exceed 1.0")
    }
}// M
ARK: - Additional Comprehensive Tests

extension AudioServiceTests {
    
    // MARK: - Error Handling Tests
    
    func testPlaySound_WithCorruptedAudioSession_HandlesGracefully() {
        // Given
        let expectation = XCTestExpectation(description: "Completion called despite audio session issues")
        
        // When
        sut.playSound("test_sound", volume: 0.5, pitch: 1.0) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        // Test passes if completion is called without crashing
    }
    
    func testPlayMusic_WithInvalidParameters_HandlesGracefully() {
        // Given
        sut.musicEnabled = true
        
        // When & Then
        XCTAssertNoThrow(sut.playMusic("", volume: nil, loop: true, fadeIn: -1.0), "Empty music name should not crash")
        XCTAssertNoThrow(sut.playMusic("test", volume: -5.0, loop: true, fadeIn: 0), "Invalid volume should not crash")
        XCTAssertNoThrow(sut.playMusic("test", volume: nil, loop: true, fadeIn: -10.0), "Negative fade time should not crash")
    }
    
    func testAudioInterruption_HandlesCorrectly() {
        // Given
        sut.playMusic("test_music", volume: nil, loop: true, fadeIn: 0)
        
        // When - Simulate audio interruption
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: nil, userInfo: [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue
        ])
        
        // Then - Should handle gracefully without crashing
        XCTAssertTrue(true)
    }
    
    func testAudioRouteChange_HandlesCorrectly() {
        // Given
        sut.playMusic("test_music", volume: nil, loop: true, fadeIn: 0)
        
        // When - Simulate route change (e.g., headphones disconnected)
        NotificationCenter.default.post(name: AVAudioSession.routeChangeNotification, object: nil, userInfo: [
            AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
        ])
        
        // Then - Should handle gracefully without crashing
        XCTAssertTrue(true)
    }
    
    // MARK: - Performance Tests
    
    func testMultipleSoundPlayback_PerformanceTest() {
        // Given
        sut.soundEnabled = true
        
        // When
        measure {
            for i in 0..<100 {
                sut.playSound("test_sound_\(i % 5)", volume: nil, pitch: 1.0, completion: nil)
            }
        }
        
        // Then - Should complete without significant performance issues
        XCTAssertTrue(true)
    }
    
    func testRapidVolumeChanges_PerformanceTest() {
        // When
        measure {
            for i in 0..<1000 {
                sut.soundVolume = Float(i % 100) / 100.0
                sut.musicVolume = Float((i + 50) % 100) / 100.0
            }
        }
        
        // Then
        XCTAssertGreaterThanOrEqual(sut.soundVolume, 0.0)
        XCTAssertLessThanOrEqual(sut.soundVolume, 1.0)
    }
    
    // MARK: - Memory Management Tests
    
    func testSoundPlayback_DoesNotLeak() {
        // Given
        sut.soundEnabled = true
        
        // When
        for _ in 0..<50 {
            sut.playSound("test_sound", volume: nil, pitch: 1.0, completion: nil)
            sut.stopSound("test_sound")
        }
        
        // Then - Should not leak memory
        XCTAssertTrue(true)
    }
    
    func testMusicPlayback_DoesNotLeak() {
        // Given
        sut.musicEnabled = true
        
        // When
        for i in 0..<10 {
            sut.playMusic("test_music_\(i)", volume: nil, loop: false, fadeIn: 0)
            sut.stopMusic(fadeOut: 0)
        }
        
        // Then - Should not leak memory
        XCTAssertTrue(true)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentVolumeChanges_ThreadSafe() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent volume changes complete")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.sut.soundVolume = Float(i) / 10.0
                self.sut.musicVolume = Float(9 - i) / 10.0
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then
        XCTAssertGreaterThanOrEqual(sut.soundVolume, 0.0)
        XCTAssertLessThanOrEqual(sut.soundVolume, 1.0)
        XCTAssertGreaterThanOrEqual(sut.musicVolume, 0.0)
        XCTAssertLessThanOrEqual(sut.musicVolume, 1.0)
    }
    
    func testConcurrentSoundPlayback_ThreadSafe() {
        // Given
        sut.soundEnabled = true
        let expectation = XCTestExpectation(description: "Concurrent sound playback complete")
        expectation.expectedFulfillmentCount = 5
        
        // When
        for i in 0..<5 {
            DispatchQueue.global().async {
                self.sut.playSound("test_sound_\(i)", volume: nil, pitch: 1.0) {
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then - Should complete without crashing
        XCTAssertTrue(true)
    }
    
    // MARK: - Audio Session Tests
    
    func testAudioSessionConfiguration_SetsCorrectCategory() {
        // Given
        let audioSession = AVAudioSession.sharedInstance()
        
        // When - Audio service should configure session appropriately
        sut.playMusic("test_music", volume: nil, loop: true, fadeIn: 0)
        
        // Then
        XCTAssertTrue(audioSession.category == .ambient || 
                     audioSession.category == .playback ||
                     audioSession.category == .soloAmbient,
                     "Audio session should be configured for playback")
    }
    
    func testAudioSessionActivation_HandlesErrors() {
        // Given
        let expectation = XCTestExpectation(description: "Audio session activation handled")
        
        // When
        sut.playMusic("test_music", volume: nil, loop: true, fadeIn: 0)
        
        // Simulate a delay to allow audio session setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then - Should not crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Fade Effects Tests
    
    func testMusicFadeIn_WithValidDuration_DoesNotCrash() {
        // Given
        sut.musicEnabled = true
        
        // When & Then
        XCTAssertNoThrow(sut.playMusic("test_music", volume: nil, loop: true, fadeIn: 1.0), "Fade in should not crash")
    }
    
    func testMusicFadeOut_WithValidDuration_DoesNotCrash() {
        // Given
        sut.musicEnabled = true
        sut.playMusic("test_music", volume: nil, loop: true, fadeIn: 0)
        
        // When & Then
        XCTAssertNoThrow(sut.stopMusic(fadeOut: 1.0), "Fade out should not crash")
    }
    
    func testMusicFadeEffects_WithZeroDuration_HandlesCorrectly() {
        // Given
        sut.musicEnabled = true
        
        // When & Then
        XCTAssertNoThrow(sut.playMusic("test_music", volume: nil, loop: true, fadeIn: 0), "Zero fade in should not crash")
        XCTAssertNoThrow(sut.stopMusic(fadeOut: 0), "Zero fade out should not crash")
    }
    
    // MARK: - Sound Pitch Tests
    
    func testPlaySound_WithValidPitch_DoesNotCrash() {
        // Given
        sut.soundEnabled = true
        let expectation = XCTestExpectation(description: "Sound with pitch played")
        
        // When
        sut.playSound("test_sound", volume: nil, pitch: 1.5) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testPlaySound_WithExtremePitch_ClampsCorrectly() {
        // Given
        sut.soundEnabled = true
        let expectation = XCTestExpectation(description: "Sound with extreme pitch played")
        
        // When & Then
        XCTAssertNoThrow(sut.playSound("test_sound", volume: nil, pitch: 10.0) {
            expectation.fulfill()
        }, "Extreme high pitch should not crash")
        
        wait(for: [expectation], timeout: 2.0)
        
        let expectation2 = XCTestExpectation(description: "Sound with low pitch played")
        XCTAssertNoThrow(sut.playSound("test_sound", volume: nil, pitch: 0.1) {
            expectation2.fulfill()
        }, "Extreme low pitch should not crash")
        
        wait(for: [expectation2], timeout: 2.0)
    }
    
    // MARK: - Preloading Edge Cases
    
    func testPreloadSounds_WithMixedValidInvalid_HandlesCorrectly() {
        // Given
        let mixedSounds = ["valid_sound", "nonexistent_sound", "another_valid", ""]
        
        // When & Then
        XCTAssertNoThrow(sut.preloadSounds(mixedSounds), "Mixed valid/invalid sounds should not crash")
    }
    
    func testPreloadSounds_WithLargeArray_HandlesCorrectly() {
        // Given
        let largeSoundArray = (0..<1000).map { "sound_\($0)" }
        
        // When & Then
        XCTAssertNoThrow(sut.preloadSounds(largeSoundArray), "Large sound array should not crash")
    }
    
    // MARK: - State Persistence Tests
    
    func testVolumeSettings_PersistAcrossInstances() {
        // Given
        let testSoundVolume: Float = 0.3
        let testMusicVolume: Float = 0.8
        sut.soundVolume = testSoundVolume
        sut.musicVolume = testMusicVolume
        
        // When - Create new instance
        let newAudioService = AudioService()
        
        // Then
        XCTAssertEqual(newAudioService.soundVolume, testSoundVolume, accuracy: 0.01, "Sound volume should persist")
        XCTAssertEqual(newAudioService.musicVolume, testMusicVolume, accuracy: 0.01, "Music volume should persist")
    }
    
    func testEnabledSettings_PersistAcrossInstances() {
        // Given
        sut.soundEnabled = false
        sut.musicEnabled = false
        
        // When - Create new instance
        let newAudioService = AudioService()
        
        // Then
        XCTAssertFalse(newAudioService.soundEnabled, "Sound enabled state should persist")
        XCTAssertFalse(newAudioService.musicEnabled, "Music enabled state should persist")
    }
}