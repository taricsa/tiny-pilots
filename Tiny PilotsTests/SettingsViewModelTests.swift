//
//  SettingsViewModelTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
import SwiftData
@testable import Tiny_Pilots

final class SettingsViewModelTests: XCTestCase {
    
    var sut: SettingsViewModel!
    var mockAudioService: MockAudioService!
    var mockPhysicsService: MockPhysicsService!
    var mockGameCenterService: MockGameCenterService!
    var modelContext: ModelContext!
    var container: ModelContainer!
    
    override func setUp() {
        super.setUp()
        
        // Set up in-memory SwiftData container for testing
        do {
            let schema = Schema([
                PlayerData.self,
                GameResult.self,
                Achievement.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            modelContext = ModelContext(container)
        } catch {
            XCTFail("Failed to create test container: \(error)")
        }
        
        // Create mock services
        mockAudioService = MockAudioService()
        mockPhysicsService = MockPhysicsService()
        mockGameCenterService = MockGameCenterService()
        
        // Clear UserDefaults for testing
        UserDefaults.standard.removeObject(forKey: "gameSettings")
        
        // Create system under test
        sut = SettingsViewModel(
            audioService: mockAudioService,
            physicsService: mockPhysicsService,
            gameCenterService: mockGameCenterService,
            modelContext: modelContext
        )
        
        sut.initialize()
    }
    
    override func tearDown() {
        sut.cleanup()
        sut = nil
        mockAudioService = nil
        mockPhysicsService = nil
        mockGameCenterService = nil
        modelContext = nil
        container = nil
        
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "gameSettings")
        
        super.tearDown()
    }
    
    // MARK: - Property Mutability Tests
    
    func testAudioServiceProperty_IsMutable() {
        // Given
        let newMockAudioService = MockAudioService()
        newMockAudioService.soundVolume = 0.9
        
        // When - This should compile and work since audioService is now var
        sut.setAudioService(newMockAudioService)
        
        // Then
        XCTAssertEqual(sut.getAudioService().soundVolume, 0.9, accuracy: 0.01)
    }
    
    func testPhysicsServiceProperty_IsMutable() {
        // Given
        let newMockPhysicsService = MockPhysicsService()
        newMockPhysicsService.sensitivity = 1.8
        
        // When - This should compile and work since physicsService is now var
        sut.setPhysicsService(newMockPhysicsService)
        
        // Then
        XCTAssertEqual(sut.getPhysicsService().sensitivity, 1.8, accuracy: 0.01)
    }
    
    func testServiceProperties_CanBeReassignedMultipleTimes() {
        // Given
        let audioService1 = MockAudioService()
        let audioService2 = MockAudioService()
        let physicsService1 = MockPhysicsService()
        let physicsService2 = MockPhysicsService()
        
        audioService1.soundVolume = 0.3
        audioService2.soundVolume = 0.7
        physicsService1.sensitivity = 0.8
        physicsService2.sensitivity = 1.2
        
        // When - Multiple reassignments should work
        sut.setAudioService(audioService1)
        sut.setPhysicsService(physicsService1)
        
        // Then
        XCTAssertEqual(sut.getAudioService().soundVolume, 0.3, accuracy: 0.01)
        XCTAssertEqual(sut.getPhysicsService().sensitivity, 0.8, accuracy: 0.01)
        
        // When - Reassign again
        sut.setAudioService(audioService2)
        sut.setPhysicsService(physicsService2)
        
        // Then
        XCTAssertEqual(sut.getAudioService().soundVolume, 0.7, accuracy: 0.01)
        XCTAssertEqual(sut.getPhysicsService().sensitivity, 1.2, accuracy: 0.01)
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_SetsDefaultValues() {
        // Then
        XCTAssertEqual(sut.soundVolume, 0.7, accuracy: 0.01)
        XCTAssertEqual(sut.musicVolume, 0.5, accuracy: 0.01)
        XCTAssertTrue(sut.soundEnabled)
        XCTAssertTrue(sut.musicEnabled)
        XCTAssertEqual(sut.controlSensitivity, 1.0, accuracy: 0.01)
        XCTAssertTrue(sut.showTutorialTips)
        XCTAssertTrue(sut.useHapticFeedback)
        XCTAssertFalse(sut.invertControls)
        XCTAssertFalse(sut.highPerformanceMode)
        XCTAssertTrue(sut.particleEffectsEnabled)
        XCTAssertEqual(sut.graphicsQuality, .medium)
        XCTAssertTrue(sut.analyticsEnabled)
        XCTAssertTrue(sut.crashReportingEnabled)
        XCTAssertTrue(sut.gameCenterEnabled)
        XCTAssertTrue(sut.gameCenterNotifications)
    }
    
    func testInitialization_AppliesSettingsToServices() {
        // Then
        XCTAssertEqual(mockAudioService.soundVolume, 0.7, accuracy: 0.01)
        XCTAssertEqual(mockAudioService.musicVolume, 0.5, accuracy: 0.01)
        XCTAssertTrue(mockAudioService.soundEnabled)
        XCTAssertTrue(mockAudioService.musicEnabled)
        XCTAssertEqual(mockPhysicsService.sensitivity, 1.0, accuracy: 0.01)
    }
    
    func testInitialization_LoadsExistingSettings() {
        // Given
        let existingSettings = [
            "soundVolume": 0.8,
            "musicVolume": 0.3,
            "soundEnabled": false,
            "controlSensitivity": 1.2,
            "showTutorialTips": false
        ] as [String : Any]
        UserDefaults.standard.set(existingSettings, forKey: "gameSettings")
        
        // When
        let newSut = SettingsViewModel(
            audioService: mockAudioService,
            physicsService: mockPhysicsService,
            gameCenterService: mockGameCenterService,
            modelContext: modelContext
        )
        newSut.initialize()
        
        // Then
        XCTAssertEqual(newSut.soundVolume, 0.8, accuracy: 0.01)
        XCTAssertEqual(newSut.musicVolume, 0.3, accuracy: 0.01)
        XCTAssertFalse(newSut.soundEnabled)
        XCTAssertEqual(newSut.controlSensitivity, 1.2, accuracy: 0.01)
        XCTAssertFalse(newSut.showTutorialTips)
    }
    
    // MARK: - Audio Settings Tests
    
    func testSoundVolume_UpdatesAudioService() {
        // When
        sut.soundVolume = 0.9
        
        // Then
        XCTAssertEqual(mockAudioService.soundVolume, 0.9, accuracy: 0.01)
    }
    
    func testMusicVolume_UpdatesAudioService() {
        // When
        sut.musicVolume = 0.2
        
        // Then
        XCTAssertEqual(mockAudioService.musicVolume, 0.2, accuracy: 0.01)
    }
    
    func testSoundEnabled_UpdatesAudioService() {
        // When
        sut.soundEnabled = false
        
        // Then
        XCTAssertFalse(mockAudioService.soundEnabled)
    }
    
    func testMusicEnabled_UpdatesAudioService() {
        // When
        sut.musicEnabled = false
        
        // Then
        XCTAssertFalse(mockAudioService.musicEnabled)
    }
    
    // MARK: - Gameplay Settings Tests
    
    func testControlSensitivity_UpdatesPhysicsService() {
        // When
        sut.controlSensitivity = 1.3
        
        // Then
        XCTAssertEqual(mockPhysicsService.sensitivity, 1.3, accuracy: 0.01)
    }
    
    func testShowTutorialTips_UpdatesValue() {
        // When
        sut.showTutorialTips = false
        
        // Then
        XCTAssertFalse(sut.showTutorialTips)
    }
    
    func testUseHapticFeedback_UpdatesValue() {
        // When
        sut.useHapticFeedback = false
        
        // Then
        XCTAssertFalse(sut.useHapticFeedback)
    }
    
    func testInvertControls_UpdatesValue() {
        // When
        sut.invertControls = true
        
        // Then
        XCTAssertTrue(sut.invertControls)
    }
    
    // MARK: - Graphics Settings Tests
    
    func testHighPerformanceMode_UpdatesValue() {
        // When
        sut.highPerformanceMode = true
        
        // Then
        XCTAssertTrue(sut.highPerformanceMode)
    }
    
    func testParticleEffectsEnabled_UpdatesValue() {
        // When
        sut.particleEffectsEnabled = false
        
        // Then
        XCTAssertFalse(sut.particleEffectsEnabled)
    }
    
    func testGraphicsQuality_UpdatesValue() {
        // When
        sut.graphicsQuality = .high
        
        // Then
        XCTAssertEqual(sut.graphicsQuality, .high)
    }
    
    // MARK: - Privacy Settings Tests
    
    func testAnalyticsEnabled_UpdatesValue() {
        // When
        sut.analyticsEnabled = false
        
        // Then
        XCTAssertFalse(sut.analyticsEnabled)
    }
    
    func testCrashReportingEnabled_UpdatesValue() {
        // When
        sut.crashReportingEnabled = false
        
        // Then
        XCTAssertFalse(sut.crashReportingEnabled)
    }
    
    // MARK: - Game Center Settings Tests
    
    func testGameCenterEnabled_UpdatesValue() {
        // When
        sut.gameCenterEnabled = false
        
        // Then
        XCTAssertFalse(sut.gameCenterEnabled)
    }
    
    func testGameCenterNotifications_UpdatesValue() {
        // When
        sut.gameCenterNotifications = false
        
        // Then
        XCTAssertFalse(sut.gameCenterNotifications)
    }
    
    func testIsGameCenterAuthenticated_ReturnsServiceStatus() {
        // Given
        mockGameCenterService.isAuthenticated = true
        
        // Then
        XCTAssertTrue(sut.isGameCenterAuthenticated)
        
        // When
        mockGameCenterService.isAuthenticated = false
        
        // Then
        XCTAssertFalse(sut.isGameCenterAuthenticated)
    }
    
    func testGameCenterPlayerName_ReturnsServiceName() {
        // Given
        mockGameCenterService.playerDisplayName = "TestPlayer"
        
        // Then
        XCTAssertEqual(sut.gameCenterPlayerName, "TestPlayer")
    }
    
    // MARK: - Settings Persistence Tests
    
    func testSettingsChanges_AreSavedToUserDefaults() {
        // When
        sut.soundVolume = 0.8
        sut.musicEnabled = false
        sut.controlSensitivity = 1.4
        
        // Then
        let savedSettings = UserDefaults.standard.dictionary(forKey: "gameSettings")
        XCTAssertNotNil(savedSettings)
        XCTAssertEqual(savedSettings?["soundVolume"] as? Double, 0.8)
        XCTAssertEqual(savedSettings?["musicEnabled"] as? Bool, false)
        XCTAssertEqual(savedSettings?["controlSensitivity"] as? Double, 1.4)
    }
    
    // MARK: - Reset to Defaults Tests
    
    func testResetToDefaults_RestoresDefaultValues() {
        // Given
        sut.soundVolume = 0.1
        sut.musicVolume = 0.9
        sut.soundEnabled = false
        sut.controlSensitivity = 1.5
        sut.showTutorialTips = false
        sut.highPerformanceMode = true
        sut.graphicsQuality = .ultra
        
        // When
        sut.resetToDefaults()
        
        // Then
        XCTAssertEqual(sut.soundVolume, 0.7, accuracy: 0.01)
        XCTAssertEqual(sut.musicVolume, 0.5, accuracy: 0.01)
        XCTAssertTrue(sut.soundEnabled)
        XCTAssertEqual(sut.controlSensitivity, 1.0, accuracy: 0.01)
        XCTAssertTrue(sut.showTutorialTips)
        XCTAssertFalse(sut.highPerformanceMode)
        XCTAssertEqual(sut.graphicsQuality, .medium)
    }
    
    func testResetToDefaults_AppliesSettingsToServices() {
        // Given
        sut.soundVolume = 0.1
        sut.controlSensitivity = 1.5
        
        // When
        sut.resetToDefaults()
        
        // Then
        XCTAssertEqual(mockAudioService.soundVolume, 0.7, accuracy: 0.01)
        XCTAssertEqual(mockPhysicsService.sensitivity, 1.0, accuracy: 0.01)
    }
    
    func testResetToDefaults_PlaysSoundEffect() {
        // When
        sut.resetToDefaults()
        
        // Then
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("settings_reset"))
    }
    
    // MARK: - Export/Import Settings Tests
    
    func testExportSettings_ReturnsAllSettings() {
        // Given
        sut.soundVolume = 0.8
        sut.musicEnabled = false
        sut.controlSensitivity = 1.3
        sut.graphicsQuality = .high
        
        // When
        let exported = sut.exportSettings()
        
        // Then
        XCTAssertEqual(exported["soundVolume"] as? Double, 0.8)
        XCTAssertEqual(exported["musicEnabled"] as? Bool, false)
        XCTAssertEqual(exported["controlSensitivity"] as? Double, 1.3)
        XCTAssertEqual(exported["graphicsQuality"] as? String, "high")
        XCTAssertTrue(exported.keys.count >= 15) // Should have all settings
    }
    
    func testImportSettings_ValidSettings_ReturnsTrue() {
        // Given
        let settingsToImport = [
            "soundVolume": 0.6,
            "musicVolume": 0.4,
            "soundEnabled": false,
            "controlSensitivity": 1.1,
            "showTutorialTips": false,
            "graphicsQuality": "high"
        ] as [String : Any]
        
        // When
        let result = sut.importSettings(settingsToImport)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(sut.soundVolume, 0.6, accuracy: 0.01)
        XCTAssertEqual(sut.musicVolume, 0.4, accuracy: 0.01)
        XCTAssertFalse(sut.soundEnabled)
        XCTAssertEqual(sut.controlSensitivity, 1.1, accuracy: 0.01)
        XCTAssertFalse(sut.showTutorialTips)
        XCTAssertEqual(sut.graphicsQuality, .high)
    }
    
    func testImportSettings_ClampsValues() {
        // Given
        let settingsToImport = [
            "soundVolume": 2.0, // Should be clamped to 1.0
            "musicVolume": -0.5, // Should be clamped to 0.0
            "controlSensitivity": 3.0 // Should be clamped to 1.5
        ] as [String : Any]
        
        // When
        let result = sut.importSettings(settingsToImport)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(sut.soundVolume, 1.0, accuracy: 0.01)
        XCTAssertEqual(sut.musicVolume, 0.0, accuracy: 0.01)
        XCTAssertEqual(sut.controlSensitivity, 1.5, accuracy: 0.01)
    }
    
    // MARK: - Game Center Authentication Tests
    
    func testAuthenticateGameCenter_WhenEnabled_CallsService() {
        // Given
        sut.gameCenterEnabled = true
        mockGameCenterService.isAuthenticated = false
        
        // When
        sut.authenticateGameCenter()
        
        // Then
        // We can't directly test the authentication call, but we can verify loading state
        XCTAssertTrue(sut.isLoading)
    }
    
    func testAuthenticateGameCenter_WhenDisabled_DoesNothing() {
        // Given
        sut.gameCenterEnabled = false
        
        // When
        sut.authenticateGameCenter()
        
        // Then
        XCTAssertFalse(sut.isLoading)
    }
    
    func testSignOutGameCenter_DisablesGameCenter() {
        // Given
        sut.gameCenterEnabled = true
        
        // When
        sut.signOutGameCenter()
        
        // Then
        XCTAssertFalse(sut.gameCenterEnabled)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("game_center_disconnected"))
    }
    
