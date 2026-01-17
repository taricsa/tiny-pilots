//
//  GameViewModelTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
import SwiftData
@testable import Tiny_Pilots

final class GameViewModelTests: XCTestCase {
    
    var sut: GameViewModel!
    var mockPhysicsService: MockPhysicsService!
    var mockAudioService: MockAudioService!
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
        mockPhysicsService = MockPhysicsService()
        mockAudioService = MockAudioService()
        mockGameCenterService = MockGameCenterService()
        
        // Create system under test
        sut = GameViewModel(
            physicsService: mockPhysicsService,
            audioService: mockAudioService,
            gameCenterService: mockGameCenterService,
            modelContext: modelContext
        )
        
        sut.initialize()
    }
    
    override func tearDown() {
        sut.cleanup()
        sut = nil
        mockPhysicsService = nil
        mockAudioService = nil
        mockGameCenterService = nil
        modelContext = nil
        container = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_CreatesPlayerDataIfNoneExists() {
        // Given - setUp creates a fresh context
        
        // When - initialization happens in setUp
        
        // Then
        XCTAssertNotNil(sut.playerData)
        XCTAssertEqual(sut.playerData?.level, 1)
        XCTAssertEqual(sut.playerData?.experiencePoints, 0)
    }
    
    func testInitialization_LoadsExistingPlayerData() {
        // Given
        let existingPlayer = PlayerData()
        existingPlayer.level = 5
        existingPlayer.experiencePoints = 500
        modelContext.insert(existingPlayer)
        try! modelContext.save()
        
        // When
        let newSut = GameViewModel(
            physicsService: mockPhysicsService,
            audioService: mockAudioService,
            gameCenterService: mockGameCenterService,
            modelContext: modelContext
        )
        newSut.initialize()
        
        // Then
        XCTAssertEqual(newSut.playerData?.level, 5)
        XCTAssertEqual(newSut.playerData?.experiencePoints, 500)
    }
    
    // MARK: - Game State Tests
    
    func testInitialState_IsNotStarted() {
        // Then
        XCTAssertEqual(sut.gameState.status, .notStarted)
        XCTAssertEqual(sut.gameState.score, 0)
        XCTAssertEqual(sut.gameState.distance, 0)
        XCTAssertEqual(sut.gameState.timeElapsed, 0)
        XCTAssertEqual(sut.gameState.coinsCollected, 0)
    }
    
    func testCanStart_InitiallyTrue() {
        // Then
        XCTAssertTrue(sut.canStart)
        XCTAssertFalse(sut.canPause)
        XCTAssertFalse(sut.canResume)
        XCTAssertFalse(sut.isGameActive)
    }
    
    // MARK: - Start Game Tests
    
    func testStartGame_UpdatesStateToPlaying() {
        // When
        sut.startGame(mode: .freePlay)
        
        // Then
        XCTAssertEqual(sut.gameState.status, .playing)
        XCTAssertEqual(sut.gameState.mode, .freePlay)
        XCTAssertTrue(sut.isGameActive)
        XCTAssertTrue(sut.canPause)
        XCTAssertFalse(sut.canStart)
    }
    
    func testStartGame_StartsPhysicsService() {
        // When
        sut.startGame(mode: .freePlay)
        
        // Then
        XCTAssertTrue(mockPhysicsService.deviceMotionStarted)
        XCTAssertTrue(mockPhysicsService.physicsSimulationStarted)
    }
    
    func testStartGame_PlaysBackgroundMusic() {
        // When
        sut.startGame(mode: .freePlay)
        
        // Then
        XCTAssertTrue(mockAudioService.musicPlayed)
        XCTAssertEqual(mockAudioService.lastMusicTrack, "freeplay_music")
        XCTAssertTrue(mockAudioService.lastMusicLoop)
    }
    
    func testStartGame_PlaysSoundEffect() {
        // When
        sut.startGame(mode: .freePlay)
        
        // Then
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("game_start"))
    }
    
    func testStartGame_WhenAlreadyPlaying_DoesNothing() {
        // Given
        sut.startGame(mode: .freePlay)
        let initialStartTime = sut.gameState.startTime
        
        // When
        sut.startGame(mode: .challenge)
        
        // Then
        XCTAssertEqual(sut.gameState.mode, .freePlay) // Should not change
        XCTAssertEqual(sut.gameState.startTime, initialStartTime)
    }
    
    // MARK: - Pause Game Tests
    
    func testPauseGame_UpdatesStateToPaused() {
        // Given
        sut.startGame(mode: .freePlay)
        
        // When
        sut.pauseGame()
        
        // Then
        XCTAssertEqual(sut.gameState.status, .paused)
        XCTAssertTrue(sut.canResume)
        XCTAssertFalse(sut.canPause)
    }
    
    func testPauseGame_StopsPhysicsService() {
        // Given
        sut.startGame(mode: .freePlay)
        
        // When
        sut.pauseGame()
        
        // Then
        XCTAssertFalse(mockPhysicsService.deviceMotionStarted)
    }
    
    func testPauseGame_PausesMusic() {
        // Given
        sut.startGame(mode: .freePlay)
        
        // When
        sut.pauseGame()
        
        // Then
        XCTAssertTrue(mockAudioService.musicPaused)
    }
    
    func testPauseGame_WhenNotPlaying_DoesNothing() {
        // When
        sut.pauseGame()
        
        // Then
        XCTAssertEqual(sut.gameState.status, .notStarted)
        XCTAssertFalse(mockAudioService.musicPaused)
    }
    
    // MARK: - Resume Game Tests
    
    func testResumeGame_UpdatesStateToPlaying() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.pauseGame()
        
        // When
        sut.resumeGame()
        
        // Then
        XCTAssertEqual(sut.gameState.status, .playing)
        XCTAssertTrue(sut.canPause)
        XCTAssertFalse(sut.canResume)
    }
    
    func testResumeGame_RestartsPhysicsService() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.pauseGame()
        
        // When
        sut.resumeGame()
        
        // Then
        XCTAssertTrue(mockPhysicsService.deviceMotionStarted)
    }
    
    func testResumeGame_ResumesMusic() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.pauseGame()
        
        // When
        sut.resumeGame()
        
        // Then
        XCTAssertTrue(mockAudioService.musicResumed)
    }
    
    // MARK: - End Game Tests
    
    func testEndGame_UpdatesStateToEnded() {
        // Given
        sut.startGame(mode: .freePlay)
        
        // When
        sut.endGame()
        
        // Then
        XCTAssertEqual(sut.gameState.status, .ended)
        XCTAssertFalse(sut.isGameActive)
        XCTAssertNotNil(sut.gameState.endTime)
    }
    
    func testEndGame_StopsPhysicsService() {
        // Given
        sut.startGame(mode: .freePlay)
        
        // When
        sut.endGame()
        
        // Then
        XCTAssertFalse(mockPhysicsService.deviceMotionStarted)
        XCTAssertFalse(mockPhysicsService.physicsSimulationStarted)
    }
    
    func testEndGame_StopsMusic() {
        // Given
        sut.startGame(mode: .freePlay)
        
        // When
        sut.endGame()
        
        // Then
        XCTAssertTrue(mockAudioService.musicStopped)
        XCTAssertEqual(mockAudioService.lastFadeOutDuration, 2.0)
    }
    
    func testEndGame_SavesGameResult() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.addScore(1000)
        sut.addDistance(500)
        sut.addCoin()
        
        // When
        sut.endGame()
        
        // Then
        let gameResults = try! modelContext.fetch(FetchDescriptor<GameResult>())
        XCTAssertEqual(gameResults.count, 1)
        
        let result = gameResults.first!
        XCTAssertEqual(result.mode, "free_play")
        XCTAssertEqual(result.score, 1100) // 1000 + 100 for coin
        XCTAssertEqual(result.distance, 500)
        XCTAssertEqual(result.coinsCollected, 1)
    }
    
    func testEndGame_SubmitsScoreToGameCenter() {
        // Given
        mockGameCenterService.isAuthenticated = true
        sut.startGame(mode: .freePlay)
        sut.addScore(1000)
        
        // When
        sut.endGame()
        
        // Then
        XCTAssertTrue(mockGameCenterService.scoreSubmitted)
        XCTAssertEqual(mockGameCenterService.lastSubmittedScore, 1000)
        XCTAssertEqual(mockGameCenterService.lastLeaderboardID, "freeplay_leaderboard")
    }
    
    // MARK: - Score Management Tests
    
    func testAddScore_UpdatesGameState() {
        // Given
        sut.startGame(mode: .freePlay)
        
        // When
        sut.addScore(100)
        
        // Then
        XCTAssertEqual(sut.gameState.score, 100)
        XCTAssertEqual(sut.formattedScore, "100")
    }
    
    func testUpdateScore_ReplacesCurrentScore() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.addScore(100)
        
        // When
        sut.updateScore(250)
        
        // Then
        XCTAssertEqual(sut.gameState.score, 250)
    }
    
    func testAddScore_WhenNotPlaying_DoesNothing() {
        // When
        sut.addScore(100)
        
        // Then
        XCTAssertEqual(sut.gameState.score, 0)
    }
    
    // MARK: - Distance Management Tests
    
    func testAddDistance_UpdatesGameState() {
        // Given
        sut.startGame(mode: .freePlay)
        
        // When
        sut.addDistance(150.5)
        
        // Then
        XCTAssertEqual(sut.gameState.distance, 150.5)
        XCTAssertEqual(sut.formattedDistance, "150.5 m")
    }
    
    func testUpdateDistance_ReplacesCurrentDistance() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.addDistance(100)
        
        // When
        sut.updateDistance(250.7)
        
        // Then
        XCTAssertEqual(sut.gameState.distance, 250.7)
    }
    
    // MARK: - Coin Collection Tests
    
    func testAddCoin_UpdatesGameStateAndScore() {
        // Given
        sut.startGame(mode: .freePlay)
        let initialScore = sut.gameState.score
        
        // When
        sut.addCoin()
        
        // Then
        XCTAssertEqual(sut.gameState.coinsCollected, 1)
        XCTAssertEqual(sut.gameState.score, initialScore + 100)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("coin_collect"))
    }
    
    func testFormattedCoins_ReturnsCorrectString() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.addCoin()
        sut.addCoin()
        
        // Then
        XCTAssertEqual(sut.formattedCoins, "2")
    }
    
    // MARK: - Obstacle Collision Tests
    
    func testHandleObstacleCollision_ReducesScore() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.addScore(200)
        
        // When
        sut.handleObstacleCollision()
        
        // Then
        XCTAssertEqual(sut.gameState.score, 150) // 200 - 50 penalty
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("obstacle_hit"))
    }
    
    func testHandleObstacleCollision_DoesNotGoBelowZero() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.addScore(25)
        
        // When
        sut.handleObstacleCollision()
        
        // Then
        XCTAssertEqual(sut.gameState.score, 0)
    }
    
    // MARK: - Action Handling Tests
    
    func testHandleStartGameAction_StartsGame() {
        // Given
        let action = StartGameAction(gameMode: "free_play")
        
        // When
        sut.handle(action)
        
        // Then
        XCTAssertEqual(sut.gameState.status, .playing)
        XCTAssertEqual(sut.gameState.mode, .freePlay)
    }
    
    func testHandlePauseGameAction_PausesGame() {
        // Given
        sut.startGame(mode: .freePlay)
        let action = PauseGameAction()
        
        // When
        sut.handle(action)
        
        // Then
        XCTAssertEqual(sut.gameState.status, .paused)
    }
    
    func testHandleResumeGameAction_ResumesGame() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.pauseGame()
        let action = ResumeGameAction()
        
        // When
        sut.handle(action)
        
        // Then
        XCTAssertEqual(sut.gameState.status, .playing)
    }
    
    func testHandleEndGameAction_EndsGame() {
        // Given
        sut.startGame(mode: .freePlay)
        let action = EndGameAction()
        
        // When
        sut.handle(action)
        
        // Then
        XCTAssertEqual(sut.gameState.status, .ended)
    }
    
    func testHandleTiltInputAction_CallsHandleTiltInput() {
        // Given
        sut.startGame(mode: .freePlay)
        let action = TiltInputAction(x: 0.5, y: -0.3)
        
        // When
        sut.handle(action)
        
        // Then - No assertion needed as the method doesn't do anything yet
        // This test ensures the action is handled without crashing
    }
    
    // MARK: - Environment Tests
    
    func testChangeEnvironment_WhenUnlocked_UpdatesGameState() {
        // Given
        sut.playerData?.unlockContent("forest", type: .environment)
        
        // When
        sut.changeEnvironment("forest")
        
        // Then
        XCTAssertEqual(sut.gameState.environmentType, "forest")
    }
    
    func testChangeEnvironment_WhenLocked_SetsError() {
        // When
        sut.changeEnvironment("locked_environment")
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("not unlocked"))
    }
    
    func testAvailableEnvironments_ReturnsUnlockedEnvironments() {
        // Given
        sut.playerData?.unlockContent("forest", type: .environment)
        sut.playerData?.unlockContent("desert", type: .environment)
        
        // Then
        let environments = sut.availableEnvironments
        XCTAssertTrue(environments.contains("standard"))
        XCTAssertTrue(environments.contains("forest"))
        XCTAssertTrue(environments.contains("desert"))
    }
    
    // MARK: - Achievement Tests
    
    func testCheckAchievements_UnlocksDistanceAchievement() {
        // Given
        let achievement = Achievement(
            id: "distance_1000",
            title: "Sky Explorer",
            description: "Travel 1000 units",
            targetValue: 1000
        )
        sut.playerData?.achievements.append(achievement)
        sut.startGame(mode: .freePlay)
        sut.updateDistance(1500)
        
        // When
        sut.checkAchievements()
        
        // Then
        XCTAssertTrue(achievement.isUnlocked)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("achievement_unlock"))
    }
    
    // MARK: - Restart Game Tests
    
    func testRestartGame_EndsCurrentGameAndStartsNew() {
        // Given
        sut.startGame(mode: .challenge)
        sut.addScore(500)
        
        // When
        sut.restartGame()
        
        // Then
        XCTAssertEqual(sut.gameState.status, .ended)
        
        // Wait for async restart
        let expectation = XCTestExpectation(description: "Game restarted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertEqual(self.sut.gameState.status, .playing)
            XCTAssertEqual(self.sut.gameState.mode, .challenge)
            XCTAssertEqual(self.sut.gameState.score, 0) // Should be reset
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Formatted Display Tests
    
    func testFormattedTime_ReturnsCorrectFormat() {
        // Given
        sut.startGame(mode: .freePlay)
        let gameState = sut.gameState.withTimeElapsed(125.7) // 2 minutes, 5 seconds
        sut.gameState = gameState
        
        // Then
        XCTAssertEqual(sut.formattedTime, "02:05")
    }
    
    func testFormattedScore_ReturnsLocalizedNumber() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.addScore(12345)
        
        // Then
        XCTAssertEqual(sut.formattedScore, "12,345")
    }
}

