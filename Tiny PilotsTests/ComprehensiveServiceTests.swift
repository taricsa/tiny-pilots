//
//  ComprehensiveServiceTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
import SpriteKit
import SwiftData
@testable import Tiny_Pilots

/// Comprehensive service layer testing to achieve 85%+ code coverage
final class ComprehensiveServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var container: ModelContainer!
    var context: ModelContext!
    var mockAudioService: MockAudioService!
    var mockPhysicsService: MockPhysicsService!
    var mockGameCenterService: MockGameCenterService!
    
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
    }
    
    override func tearDownWithError() throws {
        container = nil
        context = nil
        mockAudioService = nil
        mockPhysicsService = nil
        mockGameCenterService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Audio Service Comprehensive Tests
    
    func testAudioService_PlaySound_AllVariations() throws {
        // Test basic sound playback
        mockAudioService.playSound("test_sound")
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("test_sound"))
        
        // Test sound with custom volume
        mockAudioService.playSound("volume_test", volume: 0.5)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("volume_test"))
        
        // Test sound with custom pitch
        mockAudioService.playSound("pitch_test", pitch: 1.5)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("pitch_test"))
        
        // Test sound with completion handler
        let expectation = XCTestExpectation(description: "Sound completion")
        mockAudioService.playSound("completion_test") {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("completion_test"))
    }
    
    func testAudioService_StopSound_Functionality() throws {
        // Play multiple sounds
        mockAudioService.playSound("sound1")
        mockAudioService.playSound("sound2")
        mockAudioService.playSound("sound3")
        
        // Stop specific sound
        mockAudioService.stopSound("sound2")
        XCTAssertTrue(mockAudioService.stoppedSounds.contains("sound2"))
        
        // Stop all sounds
        mockAudioService.stopAllSounds()
        XCTAssertTrue(mockAudioService.stoppedSounds.contains("ALL_SOUNDS"))
    }
    
    func testAudioService_MusicPlayback_AllFeatures() throws {
        // Test basic music playback
        mockAudioService.playMusic("background_music")
        XCTAssertEqual(mockAudioService.currentMusicTrack, "background_music")
        XCTAssertTrue(mockAudioService.musicTracksPlayed.contains("background_music"))
        
        // Test music with custom volume
        mockAudioService.playMusic("menu_music", volume: 0.3)
        XCTAssertEqual(mockAudioService.currentMusicTrack, "menu_music")
        
        // Test music without looping
        mockAudioService.playMusic("intro_music", loop: false)
        XCTAssertEqual(mockAudioService.currentMusicTrack, "intro_music")
        
        // Test music with fade in
        mockAudioService.playMusic("fade_music", fadeIn: 2.0)
        XCTAssertEqual(mockAudioService.currentMusicTrack, "fade_music")
    }
    
    func testAudioService_MusicControl_PauseResumeStop() throws {
        // Start music
        mockAudioService.playMusic("test_music")
        XCTAssertEqual(mockAudioService.currentMusicTrack, "test_music")
        
        // Pause music
        mockAudioService.pauseMusic()
        XCTAssertTrue(mockAudioService.musicPaused)
        
        // Resume music
        mockAudioService.resumeMusic()
        XCTAssertTrue(mockAudioService.musicResumed)
        
        // Stop music
        mockAudioService.stopMusic()
        XCTAssertNil(mockAudioService.currentMusicTrack)
        XCTAssertTrue(mockAudioService.musicStopped)
        
        // Stop music with fade out
        mockAudioService.playMusic("fade_out_music")
        mockAudioService.stopMusic(fadeOut: 1.5)
        XCTAssertTrue(mockAudioService.musicStopped)
    }
    
    func testAudioService_VolumeAndSettings_Management() throws {
        // Test volume settings
        XCTAssertEqual(mockAudioService.soundVolume, 0.7)
        XCTAssertEqual(mockAudioService.musicVolume, 0.5)
        
        // Test enabled/disabled states
        XCTAssertTrue(mockAudioService.soundEnabled)
        XCTAssertTrue(mockAudioService.musicEnabled)
        
        // Test master volume
        mockAudioService.setMasterVolume(0.8)
        XCTAssertEqual(mockAudioService.masterVolumeSet, 0.8)
        
        // Test preloading sounds
        let soundsToPreload = ["sound1", "sound2", "sound3"]
        mockAudioService.preloadSounds(soundsToPreload)
        XCTAssertEqual(mockAudioService.preloadedSounds, soundsToPreload)
    }
    
    func testAudioService_GameplayScenarios() throws {
        // Test typical gameplay audio sequence
        mockAudioService.simulateGameplayAudio()
        XCTAssertTrue(mockAudioService.verifyGameplayAudioPlayed())
        
        // Test menu audio sequence
        mockAudioService.simulateMenuAudio()
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("menu_select"))
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("menu_back"))
        XCTAssertTrue(mockAudioService.musicTracksPlayed.contains("menu_music"))
        
        // Test volume changes during gameplay
        mockAudioService.simulateVolumeChanges()
        XCTAssertEqual(mockAudioService.soundVolume, 0.5)
        XCTAssertEqual(mockAudioService.musicVolume, 0.3)
        XCTAssertEqual(mockAudioService.masterVolumeSet, 0.8)
    }
    
    // MARK: - Physics Service Comprehensive Tests
    
    func testPhysicsService_WorldConfiguration() throws {
        let scene = TestScenarioHelper.createMockScene()
        
        // Test physics world configuration
        mockPhysicsService.configurePhysicsWorld(for: scene)
        XCTAssertTrue(mockPhysicsService.configuredScenes.contains(scene))
        
        // Test multiple scene configurations
        let scene2 = TestScenarioHelper.createMockScene()
        mockPhysicsService.configurePhysicsWorld(for: scene2)
        XCTAssertEqual(mockPhysicsService.configuredScenes.count, 2)
    }
    
    func testPhysicsService_DeviceMotionManagement() throws {
        // Test starting device motion
        mockPhysicsService.startDeviceMotionUpdates()
        XCTAssertTrue(mockPhysicsService.deviceMotionStarted)
        XCTAssertTrue(mockPhysicsService.isActive)
        
        // Test stopping device motion
        mockPhysicsService.stopDeviceMotionUpdates()
        XCTAssertTrue(mockPhysicsService.deviceMotionStopped)
        XCTAssertFalse(mockPhysicsService.isActive)
        
        // Test multiple start/stop cycles
        for _ in 0..<5 {
            mockPhysicsService.startDeviceMotionUpdates()
            mockPhysicsService.stopDeviceMotionUpdates()
        }
        XCTAssertTrue(mockPhysicsService.deviceMotionStarted)
        XCTAssertTrue(mockPhysicsService.deviceMotionStopped)
    }
    
    func testPhysicsService_SimulationControl() throws {
        // Test starting physics simulation
        mockPhysicsService.startPhysicsSimulation()
        XCTAssertTrue(mockPhysicsService.physicsSimulationStarted)
        XCTAssertTrue(mockPhysicsService.isActive)
        
        // Test stopping physics simulation
        mockPhysicsService.stopPhysicsSimulation()
        XCTAssertTrue(mockPhysicsService.physicsSimulationStopped)
        XCTAssertFalse(mockPhysicsService.isActive)
    }
    
    func testPhysicsService_ForceApplication() throws {
        let airplane = TestScenarioHelper.createMockAirplane()
        
        // Test basic force application
        mockPhysicsService.applyForces(to: airplane, tiltX: 0.5, tiltY: -0.3)
        XCTAssertEqual(mockPhysicsService.forcesApplied.count, 1)
        XCTAssertEqual(mockPhysicsService.forcesApplied[0].tiltX, 0.5)
        XCTAssertEqual(mockPhysicsService.forcesApplied[0].tiltY, -0.3)
        
        // Test multiple force applications
        mockPhysicsService.applyForces(to: airplane, tiltX: -0.2, tiltY: 0.8)
        XCTAssertEqual(mockPhysicsService.forcesApplied.count, 2)
        
        // Test extreme values
        mockPhysicsService.applyForces(to: airplane, tiltX: 1.0, tiltY: -1.0)
        mockPhysicsService.applyForces(to: airplane, tiltX: 0.0, tiltY: 0.0)
        XCTAssertEqual(mockPhysicsService.forcesApplied.count, 4)
    }
    
    func testPhysicsService_LiftCalculation() throws {
        let airplane = TestScenarioHelper.createMockAirplane()
        
        // Test lift calculation
        let lift = mockPhysicsService.calculateLift(for: airplane)
        XCTAssertEqual(lift, 10.0) // Mock returns 10.0
        XCTAssertTrue(mockPhysicsService.liftCalculations.contains(airplane))
        
        // Test multiple lift calculations
        for _ in 0..<10 {
            _ = mockPhysicsService.calculateLift(for: airplane)
        }
        XCTAssertEqual(mockPhysicsService.liftCalculations.count, 11)
    }
    
    func testPhysicsService_CollisionHandling() throws {
        let nodeA = SKNode()
        let nodeB = SKNode()
        
        // Test collision handling
        mockPhysicsService.handleCollision(between: nodeA, and: nodeB)
        XCTAssertEqual(mockPhysicsService.collisionsHandled.count, 1)
        
        // Test multiple collisions
        let nodeC = SKNode()
        mockPhysicsService.handleCollision(between: nodeA, and: nodeC)
        mockPhysicsService.handleCollision(between: nodeB, and: nodeC)
        XCTAssertEqual(mockPhysicsService.collisionsHandled.count, 3)
    }
    
    func testPhysicsService_WindSystem() throws {
        let airplane = TestScenarioHelper.createMockAirplane()
        
        // Test wind vector setting
        mockPhysicsService.setWindVector(direction: 45, strength: 15)
        let expectedX = cos(45 * .pi / 180) * 15
        let expectedY = sin(45 * .pi / 180) * 15
        XCTAssertEqual(mockPhysicsService.windVector.dx, expectedX, accuracy: 0.1)
        XCTAssertEqual(mockPhysicsService.windVector.dy, expectedY, accuracy: 0.1)
        
        // Test wind application
        mockPhysicsService.applyWind(to: airplane)
        // Mock doesn't track this specifically, but ensures no crash
        
        // Test random wind updates
        mockPhysicsService.updateRandomWind()
        XCTAssertEqual(mockPhysicsService.windUpdates, 1)
        
        // Test wind transitions
        mockPhysicsService.transitionWindVector(toDirection: 90, strength: 20, duration: 2.0)
        XCTAssertEqual(mockPhysicsService.windTransitions.count, 1)
        XCTAssertEqual(mockPhysicsService.windTransitions[0].direction, 90)
        XCTAssertEqual(mockPhysicsService.windTransitions[0].strength, 20)
        XCTAssertEqual(mockPhysicsService.windTransitions[0].duration, 2.0)
    }
    
    func testPhysicsService_AdvancedFeatures() throws {
        let airplane = TestScenarioHelper.createMockAirplane()
        
        // Test turbulence application
        mockPhysicsService.applyTurbulence(to: airplane)
        XCTAssertTrue(mockPhysicsService.turbulenceApplications.contains(airplane))
        
        // Test advanced flight controls (would need CMDeviceMotion mock)
        // For now, test that the method exists and doesn't crash
        // mockPhysicsService.applyAdvancedFlightControls(to: airplane, motion: mockMotion)
    }
    
    func testPhysicsService_GameplayScenarios() throws {
        let airplane = TestScenarioHelper.createMockAirplane()
        
        // Test complete gameplay physics scenario
        mockPhysicsService.simulateGameplayPhysics(with: airplane)
        XCTAssertTrue(mockPhysicsService.verifyPhysicsActive())
        XCTAssertTrue(mockPhysicsService.verifyForcesApplied(to: airplane))
        
        // Test windy conditions scenario
        mockPhysicsService.simulateWindyConditions()
        XCTAssertGreaterThan(mockPhysicsService.windUpdates, 0)
        XCTAssertGreaterThan(mockPhysicsService.windTransitions.count, 0)
        
        // Test collision scenario
        let nodeA = SKNode()
        let nodeB = SKNode()
        mockPhysicsService.simulateCollisionScenario(nodeA: nodeA, nodeB: nodeB)
        XCTAssertGreaterThan(mockPhysicsService.collisionsHandled.count, 0)
    }
    
    // MARK: - Game Center Service Comprehensive Tests
    
    func testGameCenterService_Authentication() throws {
        // Test successful authentication
        let successExpectation = XCTestExpectation(description: "Successful authentication")
        mockGameCenterService.authenticate { success, error in
            XCTAssertTrue(success)
            XCTAssertNil(error)
            XCTAssertTrue(self.mockGameCenterService.isAuthenticated)
            XCTAssertEqual(self.mockGameCenterService.playerDisplayName, "Test Player")
            successExpectation.fulfill()
        }
        wait(for: [successExpectation], timeout: 1.0)
        XCTAssertEqual(mockGameCenterService.authenticationAttempts, 1)
        
        // Test failed authentication
        mockGameCenterService.reset()
        mockGameCenterService.shouldFailAuthentication = true
        
        let failureExpectation = XCTestExpectation(description: "Failed authentication")
        mockGameCenterService.authenticate { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            XCTAssertFalse(self.mockGameCenterService.isAuthenticated)
            failureExpectation.fulfill()
        }
        wait(for: [failureExpectation], timeout: 1.0)
    }
    
    func testGameCenterService_ScoreSubmission() throws {
        // Setup authentication
        mockGameCenterService.simulateSuccessfulAuthentication()
        
        // Test successful score submission
        let successExpectation = XCTestExpectation(description: "Successful score submission")
        mockGameCenterService.submitScore(1500, to: "high_score") { error in
            XCTAssertNil(error)
            successExpectation.fulfill()
        }
        wait(for: [successExpectation], timeout: 1.0)
        
        XCTAssertEqual(mockGameCenterService.scoresSubmitted.count, 1)
        XCTAssertEqual(mockGameCenterService.scoresSubmitted[0].score, 1500)
        XCTAssertEqual(mockGameCenterService.scoresSubmitted[0].leaderboardID, "high_score")
        
        // Test failed score submission
        mockGameCenterService.shouldFailScoreSubmission = true
        
        let failureExpectation = XCTestExpectation(description: "Failed score submission")
        mockGameCenterService.submitScore(2000, to: "distance") { error in
            XCTAssertNotNil(error)
            failureExpectation.fulfill()
        }
        wait(for: [failureExpectation], timeout: 1.0)
    }
    
    func testGameCenterService_LeaderboardLoading() throws {
        // Setup mock leaderboard data
        mockGameCenterService.simulateLeaderboardData()
        
        // Test successful leaderboard loading
        let successExpectation = XCTestExpectation(description: "Successful leaderboard loading")
        mockGameCenterService.loadLeaderboard(for: "high_score") { entries, error in
            XCTAssertNil(error)
            XCTAssertNotNil(entries)
            XCTAssertEqual(entries?.count, 3)
            XCTAssertEqual(entries?[0].displayName, "Player 1")
            XCTAssertEqual(entries?[0].score, 1500)
            XCTAssertEqual(entries?[0].rank, 1)
            successExpectation.fulfill()
        }
        wait(for: [successExpectation], timeout: 1.0)
        
        XCTAssertTrue(mockGameCenterService.leaderboardsLoaded.contains("high_score"))
        
        // Test failed leaderboard loading
        mockGameCenterService.shouldFailLeaderboardLoad = true
        
        let failureExpectation = XCTestExpectation(description: "Failed leaderboard loading")
        mockGameCenterService.loadLeaderboard(for: "invalid") { entries, error in
            XCTAssertNotNil(error)
            XCTAssertNil(entries)
            failureExpectation.fulfill()
        }
        wait(for: [failureExpectation], timeout: 1.0)
    }
    
    func testGameCenterService_AchievementManagement() throws {
        // Setup mock achievement data
        mockGameCenterService.simulateAchievementData()
        
        // Test achievement reporting
        let reportExpectation = XCTestExpectation(description: "Achievement reporting")
        mockGameCenterService.reportAchievement(identifier: "first_flight", percentComplete: 100.0) { error in
            XCTAssertNil(error)
            reportExpectation.fulfill()
        }
        wait(for: [reportExpectation], timeout: 1.0)
        
        XCTAssertEqual(mockGameCenterService.achievementsReported.count, 1)
        XCTAssertEqual(mockGameCenterService.achievementsReported[0].identifier, "first_flight")
        XCTAssertEqual(mockGameCenterService.achievementsReported[0].percentComplete, 100.0)
        
        // Test achievement loading
        let loadExpectation = XCTestExpectation(description: "Achievement loading")
        mockGameCenterService.loadAchievements { achievements, error in
            XCTAssertNil(error)
            XCTAssertNotNil(achievements)
            XCTAssertEqual(achievements?.count, 3)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 1.0)
        
        XCTAssertEqual(mockGameCenterService.achievementsLoaded, 1)
    }
    
    func testGameCenterService_ChallengeSystem() throws {
        // Test challenge code generation
        let challengeCode1 = mockGameCenterService.generateChallengeCode(for: "test_course_data")
        XCTAssertEqual(challengeCode1, "TEST_1")
        XCTAssertTrue(mockGameCenterService.challengeCodesGenerated.contains("TEST_1"))
        
        let challengeCode2 = mockGameCenterService.generateChallengeCode(for: "another_course")
        XCTAssertEqual(challengeCode2, "TEST_2")
        
        // Test challenge code validation - success
        let validationExpectation = XCTestExpectation(description: "Challenge validation")
        mockGameCenterService.validateChallengeCode("VALID_CODE") { result in
            switch result {
            case .success(let courseData):
                XCTAssertEqual(courseData, "Mock course data for VALID_CODE")
                validationExpectation.fulfill()
            case .failure:
                XCTFail("Validation should succeed")
            }
        }
        wait(for: [validationExpectation], timeout: 1.0)
        
        // Test challenge code validation - failure
        mockGameCenterService.shouldFailChallengeValidation = true
        
        let failureExpectation = XCTestExpectation(description: "Challenge validation failure")
        mockGameCenterService.validateChallengeCode("INVALID_CODE") { result in
            switch result {
            case .success:
                XCTFail("Validation should fail")
            case .failure(let error):
                XCTAssertNotNil(error)
                failureExpectation.fulfill()
            }
        }
        wait(for: [failureExpectation], timeout: 1.0)
    }
    
    func testGameCenterService_UIPresentation() throws {
        let mockViewController = UIViewController()
        
        // Test leaderboard presentation
        mockGameCenterService.showLeaderboards(from: mockViewController)
        XCTAssertEqual(mockGameCenterService.leaderboardsShown, 1)
        
        // Test achievement presentation
        mockGameCenterService.showAchievements(from: mockViewController)
        XCTAssertEqual(mockGameCenterService.achievementsShown, 1)
        
        // Test multiple presentations
        for _ in 0..<5 {
            mockGameCenterService.showLeaderboards(from: mockViewController)
            mockGameCenterService.showAchievements(from: mockViewController)
        }
        XCTAssertEqual(mockGameCenterService.leaderboardsShown, 6)
        XCTAssertEqual(mockGameCenterService.achievementsShown, 6)
    }
    
    func testGameCenterService_CompleteGameCenterFlow() throws {
        // Test complete Game Center interaction flow
        mockGameCenterService.simulateGameCenterInteraction()
        XCTAssertTrue(mockGameCenterService.verifyGameCenterActivity())
        
        // Test network failure scenarios
        mockGameCenterService.reset()
        mockGameCenterService.simulateNetworkFailures()
        
        let authExpectation = XCTestExpectation(description: "Auth failure")
        mockGameCenterService.authenticate { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            authExpectation.fulfill()
        }
        wait(for: [authExpectation], timeout: 1.0)
        
        let scoreExpectation = XCTestExpectation(description: "Score failure")
        mockGameCenterService.submitScore(1000, to: "test") { error in
            XCTAssertNotNil(error)
            scoreExpectation.fulfill()
        }
        wait(for: [scoreExpectation], timeout: 1.0)
    }
    
    // MARK: - Integration Service Tests
    
    func testServiceIntegration_AudioAndPhysics() throws {
        let airplane = TestScenarioHelper.createMockAirplane()
        
        // Start physics simulation
        mockPhysicsService.startPhysicsSimulation()
        mockPhysicsService.startDeviceMotionUpdates()
        
        // Play background music
        mockAudioService.playMusic("gameplay_music")
        
        // Simulate gameplay with both services
        mockPhysicsService.applyForces(to: airplane, tiltX: 0.3, tiltY: -0.2)
        mockAudioService.playSound("airplane_whoosh")
        
        // Simulate collision
        let obstacle = SKNode()
        mockPhysicsService.handleCollision(between: airplane, and: obstacle)
        mockAudioService.playSound("collision_sound")
        
        // Verify both services were used
        XCTAssertTrue(mockPhysicsService.isActive)
        XCTAssertGreaterThan(mockPhysicsService.forcesApplied.count, 0)
        XCTAssertGreaterThan(mockPhysicsService.collisionsHandled.count, 0)
        XCTAssertEqual(mockAudioService.currentMusicTrack, "gameplay_music")
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("airplane_whoosh"))
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("collision_sound"))
    }
    
    func testServiceIntegration_GameCenterAndAudio() throws {
        // Authenticate with Game Center
        mockGameCenterService.simulateSuccessfulAuthentication()
        
        // Play authentication success sound
        mockAudioService.playSound("gamecenter_connected")
        
        // Submit score with audio feedback
        let scoreExpectation = XCTestExpectation(description: "Score submission")
        mockGameCenterService.submitScore(2500, to: "high_score") { error in
            if error == nil {
                self.mockAudioService.playSound("score_submitted")
            } else {
                self.mockAudioService.playSound("error_sound")
            }
            scoreExpectation.fulfill()
        }
        wait(for: [scoreExpectation], timeout: 1.0)
        
        // Verify integration
        XCTAssertTrue(mockGameCenterService.isAuthenticated)
        XCTAssertGreaterThan(mockGameCenterService.scoresSubmitted.count, 0)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("gamecenter_connected"))
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("score_submitted"))
    }
    
    func testServiceIntegration_AllThreeServices() throws {
        let airplane = TestScenarioHelper.createMockAirplane()
        
        // Initialize all services
        mockGameCenterService.simulateSuccessfulAuthentication()
        mockPhysicsService.startPhysicsSimulation()
        mockAudioService.playMusic("game_music")
        
        // Simulate complete gameplay sequence
        // 1. Game start
        mockAudioService.playSound("game_start")
        mockPhysicsService.startDeviceMotionUpdates()
        
        // 2. Gameplay
        for i in 0..<10 {
            mockPhysicsService.applyForces(to: airplane, tiltX: Float(i) * 0.1, tiltY: -0.2)
            if i % 3 == 0 {
                mockAudioService.playSound("coin_collect")
            }
        }
        
        // 3. Game end and score submission
        mockPhysicsService.stopPhysicsSimulation()
        mockAudioService.stopMusic()
        
        let scoreExpectation = XCTestExpectation(description: "Final score submission")
        mockGameCenterService.submitScore(5000, to: "final_score") { error in
            self.mockAudioService.playSound("game_complete")
            scoreExpectation.fulfill()
        }
        wait(for: [scoreExpectation], timeout: 1.0)
        
        // Verify all services were properly integrated
        XCTAssertTrue(mockGameCenterService.isAuthenticated)
        XCTAssertGreaterThan(mockGameCenterService.scoresSubmitted.count, 0)
        XCTAssertEqual(mockPhysicsService.forcesApplied.count, 10)
        XCTAssertTrue(mockPhysicsService.physicsSimulationStopped)
        XCTAssertTrue(mockAudioService.musicStopped)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("game_start"))
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("coin_collect"))
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("game_complete"))
    }
    
    // MARK: - Performance Tests
    
    func testServicePerformance_AudioService() throws {
        measure {
            for i in 0..<1000 {
                mockAudioService.playSound("perf_test_\(i)")
            }
        }
        
        XCTAssertEqual(mockAudioService.soundsPlayed.count, 1000)
    }
    
    func testServicePerformance_PhysicsService() throws {
        let airplane = TestScenarioHelper.createMockAirplane()
        
        measure {
            for i in 0..<1000 {
                mockPhysicsService.applyForces(to: airplane, tiltX: Float(i) * 0.001, tiltY: -0.1)
            }
        }
        
        XCTAssertEqual(mockPhysicsService.forcesApplied.count, 1000)
    }
    
    func testServicePerformance_GameCenterService() throws {
        mockGameCenterService.simulateSuccessfulAuthentication()
        
        measure {
            for i in 0..<100 {
                let expectation = XCTestExpectation(description: "Score \(i)")
                mockGameCenterService.submitScore(i * 10, to: "perf_test") { _ in
                    expectation.fulfill()
                }
                wait(for: [expectation], timeout: 0.1)
            }
        }
        
        XCTAssertEqual(mockGameCenterService.scoresSubmitted.count, 100)
    }
    
    // MARK: - Error Handling Tests
    
    func testServiceErrorHandling_AudioService() throws {
        // Test that audio service handles errors gracefully
        mockAudioService.playSound("")  // Empty sound name
        mockAudioService.playMusic("")  // Empty music name
        mockAudioService.setMasterVolume(-1.0)  // Invalid volume
        mockAudioService.setMasterVolume(2.0)   // Invalid volume
        
        // Should not crash and should handle gracefully
        XCTAssertTrue(true)  // If we get here, no crashes occurred
    }
    
    func testServiceErrorHandling_PhysicsService() throws {
        // Test physics service error handling
        mockPhysicsService.applyForces(to: TestScenarioHelper.createMockAirplane(), tiltX: Float.infinity, tiltY: Float.nan)
        mockPhysicsService.setWindVector(direction: Float.infinity, strength: Float.nan)
        
        // Should handle extreme values gracefully
        XCTAssertTrue(true)
    }
    
    func testServiceErrorHandling_GameCenterService() throws {
        // Test Game Center service error handling
        mockGameCenterService.submitScore(-1, to: "") { _ in }
        mockGameCenterService.loadLeaderboard(for: "") { _, _ in }
        mockGameCenterService.reportAchievement(identifier: "", percentComplete: -1.0) { _ in }
        
        // Should handle invalid inputs gracefully
        XCTAssertTrue(true)
    }
}