    // MARK: - Validation Tests
    
    func testValidateSetting_SoundVolume_ValidRange() {
        // Then
        XCTAssertTrue(sut.validateSetting(key: "soundVolume", value: 0.0))
        XCTAssertTrue(sut.validateSetting(key: "soundVolume", value: 0.5))
        XCTAssertTrue(sut.validateSetting(key: "soundVolume", value: 1.0))
        XCTAssertFalse(sut.validateSetting(key: "soundVolume", value: -0.1))
        XCTAssertFalse(sut.validateSetting(key: "soundVolume", value: 1.1))
        XCTAssertFalse(sut.validateSetting(key: "soundVolume", value: "invalid"))
    }
    
    func testValidateSetting_ControlSensitivity_ValidRange() {
        // Then
        XCTAssertTrue(sut.validateSetting(key: "controlSensitivity", value: 0.5))
        XCTAssertTrue(sut.validateSetting(key: "controlSensitivity", value: 1.0))
        XCTAssertTrue(sut.validateSetting(key: "controlSensitivity", value: 1.5))
        XCTAssertFalse(sut.validateSetting(key: "controlSensitivity", value: 0.4))
        XCTAssertFalse(sut.validateSetting(key: "controlSensitivity", value: 1.6))
    }
    
    func testValidateSetting_GraphicsQuality_ValidValues() {
        // Then
        XCTAssertTrue(sut.validateSetting(key: "graphicsQuality", value: "low"))
        XCTAssertTrue(sut.validateSetting(key: "graphicsQuality", value: "medium"))
        XCTAssertTrue(sut.validateSetting(key: "graphicsQuality", value: "high"))
        XCTAssertTrue(sut.validateSetting(key: "graphicsQuality", value: "ultra"))
        XCTAssertFalse(sut.validateSetting(key: "graphicsQuality", value: "invalid"))
        XCTAssertFalse(sut.validateSetting(key: "graphicsQuality", value: 123))
    }
    