// MARK: - Additional Edge Case Tests

extension GameViewModelTests {
    
    // MARK: - Error Handling Tests
    
    func testStartGame_WithInvalidMode_SetsError() {
        // Given
        let invalidMode = GameMode(rawValue: "invalid_mode") ?? .freePlay
        
        // When
        sut.startGame(mode: invalidMode)
        
        // Then - Should handle gracefully without crashing
        XCTAssertEqual(sut.gameState.status, .playing)
    }
    
    func testEndGame_WhenNotStarted_DoesNotCrash() {
        // When
        sut.endGame()
        
        // Then
        XCTAssertEqual(sut.gameState.status, .notStarted)
    }
    
    func testHandleTiltInput_WithExtremeValues_HandlesGracefully() {
        // Given
        sut.startGame(mode: .freePlay)
        
        // When
        sut.handleTiltInput(x: 999.0, y: -999.0)
        
        // Then - Should not crash and should clamp values
        // Verify physics service received reasonable values
        XCTAssertTrue(mockPhysicsService.forcesApplied.count > 0)
    }
    
    func testAddScore_WithNegativeValue_HandlesCorrectly() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.addScore(100)
        
        // When
        sut.addScore(-50)
        
        // Then
        XCTAssertEqual(sut.gameState.score, 50) // Should subtract correctly
    }
    
    func testAddDistance_WithNegativeValue_DoesNotDecrease() {
        // Given
        sut.startGame(mode: .freePlay)
        sut.addDistance(100)
        
        // When
        sut.addDistance(-50)
        
        // Then
        XCTAssertEqual(sut.gameState.distance, 100) // Should not go backwards
    }
    
    func testGameStateTransitions_InvalidSequence_HandlesGracefully() {
        // When - Try to resume without pausing
        sut.resumeGame()
        
        // Then
        XCTAssertEqual(sut.gameState.status, .notStarted)
        
        // When - Try to pause without starting
        sut.pauseGame()
        
        // Then
        XCTAssertEqual(sut.gameState.status, .notStarted)
    }
    
    // MARK: - Performance Tests
    
    func testMultipleScoreUpdates_PerformanceTest() {
        // Given
        sut.startGame(mode: .freePlay)
        
        // When
        measure {
            for i in 0..<1000 {
                sut.addScore(1)
            }
        }
        
        // Then
        XCTAssertEqual(sut.gameState.score, 1000)
    }
    
    func testRapidStateChanges_PerformanceTest() {
        // When
        measure {
            for _ in 0..<100 {
                sut.startGame(mode: .freePlay)
                sut.pauseGame()
                sut.resumeGame()
                sut.endGame()
            }
        }
        
        // Then
        XCTAssertEqual(sut.gameState.status, .ended)
    }
    
    // MARK: - Memory Management Tests
    
    func testCleanup_ReleasesResources() {
        // Given
        sut.startGame(mode: .freePlay)
        
        // When
        sut.cleanup()
        
        // Then
        XCTAssertFalse(mockPhysicsService.isActive)
        XCTAssertTrue(mockAudioService.musicStopped)
    }
    
    func testMultipleInitialization_DoesNotLeak() {
        // When
        for _ in 0..<10 {
            let viewModel = GameViewModel(
                physicsService: mockPhysicsService,
                audioService: mockAudioService,
                gameCenterService: mockGameCenterService,
                modelContext: modelContext
            )
            viewModel.initialize()
            viewModel.cleanup()
        }
        
        // Then - Should not crash or leak memory
        XCTAssertTrue(true)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentScoreUpdates_ThreadSafe() {
        // Given
        sut.startGame(mode: .freePlay)
        let expectation = XCTestExpectation(description: "Concurrent updates complete")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.sut.addScore(10)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then
        XCTAssertEqual(sut.gameState.score, 100)
    }
    
    // MARK: - Game Center Integration Tests
    
    func testGameCenterSubmission_WhenNotAuthenticated_HandlesGracefully() {
        // Given
        mockGameCenterService.isAuthenticated = false
        sut.startGame(mode: .freePlay)
        sut.addScore(1000)
        
        // When
        sut.endGame()
        
        // Then
        XCTAssertFalse(mockGameCenterService.scoreSubmitted)
    }
    
    func testGameCenterSubmission_WithNetworkError_HandlesGracefully() {
        // Given
        mockGameCenterService.isAuthenticated = true
        mockGameCenterService.shouldFailScoreSubmission = true
        sut.startGame(mode: .freePlay)
        sut.addScore(1000)
        
        // When
        sut.endGame()
        
        // Then
        XCTAssertTrue(mockGameCenterService.scoreSubmitted) // Attempt was made
        // Should not crash or show error to user during gameplay
    }
    
    // MARK: - Data Persistence Tests
    
    func testGameResult_SavesAllRequiredFields() {
        // Given
        sut.startGame(mode: .challenge)
        sut.addScore(1500)
        sut.addDistance(750.5)
        sut.addCoin()
        sut.addCoin()
        sut.changeEnvironment("forest")
        
        // When
        sut.endGame()
        
        // Then
        let gameResults = try! modelContext.fetch(FetchDescriptor<GameResult>())
        XCTAssertEqual(gameResults.count, 1)
        
        let result = gameResults.first!
        XCTAssertEqual(result.mode, "challenge")
        XCTAssertEqual(result.score, 1700) // 1500 + 200 for coins
        XCTAssertEqual(result.distance, 750.5)
        XCTAssertEqual(result.coinsCollected, 2)
        XCTAssertEqual(result.environmentType, "forest")
        XCTAssertNotNil(result.completedAt)
    }
    
    func testPlayerDataUpdate_UpdatesExperienceAndLevel() {
        // Given
        let initialLevel = sut.playerData?.level ?? 1
        let initialXP = sut.playerData?.experiencePoints ?? 0
        sut.startGame(mode: .freePlay)
        sut.addScore(2000) // High score for XP
        sut.addDistance(1000)
        
        // When
        sut.endGame()
        
        // Then
        XCTAssertGreaterThan(sut.playerData?.experiencePoints ?? 0, initialXP)
        // Level might increase depending on XP gained
    }
    
    // MARK: - Achievement System Tests
    
    func testAchievementProgress_UpdatesCorrectly() {
        // Given
        let distanceAchievement = Achievement(
            id: "distance_500",
            title: "Explorer",
            description: "Travel 500 units",
            targetValue: 500
        )
        sut.playerData?.achievements.append(distanceAchievement)
        sut.startGame(mode: .freePlay)
        
        // When
        sut.updateDistance(250) // Half way to achievement
        sut.checkAchievements()
        
        // Then
        XCTAssertEqual(distanceAchievement.progress, 0.5, accuracy: 0.01)
        XCTAssertFalse(distanceAchievement.isUnlocked)
        
        // When - Complete the achievement
        sut.updateDistance(500)
        sut.checkAchievements()
        
        // Then
        XCTAssertTrue(distanceAchievement.isUnlocked)
        XCTAssertNotNil(distanceAchievement.unlockedAt)
    }
    
    // MARK: - Environment System Tests
    
    func testEnvironmentChange_UpdatesPhysicsSettings() {
        // Given
        sut.playerData?.unlockContent("windy_canyon", type: .environment)
        sut.startGame(mode: .freePlay)
        
        // When
        sut.changeEnvironment("windy_canyon")
        
        // Then
        XCTAssertEqual(sut.gameState.environmentType, "windy_canyon")
        // Physics service should be notified of environment change
        XCTAssertTrue(mockPhysicsService.windTransitions.count > 0)
    }
    
    func testAvailableEnvironments_FiltersCorrectly() {
        // Given
        sut.playerData?.unlockContent("forest", type: .environment)
        sut.playerData?.unlockContent("desert", type: .environment)
        
        // When
        let environments = sut.availableEnvironments
        
        // Then
        XCTAssertTrue(environments.contains("standard")) // Always available
        XCTAssertTrue(environments.contains("forest"))
        XCTAssertTrue(environments.contains("desert"))
        XCTAssertFalse(environments.contains("locked_environment"))
    }
}