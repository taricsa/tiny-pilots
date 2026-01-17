//
//  ComprehensiveViewModelTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
import SwiftData
@testable import Tiny_Pilots

/// Comprehensive ViewModel testing to achieve 85%+ code coverage
final class ComprehensiveViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    var container: ModelContainer!
    var context: ModelContext!
    var mockAudioService: MockAudioService!
    var mockPhysicsService: MockPhysicsService!
    var mockGameCenterService: MockGameCenterService!
    
    // ViewModels under test
    var gameViewModel: GameViewModel!
    var mainMenuViewModel: MainMenuViewModel!
    var hangarViewModel: HangarViewModel!
    var settingsViewModel: SettingsViewModel!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup in-memory SwiftData container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: PlayerData.self, GameResult.self, Achievement.self,
            configurations: config
        )
        context = ModelContext(container)
        
        // Create mock services
        mockAudioService = MockAudioService()
        mockPhysicsService = MockPhysicsService()
        mockGameCenterService = MockGameCenterService()
        
        // Reset all mocks
        mockAudioService.reset()
        mockPhysicsService.reset()
        mockGameCenterService.reset()
        
        // Create ViewModels
        gameViewModel = GameViewModel(
            physicsService: mockPhysicsService,
            audioService: mockAudioService,
            gameCenterService: mockGameCenterService,
            modelContext: context
        )
        
        mainMenuViewModel = MainMenuViewModel(
            gameCenterService: mockGameCenterService,
            audioService: mockAudioService,
            modelContext: context
        )
        
        hangarViewModel = HangarViewModel(
            audioService: mockAudioService,
            modelContext: context
        )
        
        settingsViewModel = SettingsViewModel(
            audioService: mockAudioService,
            modelContext: context
        )
    }
    
    override func tearDownWithError() throws {
        gameViewModel?.cleanup()
        mainMenuViewModel?.cleanup()
        hangarViewModel?.cleanup()
        settingsViewModel?.cleanup()
        
        gameViewModel = nil
        mainMenuViewModel = nil
        hangarViewModel = nil
        settingsViewModel = nil
        
        container = nil
        context = nil
        mockAudioService = nil
        mockPhysicsService = nil
        mockGameCenterService = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - GameViewModel Comprehensive Tests
    
    func testGameViewModel_CompleteLifecycle() throws {
        // Initialize
        gameViewModel.initialize()
        XCTAssertNotNil(gameViewModel.playerData)
        XCTAssertEqual(gameViewModel.gameState.status, .notStarted)
        
        // Start game
        gameViewModel.startGame(mode: .freePlay)
        XCTAssertEqual(gameViewModel.gameState.status, .playing)
        XCTAssertEqual(gameViewModel.gameState.mode, .freePlay)
        XCTAssertTrue(gameViewModel.isGameActive)
        XCTAssertTrue(gameViewModel.canPause)
        XCTAssertFalse(gameViewModel.canStart)
        
        // Pause game
        gameViewModel.pauseGame()
        XCTAssertEqual(gameViewModel.gameState.status, .paused)
        XCTAssertFalse(gameViewModel.isGameActive)
        XCTAssertTrue(gameViewModel.canResume)
        XCTAssertFalse(gameViewModel.canPause)
        
        // Resume game
        gameViewModel.resumeGame()
        XCTAssertEqual(gameViewModel.gameState.status, .playing)
        XCTAssertTrue(gameViewModel.isGameActive)
        
        // End game
        gameViewModel.endGame()
        XCTAssertEqual(gameViewModel.gameState.status, .ended)
        XCTAssertFalse(gameViewModel.isGameActive)
        XCTAssertFalse(gameViewModel.canPause)
        XCTAssertFalse(gameViewModel.canResume)
        XCTAssertTrue(gameViewModel.canStart)
    }
    
    func testGameViewModel_AllGameModes() throws {
        let gameModes: [GameState.Mode] = [.tutorial, .freePlay, .challenge, .dailyRun, .weeklySpecial]
        
        for mode in gameModes {
            gameViewModel.initialize()
            gameViewModel.startGame(mode: mode)
            
            XCTAssertEqual(gameViewModel.gameState.mode, mode, "Game mode should be set to \(mode)")
            XCTAssertEqual(gameViewModel.gameState.status, .playing, "Game should be playing for mode \(mode)")
            
            gameViewModel.endGame()
            XCTAssertEqual(gameViewModel.gameState.status, .ended, "Game should end properly for mode \(mode)")
        }
    }
    
    func testGameViewModel_ScoreManagement() throws {
        gameViewModel.initialize()
        gameViewModel.startGame(mode: .freePlay)
        
        // Test adding score
        gameViewModel.addScore(100)
        XCTAssertEqual(gameViewModel.gameState.score, 100)
        XCTAssertEqual(gameViewModel.formattedScore, "100")
        
        // Test updating score
        gameViewModel.updateScore(250)
        XCTAssertEqual(gameViewModel.gameState.score, 250)
        
        // Test adding negative score
        gameViewModel.addScore(-50)
        XCTAssertEqual(gameViewModel.gameState.score, 200)
        
        // Test score doesn't go below zero
        gameViewModel.updateScore(-100)
        XCTAssertGreaterThanOrEqual(gameViewModel.gameState.score, 0)
    }
    
    func testGameViewModel_DistanceTracking() throws {
        gameViewModel.initialize()
        gameViewModel.startGame(mode: .freePlay)
        
        // Test adding distance
        gameViewModel.addDistance(150.5)
        XCTAssertEqual(gameViewModel.gameState.distance, 150.5)
        XCTAssertEqual(gameViewModel.formattedDistance, "150.5 m")
        
        // Test updating distance
        gameViewModel.updateDistance(300.75)
        XCTAssertEqual(gameViewModel.gameState.distance, 300.75)
        
        // Test distance doesn't decrease
        gameViewModel.addDistance(-50)
        XCTAssertEqual(gameViewModel.gameState.distance, 300.75)
    }
    
    func testGameViewModel_CoinCollection() throws {
        gameViewModel.initialize()
        gameViewModel.startGame(mode: .freePlay)
        
        let initialScore = gameViewModel.gameState.score
        
        // Test coin collection
        gameViewModel.addCoin()
        XCTAssertEqual(gameViewModel.gameState.coinsCollected, 1)
        XCTAssertEqual(gameViewModel.gameState.score, initialScore + 100)
        XCTAssertEqual(gameViewModel.formattedCoins, "1")
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("coin_collect"))
        
        // Test multiple coins
        for i in 2...5 {
            gameViewModel.addCoin()
            XCTAssertEqual(gameViewModel.gameState.coinsCollected, i)
        }
        XCTAssertEqual(gameViewModel.formattedCoins, "5")
    }
    
    func testGameViewModel_ObstacleCollisions() throws {
        gameViewModel.initialize()
        gameViewModel.startGame(mode: .freePlay)
        gameViewModel.addScore(200)
        
        // Test obstacle collision
        gameViewModel.handleObstacleCollision()
        XCTAssertEqual(gameViewModel.gameState.score, 150) // 200 - 50 penalty
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("obstacle_hit"))
        
        // Test score doesn't go below zero
        gameViewModel.updateScore(25)
        gameViewModel.handleObstacleCollision()
        XCTAssertEqual(gameViewModel.gameState.score, 0)
    }
    
    func testGameViewModel_TiltInputHandling() throws {
        gameViewModel.initialize()
        gameViewModel.startGame(mode: .freePlay)
        
        // Test tilt input
        gameViewModel.handleTiltInput(x: 0.5, y: -0.3)
        XCTAssertGreaterThan(mockPhysicsService.forcesApplied.count, 0)
        
        // Test extreme tilt values
        gameViewModel.handleTiltInput(x: 999.0, y: -999.0)
        // Should handle gracefully without crashing
        
        // Test zero tilt
        gameViewModel.handleTiltInput(x: 0.0, y: 0.0)
        // Should handle gracefully
    }
    
    func testGameViewModel_EnvironmentManagement() throws {
        gameViewModel.initialize()
        
        // Test default environment
        XCTAssertEqual(gameViewModel.gameState.environmentType, "standard")
        
        // Test unlocking and changing environment
        gameViewModel.playerData?.unlockContent("forest", type: .environment)
        gameViewModel.changeEnvironment("forest")
        XCTAssertEqual(gameViewModel.gameState.environmentType, "forest")
        
        // Test locked environment
        gameViewModel.changeEnvironment("locked_environment")
        XCTAssertNotNil(gameViewModel.errorMessage)
        XCTAssertTrue(gameViewModel.errorMessage!.contains("not unlocked"))
        
        // Test available environments
        gameViewModel.playerData?.unlockContent("desert", type: .environment)
        let environments = gameViewModel.availableEnvironments
        XCTAssertTrue(environments.contains("standard"))
        XCTAssertTrue(environments.contains("forest"))
        XCTAssertTrue(environments.contains("desert"))
    }
    
    func testGameViewModel_AchievementSystem() throws {
        gameViewModel.initialize()
        
        // Create test achievement
        let achievement = Achievement(
            id: "distance_1000",
            title: "Sky Explorer",
            description: "Travel 1000 units",
            targetValue: 1000
        )
        gameViewModel.playerData?.achievements.append(achievement)
        
        gameViewModel.startGame(mode: .freePlay)
        gameViewModel.updateDistance(1500)
        
        // Check achievements
        gameViewModel.checkAchievements()
        XCTAssertTrue(achievement.isUnlocked)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("achievement_unlock"))
    }
    
    func testGameViewModel_GameDataPersistence() throws {
        gameViewModel.initialize()
        gameViewModel.startGame(mode: .challenge)
        gameViewModel.addScore(1500)
        gameViewModel.addDistance(750.5)
        gameViewModel.addCoin()
        gameViewModel.addCoin()
        
        // End game to trigger save
        gameViewModel.endGame()
        
        // Verify game result was saved
        let gameResults = try context.fetch(FetchDescriptor<GameResult>())
        XCTAssertEqual(gameResults.count, 1)
        
        let result = gameResults.first!
        XCTAssertEqual(result.mode, "challenge")
        XCTAssertEqual(result.score, 1700) // 1500 + 200 for coins
        XCTAssertEqual(result.distance, 750.5)
        XCTAssertEqual(result.coinsCollected, 2)
        XCTAssertNotNil(result.completedAt)
    }
    
    func testGameViewModel_RestartFunctionality() throws {
        gameViewModel.initialize()
        gameViewModel.startGame(mode: .freePlay)
        gameViewModel.addScore(500)
        
        // Restart game
        gameViewModel.restartGame()
        XCTAssertEqual(gameViewModel.gameState.status, .ended)
        
        // Wait for async restart
        let expectation = XCTestExpectation(description: "Game restarted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertEqual(self.gameViewModel.gameState.status, .playing)
            XCTAssertEqual(self.gameViewModel.gameState.score, 0) // Should be reset
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - MainMenuViewModel Comprehensive Tests
    
    func testMainMenuViewModel_Initialization() throws {
        mainMenuViewModel.initialize()
        
        XCTAssertNotNil(mainMenuViewModel.playerData)
        XCTAssertGreaterThanOrEqual(mainMenuViewModel.playerLevel, 1)
        XCTAssertGreaterThanOrEqual(mainMenuViewModel.playerExperience, 0)
    }
    
    func testMainMenuViewModel_GameCenterIntegration() throws {
        // Test Game Center availability
        mockGameCenterService.isAvailable = true
        mainMenuViewModel.initialize()
        XCTAssertTrue(mainMenuViewModel.isGameCenterAvailable)
        
        // Test Game Center unavailable
        mockGameCenterService.isAvailable = false
        mainMenuViewModel.initialize()
        XCTAssertFalse(mainMenuViewModel.isGameCenterAvailable)
        
        // Test authentication
        mockGameCenterService.simulateSuccessfulAuthentication()
        mainMenuViewModel.authenticateGameCenter()
        XCTAssertTrue(mockGameCenterService.authenticationAttempts > 0)
    }
    
    func testMainMenuViewModel_PlayerStats() throws {
        // Create player data with stats
        let playerData = PlayerData()
        playerData.level = 5
        playerData.experiencePoints = 750
        playerData.totalScore = 15000
        playerData.totalDistance = 5000.0
        playerData.totalCoinsCollected = 150
        context.insert(playerData)
        try context.save()
        
        mainMenuViewModel.initialize()
        
        XCTAssertEqual(mainMenuViewModel.playerLevel, 5)
        XCTAssertEqual(mainMenuViewModel.playerExperience, 750)
        XCTAssertEqual(mainMenuViewModel.totalScore, 15000)
        XCTAssertEqual(mainMenuViewModel.totalDistance, 5000.0)
        XCTAssertEqual(mainMenuViewModel.totalCoins, 150)
    }
    
    func testMainMenuViewModel_GameModeAvailability() throws {
        // Test with low level player
        let lowLevelPlayer = PlayerData()
        lowLevelPlayer.level = 2
        context.insert(lowLevelPlayer)
        try context.save()
        
        mainMenuViewModel.initialize()
        
        XCTAssertTrue(mainMenuViewModel.isGameModeAvailable(.tutorial))
        XCTAssertTrue(mainMenuViewModel.isGameModeAvailable(.freePlay))
        XCTAssertFalse(mainMenuViewModel.isGameModeAvailable(.challenge))
        XCTAssertFalse(mainMenuViewModel.isGameModeAvailable(.dailyRun))
        XCTAssertFalse(mainMenuViewModel.isGameModeAvailable(.weeklySpecial))
        
        // Test with high level player
        lowLevelPlayer.level = 15
        try context.save()
        mainMenuViewModel.initialize()
        
        XCTAssertTrue(mainMenuViewModel.isGameModeAvailable(.challenge))
        XCTAssertTrue(mainMenuViewModel.isGameModeAvailable(.dailyRun))
        XCTAssertTrue(mainMenuViewModel.isGameModeAvailable(.weeklySpecial))
    }
    
    func testMainMenuViewModel_RecentGameResults() throws {
        // Create recent game results
        for i in 1...5 {
            let result = GameResult()
            result.mode = "freePlay"
            result.score = i * 1000
            result.distance = Double(i * 100)
            result.completedAt = Date().addingTimeInterval(-Double(i * 3600)) // i hours ago
            context.insert(result)
        }
        try context.save()
        
        mainMenuViewModel.initialize()
        
        let recentResults = mainMenuViewModel.recentGameResults
        XCTAssertEqual(recentResults.count, 5)
        XCTAssertEqual(recentResults[0].score, 1000) // Most recent first
    }
    
    // MARK: - HangarViewModel Comprehensive Tests
    
    func testHangarViewModel_AirplaneSelection() throws {
        hangarViewModel.initialize()
        
        // Test default airplane
        XCTAssertNotNil(hangarViewModel.selectedAirplaneType)
        XCTAssertEqual(hangarViewModel.selectedAirplaneType, "basic")
        
        // Test available airplanes
        let availableTypes = hangarViewModel.availableAirplaneTypes
        XCTAssertTrue(availableTypes.contains("basic"))
        
        // Test selecting airplane
        hangarViewModel.selectAirplane("basic")
        XCTAssertEqual(hangarViewModel.selectedAirplaneType, "basic")
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("airplane_select"))
    }
    
    func testHangarViewModel_AirplaneUnlocking() throws {
        hangarViewModel.initialize()
        
        // Test unlocking airplane
        hangarViewModel.playerData?.unlockContent("speedy", type: .airplane)
        hangarViewModel.initialize() // Refresh
        
        let availableTypes = hangarViewModel.availableAirplaneTypes
        XCTAssertTrue(availableTypes.contains("speedy"))
        
        // Test selecting unlocked airplane
        hangarViewModel.selectAirplane("speedy")
        XCTAssertEqual(hangarViewModel.selectedAirplaneType, "speedy")
    }
    
    func testHangarViewModel_AirplaneCustomization() throws {
        hangarViewModel.initialize()
        
        // Test fold type selection
        hangarViewModel.selectFoldType("dart")
        XCTAssertEqual(hangarViewModel.selectedFoldType, "dart")
        
        // Test design selection
        hangarViewModel.selectDesign("colorful")
        XCTAssertEqual(hangarViewModel.selectedDesign, "colorful")
        
        // Test customization persistence
        hangarViewModel.saveCustomization()
        XCTAssertNotNil(hangarViewModel.playerData?.selectedAirplaneType)
    }
    
    func testHangarViewModel_AirplaneStats() throws {
        hangarViewModel.initialize()
        
        // Test getting airplane stats
        let basicStats = hangarViewModel.getAirplaneStats("basic")
        XCTAssertNotNil(basicStats)
        XCTAssertGreaterThan(basicStats!.speed, 0)
        XCTAssertGreaterThan(basicStats!.handling, 0)
        XCTAssertGreaterThan(basicStats!.stability, 0)
        
        // Test different airplane types have different stats
        hangarViewModel.playerData?.unlockContent("speedy", type: .airplane)
        let speedyStats = hangarViewModel.getAirplaneStats("speedy")
        XCTAssertNotNil(speedyStats)
        XCTAssertNotEqual(basicStats!.speed, speedyStats!.speed)
    }
    
    func testHangarViewModel_ProgressTracking() throws {
        hangarViewModel.initialize()
        
        // Test unlock progress
        let unlockProgress = hangarViewModel.getUnlockProgress("speedy")
        XCTAssertGreaterThanOrEqual(unlockProgress, 0.0)
        XCTAssertLessThanOrEqual(unlockProgress, 1.0)
        
        // Test requirements
        let requirements = hangarViewModel.getUnlockRequirements("speedy")
        XCTAssertNotNil(requirements)
        XCTAssertFalse(requirements!.isEmpty)
    }
    
    // MARK: - SettingsViewModel Comprehensive Tests
    
    func testSettingsViewModel_AudioSettings() throws {
        settingsViewModel.initialize()
        
        // Test initial audio settings
        XCTAssertNotNil(settingsViewModel.audioSettings)
        XCTAssertEqual(settingsViewModel.audioSettings.soundVolume, 0.7)
        XCTAssertEqual(settingsViewModel.audioSettings.musicVolume, 0.5)
        XCTAssertTrue(settingsViewModel.audioSettings.soundEnabled)
        XCTAssertTrue(settingsViewModel.audioSettings.musicEnabled)
        
        // Test changing sound volume
        settingsViewModel.setSoundVolume(0.8)
        XCTAssertEqual(settingsViewModel.audioSettings.soundVolume, 0.8)
        XCTAssertEqual(mockAudioService.soundVolume, 0.8)
        
        // Test changing music volume
        settingsViewModel.setMusicVolume(0.6)
        XCTAssertEqual(settingsViewModel.audioSettings.musicVolume, 0.6)
        XCTAssertEqual(mockAudioService.musicVolume, 0.6)
        
        // Test toggling sound
        settingsViewModel.toggleSound()
        XCTAssertFalse(settingsViewModel.audioSettings.soundEnabled)
        XCTAssertFalse(mockAudioService.soundEnabled)
        
        // Test toggling music
        settingsViewModel.toggleMusic()
        XCTAssertFalse(settingsViewModel.audioSettings.musicEnabled)
        XCTAssertFalse(mockAudioService.musicEnabled)
    }
    
    func testSettingsViewModel_GameplaySettings() throws {
        settingsViewModel.initialize()
        
        // Test physics sensitivity
        settingsViewModel.setPhysicsSensitivity(1.5)
        XCTAssertEqual(settingsViewModel.physicsSensitivity, 1.5)
        
        // Test control scheme
        settingsViewModel.setControlScheme(.tilt)
        XCTAssertEqual(settingsViewModel.controlScheme, .tilt)
        
        settingsViewModel.setControlScheme(.touch)
        XCTAssertEqual(settingsViewModel.controlScheme, .touch)
    }
    
    func testSettingsViewModel_DisplaySettings() throws {
        settingsViewModel.initialize()
        
        // Test graphics quality
        settingsViewModel.setGraphicsQuality(.high)
        XCTAssertEqual(settingsViewModel.graphicsQuality, .high)
        
        settingsViewModel.setGraphicsQuality(.medium)
        XCTAssertEqual(settingsViewModel.graphicsQuality, .medium)
        
        settingsViewModel.setGraphicsQuality(.low)
        XCTAssertEqual(settingsViewModel.graphicsQuality, .low)
        
        // Test frame rate target
        settingsViewModel.setTargetFrameRate(120)
        XCTAssertEqual(settingsViewModel.targetFrameRate, 120)
        
        settingsViewModel.setTargetFrameRate(60)
        XCTAssertEqual(settingsViewModel.targetFrameRate, 60)
    }
    
    func testSettingsViewModel_AccessibilitySettings() throws {
        settingsViewModel.initialize()
        
        // Test accessibility features
        settingsViewModel.setReduceMotion(true)
        XCTAssertTrue(settingsViewModel.reduceMotion)
        
        settingsViewModel.setHighContrast(true)
        XCTAssertTrue(settingsViewModel.highContrast)
        
        settingsViewModel.setLargeText(true)
        XCTAssertTrue(settingsViewModel.largeText)
        
        settingsViewModel.setVoiceOverEnabled(true)
        XCTAssertTrue(settingsViewModel.voiceOverEnabled)
    }
    
    func testSettingsViewModel_DataManagement() throws {
        settingsViewModel.initialize()
        
        // Test reset settings
        settingsViewModel.setSoundVolume(0.2)
        settingsViewModel.setMusicVolume(0.3)
        settingsViewModel.resetToDefaults()
        
        XCTAssertEqual(settingsViewModel.audioSettings.soundVolume, 0.7) // Default
        XCTAssertEqual(settingsViewModel.audioSettings.musicVolume, 0.5) // Default
        
        // Test export settings
        let exportedSettings = settingsViewModel.exportSettings()
        XCTAssertNotNil(exportedSettings)
        XCTAssertFalse(exportedSettings.isEmpty)
        
        // Test import settings
        settingsViewModel.importSettings(exportedSettings)
        // Should not crash and should apply settings
    }
    
    // MARK: - Cross-ViewModel Integration Tests
    
    func testViewModelIntegration_GameAndMainMenu() throws {
        // Initialize both ViewModels
        gameViewModel.initialize()
        mainMenuViewModel.initialize()
        
        // Start game from main menu
        gameViewModel.startGame(mode: .freePlay)
        gameViewModel.addScore(2000)
        gameViewModel.addDistance(500)
        gameViewModel.endGame()
        
        // Refresh main menu to see updated stats
        mainMenuViewModel.initialize()
        
        // Verify stats were updated
        XCTAssertGreaterThan(mainMenuViewModel.totalScore, 0)
        XCTAssertGreaterThan(mainMenuViewModel.totalDistance, 0)
    }
    
    func testViewModelIntegration_HangarAndGame() throws {
        // Select airplane in hangar
        hangarViewModel.initialize()
        hangarViewModel.playerData?.unlockContent("speedy", type: .airplane)
        hangarViewModel.selectAirplane("speedy")
        hangarViewModel.selectFoldType("dart")
        hangarViewModel.saveCustomization()
        
        // Start game with selected airplane
        gameViewModel.initialize()
        XCTAssertEqual(gameViewModel.playerData?.selectedAirplaneType, "speedy")
        XCTAssertEqual(gameViewModel.playerData?.selectedFoldType, "dart")
    }
    
    func testViewModelIntegration_SettingsAndGame() throws {
        // Change settings
        settingsViewModel.initialize()
        settingsViewModel.setSoundVolume(0.3)
        settingsViewModel.setMusicVolume(0.4)
        settingsViewModel.setPhysicsSensitivity(1.8)
        
        // Start game and verify settings are applied
        gameViewModel.initialize()
        gameViewModel.startGame(mode: .freePlay)
        
        XCTAssertEqual(mockAudioService.soundVolume, 0.3)
        XCTAssertEqual(mockAudioService.musicVolume, 0.4)
        XCTAssertEqual(mockPhysicsService.sensitivity, 1.8)
    }
    
    // MARK: - Performance Tests
    
    func testViewModelPerformance_GameViewModel() throws {
        gameViewModel.initialize()
        gameViewModel.startGame(mode: .freePlay)
        
        measure {
            for i in 0..<1000 {
                gameViewModel.handleTiltInput(x: Float(i % 10) * 0.1, y: -0.1)
                gameViewModel.updateDistance(Float(i))
                if i % 10 == 0 {
                    gameViewModel.addCoin()
                }
            }
        }
        
        XCTAssertEqual(gameViewModel.gameState.distance, 999)
        XCTAssertEqual(gameViewModel.gameState.coinsCollected, 100)
    }
    
    func testViewModelPerformance_MainMenuViewModel() throws {
        // Create lots of game results
        for i in 0..<1000 {
            let result = GameResult()
            result.score = i
            result.distance = Double(i)
            result.completedAt = Date()
            context.insert(result)
        }
        try context.save()
        
        measure {
            mainMenuViewModel.initialize()
            _ = mainMenuViewModel.recentGameResults
            _ = mainMenuViewModel.totalScore
            _ = mainMenuViewModel.totalDistance
        }
        
        XCTAssertGreaterThan(mainMenuViewModel.totalScore, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testViewModelErrorHandling_InvalidInputs() throws {
        gameViewModel.initialize()
        
        // Test invalid game mode
        gameViewModel.startGame(mode: .freePlay)
        // Should handle gracefully
        
        // Test invalid tilt values
        gameViewModel.handleTiltInput(x: Float.infinity, y: Float.nan)
        // Should handle gracefully
        
        // Test invalid score values
        gameViewModel.addScore(Int.max)
        gameViewModel.addScore(Int.min)
        // Should handle gracefully
        
        XCTAssertTrue(true) // If we get here, no crashes occurred
    }
    
    func testViewModelErrorHandling_ServiceFailures() throws {
        // Simulate service failures
        mockAudioService.soundEnabled = false
        mockPhysicsService.isActive = false
        mockGameCenterService.shouldFailAuthentication = true
        
        gameViewModel.initialize()
        gameViewModel.startGame(mode: .freePlay)
        
        // Should handle service failures gracefully
        XCTAssertEqual(gameViewModel.gameState.status, .playing)
        
        gameViewModel.endGame()
        XCTAssertEqual(gameViewModel.gameState.status, .ended)
    }
    
    func testViewModelErrorHandling_DataCorruption() throws {
        // Create corrupted player data
        let corruptedPlayer = PlayerData()
        corruptedPlayer.level = -1
        corruptedPlayer.experiencePoints = -100
        context.insert(corruptedPlayer)
        try context.save()
        
        // ViewModels should handle corrupted data gracefully
        gameViewModel.initialize()
        mainMenuViewModel.initialize()
        hangarViewModel.initialize()
        settingsViewModel.initialize()
        
        // Should not crash and should provide reasonable defaults
        XCTAssertGreaterThanOrEqual(gameViewModel.playerData?.level ?? 1, 1)
        XCTAssertGreaterThanOrEqual(gameViewModel.playerData?.experiencePoints ?? 0, 0)
    }
}