    func testValidateSetting_BooleanSettings() {
        // Then
        XCTAssertTrue(sut.validateSetting(key: "soundEnabled", value: true))
        XCTAssertTrue(sut.validateSetting(key: "soundEnabled", value: false))
        XCTAssertFalse(sut.validateSetting(key: "soundEnabled", value: "true"))
        XCTAssertFalse(sut.validateSetting(key: "soundEnabled", value: 1))
    }
    
    func testValidateSetting_UnknownKey_ReturnsFalse() {
        // Then
        XCTAssertFalse(sut.validateSetting(key: "unknownSetting", value: true))
    }
    
    // MARK: - Action Handling Tests
    
    func testHandleUpdateSettingAction_ValidSetting_UpdatesValue() {
        // Given
        let action = UpdateSettingAction(key: "soundVolume", value: 0.8)
        
        // When
        sut.handle(action)
        
        // Then
        XCTAssertEqual(sut.soundVolume, 0.8, accuracy: 0.01)
    }
    
    func testHandleUpdateSettingAction_InvalidValue_SetsError() {
        // Given
        let action = UpdateSettingAction(key: "soundVolume", value: "invalid")
        
        // When
        sut.handle(action)
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Invalid value"))
    }
    
    func testHandleUpdateSettingAction_UnknownSetting_SetsError() {
        // Given
        let action = UpdateSettingAction(key: "unknownSetting", value: true)
        
        // When
        sut.handle(action)
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Unknown setting"))
    }
    
    // MARK: - Computed Properties Tests
    
    func testHasModifiedSettings_DefaultConfiguration_ReturnsFalse() {
        // Then
        XCTAssertFalse(sut.hasModifiedSettings)
    }
    
    func testHasModifiedSettings_ModifiedConfiguration_ReturnsTrue() {
        // When
        sut.soundVolume = 0.8
        
        // Then
        XCTAssertTrue(sut.hasModifiedSettings)
    }
    
    func testAppVersion_ReturnsVersionString() {
        // Then
        XCTAssertNotNil(sut.appVersion)
        XCTAssertFalse(sut.appVersion.isEmpty)
    }
    
    func testBuildNumber_ReturnsBuildString() {
        // Then
        XCTAssertNotNil(sut.buildNumber)
        XCTAssertFalse(sut.buildNumber.isEmpty)
    }
}

// MARK: - GraphicsQuality Tests

extension SettingsViewModelTests {
    
    func testGraphicsQuality_DisplayNames() {
        XCTAssertEqual(GraphicsQuality.low.displayName, "Low")
        XCTAssertEqual(GraphicsQuality.medium.displayName, "Medium")
        XCTAssertEqual(GraphicsQuality.high.displayName, "High")
        XCTAssertEqual(GraphicsQuality.ultra.displayName, "Ultra")
    }
    
    func testGraphicsQuality_Descriptions() {
        XCTAssertTrue(GraphicsQuality.low.description.contains("battery"))
        XCTAssertTrue(GraphicsQuality.medium.description.contains("balanced"))
        XCTAssertTrue(GraphicsQuality.high.description.contains("enhanced"))
        XCTAssertTrue(GraphicsQuality.ultra.description.contains("maximum"))
    }
    
    func testGraphicsQuality_AllCases() {
        let allCases = GraphicsQuality.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.low))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.high))
        XCTAssertTrue(allCases.contains(.ultra))
    }
}// MAR
K: - Additional Edge Case Tests

extension SettingsViewModelTests {
    
    // MARK: - Error Handling Tests
    
    func testSettingsLoad_WithCorruptedData_UsesDefaults() {
        // Given
        let corruptedSettings = [
            "soundVolume": "invalid_string", // Should be Float
            "musicVolume": -5.0, // Invalid range
            "controlSensitivity": 999.0 // Out of range
        ] as [String : Any]
        UserDefaults.standard.set(corruptedSettings, forKey: "gameSettings")
        
        // When
        let newSut = SettingsViewModel(
            audioService: mockAudioService,
            physicsService: mockPhysicsService,
            gameCenterService: mockGameCenterService,
            modelContext: modelContext
        )
        newSut.initialize()
        
        // Then - Should use default values
        XCTAssertEqual(newSut.soundVolume, 0.7, accuracy: 0.01)
        XCTAssertEqual(newSut.musicVolume, 0.5, accuracy: 0.01)
        XCTAssertEqual(newSut.controlSensitivity, 1.0, accuracy: 0.01)
    }
    
    func testSettingsSave_WithNilPlayerData_HandlesGracefully() {
        // Given
        sut.playerData = nil
        sut.soundVolume = 0.8
        
        // When
        sut.saveSettings()
        
        // Then - Should not crash
        XCTAssertTrue(true)
    }
    
    func testVolumeSettings_WithExtremeValues_ClampsCorrectly() {
        // When
        sut.soundVolume = -1.0 // Below minimum
        sut.musicVolume = 2.0 // Above maximum
        
        // Then
        XCTAssertGreaterThanOrEqual(sut.soundVolume, 0.0)
        XCTAssertLessThanOrEqual(sut.soundVolume, 1.0)
        XCTAssertGreaterThanOrEqual(sut.musicVolume, 0.0)
        XCTAssertLessThanOrEqual(sut.musicVolume, 1.0)
    }
    
    func testControlSensitivity_WithExtremeValues_ClampsCorrectly() {
        // When
        sut.controlSensitivity = -1.0 // Below minimum
        
        // Then
        XCTAssertGreaterThanOrEqual(sut.controlSensitivity, 0.1)
        
        // When
        sut.controlSensitivity = 10.0 // Above maximum
        
        // Then
        XCTAssertLessThanOrEqual(sut.controlSensitivity, 3.0)
    }
    
    // MARK: - Performance Tests
    
    func testMultipleSettingsChanges_PerformanceTest() {
        // When
        measure {
            for i in 0..<1000 {
                sut.soundVolume = Float(i % 100) / 100.0
                sut.musicVolume = Float((i + 50) % 100) / 100.0
                sut.controlSensitivity = 0.5 + Float(i % 25) / 10.0
            }
        }
        
        // Then
        XCTAssertNotNil(sut.soundVolume)
    }
    
    func testSettingsSaveLoad_PerformanceTest() {
        // When
        measure {
            for _ in 0..<100 {
                sut.saveSettings()
                sut.loadSettings()
            }
        }
        
        // Then
        XCTAssertNotNil(sut.soundVolume)
    }
    
    // MARK: - Memory Management Tests
    
    func testCleanup_ReleasesResources() {
        // Given
        sut.soundVolume = 0.8
        sut.musicVolume = 0.6
        
        // When
        sut.cleanup()
        
        // Then - Should not crash and should clean up properly
        XCTAssertTrue(true)
    }
    
    func testMultipleInitialization_DoesNotLeak() {
        // When
        for _ in 0..<10 {
            let viewModel = SettingsViewModel(
                audioService: mockAudioService,
                physicsService: mockPhysicsService,
                gameCenterService: mockGameCenterService,
                modelContext: modelContext
            )
            viewModel.initialize()
            viewModel.cleanup()
        }
        
        // Then - Should not crash or leak memory
        XCTAssertTrue(true)
    }
    
    // MARK: - Settings Persistence Tests
    
    func testSettingsPersistence_AcrossAppLaunches() {
        // Given
        sut.soundVolume = 0.8
        sut.musicVolume = 0.3
        sut.controlSensitivity = 1.5
        sut.showTutorialTips = false
        sut.useHapticFeedback = false
        
        // When
        sut.saveSettings()
        
        // Create new instance (simulating app restart)
        let newSut = SettingsViewModel(
            audioService: mockAudioService,
            physicsService: mockPhysicsService,
            gameCenterService: mockGameCenterService,
            modelContext: modelContext
        )
        newSut.initialize()
        
        // Then
        XCTAssertEqual(newSut.soundVolume, 0.8, accuracy: 0.01)
        XCTAssertEqual(newSut.musicVolume, 0.3, accuracy: 0.01)
        XCTAssertEqual(newSut.controlSensitivity, 1.5, accuracy: 0.01)
        XCTAssertFalse(newSut.showTutorialTips)
        XCTAssertFalse(newSut.useHapticFeedback)
    }
    
    func testSettingsReset_RestoresDefaults() {
        // Given
        sut.soundVolume = 0.2
        sut.musicVolume = 0.1
        sut.controlSensitivity = 2.0
        sut.showTutorialTips = false
        sut.useHapticFeedback = false
        sut.invertControls = true
        
        // When
        sut.resetToDefaults()
        
        // Then
        XCTAssertEqual(sut.soundVolume, 0.7, accuracy: 0.01)
        XCTAssertEqual(sut.musicVolume, 0.5, accuracy: 0.01)
        XCTAssertEqual(sut.controlSensitivity, 1.0, accuracy: 0.01)
        XCTAssertTrue(sut.showTutorialTips)
        XCTAssertTrue(sut.useHapticFeedback)
        XCTAssertFalse(sut.invertControls)
    }
    
    // MARK: - Service Integration Tests
    
    func testAudioServiceIntegration_UpdatesImmediately() {
        // When
        sut.soundVolume = 0.9
        
        // Then
        XCTAssertEqual(mockAudioService.soundVolume, 0.9, accuracy: 0.01)
        
        // When
        sut.musicVolume = 0.2
        
        // Then
        XCTAssertEqual(mockAudioService.musicVolume, 0.2, accuracy: 0.01)
    }
    
    func testPhysicsServiceIntegration_UpdatesImmediately() {
        // When
        sut.controlSensitivity = 1.8
        
        // Then
        XCTAssertEqual(mockPhysicsService.sensitivity, 1.8, accuracy: 0.01)
    }
    
    func testGameCenterServiceIntegration_ReflectsState() {
        // Given
        mockGameCenterService.isAuthenticated = true
        mockGameCenterService.playerDisplayName = "TestPlayer123"
        
        // When
        sut.refreshGameCenterStatus()
        
        // Then
        XCTAssertTrue(sut.isGameCenterAuthenticated)
        XCTAssertEqual(sut.gameCenterPlayerName, "TestPlayer123")
    }
    
    // MARK: - Graphics Settings Tests
    
    func testGraphicsQuality_UpdatesCorrectly() {
        // When
        sut.graphicsQuality = .high
        
        // Then
        XCTAssertEqual(sut.graphicsQuality, .high)
    }
    
    func testParticleEffects_ToggleCorrectly() {
        // Given
        let initialState = sut.particleEffectsEnabled
        
        // When
        sut.particleEffectsEnabled = !initialState
        
        // Then
        XCTAssertNotEqual(sut.particleEffectsEnabled, initialState)
    }
    
    func testHighPerformanceMode_AffectsOtherSettings() {
        // When
        sut.highPerformanceMode = true
        
        // Then
        XCTAssertTrue(sut.highPerformanceMode)
        // High performance mode might disable particle effects
        XCTAssertFalse(sut.particleEffectsEnabled)
        XCTAssertEqual(sut.graphicsQuality, .low)
    }
    
    // MARK: - Privacy Settings Tests
    
    func testAnalyticsEnabled_ToggleCorrectly() {
        // Given
        let initialState = sut.analyticsEnabled
        
        // When
        sut.analyticsEnabled = !initialState
        
        // Then
        XCTAssertNotEqual(sut.analyticsEnabled, initialState)
    }
    
    func testCrashReporting_ToggleCorrectly() {
        // Given
        let initialState = sut.crashReportingEnabled
        
        // When
        sut.crashReportingEnabled = !initialState
        
        // Then
        XCTAssertNotEqual(sut.crashReportingEnabled, initialState)
    }
    
    // MARK: - Game Center Settings Tests
    
    func testGameCenterEnabled_ToggleCorrectly() {
        // Given
        let initialState = sut.gameCenterEnabled
        
        // When
        sut.gameCenterEnabled = !initialState
        
        // Then
        XCTAssertNotEqual(sut.gameCenterEnabled, initialState)
    }
    
    func testGameCenterNotifications_ToggleCorrectly() {
        // Given
        let initialState = sut.gameCenterNotifications
        
        // When
        sut.gameCenterNotifications = !initialState
        
        // Then
        XCTAssertNotEqual(sut.gameCenterNotifications, initialState)
    }
    
    func testGameCenterDisconnect_HandlesCorrectly() {
        // Given
        sut.gameCenterEnabled = true
        mockGameCenterService.isAuthenticated = true
        
        // When
        sut.disconnectGameCenter()
        
        // Then
        XCTAssertFalse(sut.gameCenterEnabled)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("game_center_disconnected"))
    }
    
    // MARK: - Validation Tests
    
    func testSettingsValidation_ValidatesRanges() {
        // When
        let isValid = sut.validateSettings()
        
        // Then
        XCTAssertTrue(isValid)
        
        // When - Set invalid values
        sut.soundVolume = -1.0
        sut.controlSensitivity = 999.0
        let isInvalid = sut.validateSettings()
        
        // Then
        XCTAssertFalse(isInvalid)
    }
    
    func testSettingsValidation_FixesInvalidValues() {
        // Given
        sut.soundVolume = -1.0
        sut.musicVolume = 2.0
        sut.controlSensitivity = -0.5
        
        // When
        sut.fixInvalidSettings()
        
        // Then
        XCTAssertGreaterThanOrEqual(sut.soundVolume, 0.0)
        XCTAssertLessThanOrEqual(sut.musicVolume, 1.0)
        XCTAssertGreaterThanOrEqual(sut.controlSensitivity, 0.1)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentSettingsChanges_ThreadSafe() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent changes complete")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.sut.soundVolume = Float(i) / 10.0
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then
        XCTAssertGreaterThanOrEqual(sut.soundVolume, 0.0)
        XCTAssertLessThanOrEqual(sut.soundVolume, 1.0)
    }
}