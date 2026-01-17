//
//  MockServices.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import Foundation
import SpriteKit
import GameKit
import CoreMotion
@testable import Tiny_Pilots

// MARK: - Mock Audio Service

class MockAudioService: AudioServiceProtocol {
    var soundVolume: Float = 0.7
    var musicVolume: Float = 0.5
    var soundEnabled: Bool = true
    var musicEnabled: Bool = true
    var currentMusicTrack: String?
    
    // Test tracking properties
    var soundsPlayed: [String] = []
    var musicTracksPlayed: [String] = []
    var stoppedSounds: [String] = []
    var preloadedSounds: [String] = []
    var masterVolumeSet: Float?
    var musicStopped: Bool = false
    var musicPaused: Bool = false
    var musicResumed: Bool = false
    
    func playSound(_ name: String, volume: Float? = nil, pitch: Float = 1.0, completion: (() -> Void)? = nil) {
        soundsPlayed.append(name)
        completion?()
    }
    
    func stopSound(_ name: String) {
        stoppedSounds.append(name)
    }
    
    func stopAllSounds() {
        stoppedSounds.append("ALL_SOUNDS")
    }
    
    func playMusic(_ name: String, volume: Float? = nil, loop: Bool = true, fadeIn: TimeInterval = 0) {
        currentMusicTrack = name
        musicTracksPlayed.append(name)
    }
    
    func stopMusic(fadeOut: TimeInterval = 0) {
        currentMusicTrack = nil
        musicStopped = true
    }
    
    func pauseMusic() {
        musicPaused = true
    }
    
    func resumeMusic() {
        musicResumed = true
    }
    
    func preloadSounds(_ names: [String]) {
        preloadedSounds.append(contentsOf: names)
    }
    
    func setMasterVolume(_ volume: Float) {
        masterVolumeSet = volume
    }
    
    // Test helper methods
    func reset() {
        soundsPlayed.removeAll()
        musicTracksPlayed.removeAll()
        stoppedSounds.removeAll()
        preloadedSounds.removeAll()
        masterVolumeSet = nil
        musicStopped = false
        musicPaused = false
        musicResumed = false
        currentMusicTrack = nil
    }
}

// MARK: - Mock Physics Service

class MockPhysicsService: PhysicsServiceProtocol {
    var windVector: CGVector = CGVector.zero
    var sensitivity: CGFloat = 1.0
    var isActive: Bool = false
    
    // Test tracking properties
    var configuredScenes: [SKScene] = []
    var deviceMotionStarted: Bool = false
    var deviceMotionStopped: Bool = false
    var physicsSimulationStarted: Bool = false
    var physicsSimulationStopped: Bool = false
    var forcesApplied: [(airplane: PaperAirplane, tiltX: CGFloat, tiltY: CGFloat)] = []
    var liftCalculations: [PaperAirplane] = []
    var collisionsHandled: [(nodeA: SKNode, nodeB: SKNode)] = []
    var windTransitions: [(direction: CGFloat, strength: CGFloat, duration: TimeInterval)] = []
    var windUpdates: Int = 0
    var turbulenceApplications: [PaperAirplane] = []
    var advancedControlsApplications: [(airplane: PaperAirplane, motion: CMDeviceMotion?)] = []
    
    func configurePhysicsWorld(for scene: SKScene) {
        configuredScenes.append(scene)
    }
    
    func startDeviceMotionUpdates() {
        deviceMotionStarted = true
        isActive = true
    }
    
    func stopDeviceMotionUpdates() {
        deviceMotionStopped = true
        isActive = false
    }
    
    func startPhysicsSimulation() {
        physicsSimulationStarted = true
        isActive = true
    }
    
    func stopPhysicsSimulation() {
        physicsSimulationStopped = true
        isActive = false
    }
    
    func applyForces(to airplane: PaperAirplane, tiltX: CGFloat, tiltY: CGFloat) {
        forcesApplied.append((airplane: airplane, tiltX: tiltX, tiltY: tiltY))
    }
    
    func calculateLift(for airplane: PaperAirplane) -> CGFloat {
        liftCalculations.append(airplane)
        return 10.0 // Mock lift value
    }
    
    func handleCollision(between nodeA: SKNode, and nodeB: SKNode) {
        collisionsHandled.append((nodeA: nodeA, nodeB: nodeB))
    }
    
    func setWindVector(direction: CGFloat, strength: CGFloat) {
        let radians = direction * .pi / 180
        windVector = CGVector(dx: cos(radians) * strength, dy: sin(radians) * strength)
    }
    
    func applyWind(to airplane: PaperAirplane) {
        // Mock implementation - just track that it was called
    }
    
    func updateRandomWind() {
        windUpdates += 1
    }
    
    func transitionWindVector(toDirection direction: CGFloat, strength: CGFloat, duration: TimeInterval) {
        windTransitions.append((direction: direction, strength: strength, duration: duration))
    }
    
    func applyAdvancedFlightControls(to airplane: PaperAirplane, motion: CMDeviceMotion) {
        advancedControlsApplications.append((airplane: airplane, motion: motion))
    }
    
    func applyTurbulence(to airplane: PaperAirplane) {
        turbulenceApplications.append(airplane)
    }
    
    // Test helper methods
    func reset() {
        configuredScenes.removeAll()
        deviceMotionStarted = false
        deviceMotionStopped = false
        physicsSimulationStarted = false
        physicsSimulationStopped = false
        forcesApplied.removeAll()
        liftCalculations.removeAll()
        collisionsHandled.removeAll()
        windTransitions.removeAll()
        windUpdates = 0
        turbulenceApplications.removeAll()
        advancedControlsApplications.removeAll()
        isActive = false
        windVector = CGVector.zero
        sensitivity = 1.0
    }
}

// MARK: - Mock Game Center Service

class MockGameCenterService: GameCenterServiceProtocol {
    var isAuthenticated: Bool = false
    var playerDisplayName: String?
    
    // Test tracking properties
    var authenticationAttempts: Int = 0
    var scoresSubmitted: [(score: Int, leaderboardID: String)] = []
    var leaderboardsLoaded: [String] = []
    var achievementsReported: [(identifier: String, percentComplete: Double)] = []
    var achievementsLoaded: Int = 0
    var leaderboardsShown: Int = 0
    var achievementsShown: Int = 0
    var challengeCodesGenerated: [String] = []
    var challengeCodesValidated: [String] = []
    
    // Mock data for responses
    var mockLeaderboardEntries: [GameCenterLeaderboardEntry] = []
    var mockAchievements: [GKAchievement] = []
    var shouldFailAuthentication: Bool = false
    var shouldFailScoreSubmission: Bool = false
    var shouldFailLeaderboardLoad: Bool = false
    var shouldFailAchievementReport: Bool = false
    var shouldFailAchievementLoad: Bool = false
    var shouldFailChallengeValidation: Bool = false
    
    func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        authenticationAttempts += 1
        
        if shouldFailAuthentication {
            completion(false, GameCenterServiceError.notAuthenticated)
        } else {
            isAuthenticated = true
            playerDisplayName = "Test Player"
            completion(true, nil)
        }
    }
    
    func submitScore(_ score: Int, to leaderboardID: String, completion: @escaping (Error?) -> Void) {
        scoresSubmitted.append((score: score, leaderboardID: leaderboardID))
        
        if shouldFailScoreSubmission {
            completion(GameCenterServiceError.submissionFailed)
        } else {
            completion(nil)
        }
    }
    
    func loadLeaderboard(for leaderboardID: String, completion: @escaping ([GameCenterLeaderboardEntry]?, Error?) -> Void) {
        leaderboardsLoaded.append(leaderboardID)
        
        if shouldFailLeaderboardLoad {
            completion(nil, GameCenterServiceError.leaderboardNotFound)
        } else {
            completion(mockLeaderboardEntries, nil)
        }
    }
    
    func reportAchievement(identifier: String, percentComplete: Double, completion: @escaping (Error?) -> Void) {
        achievementsReported.append((identifier: identifier, percentComplete: percentComplete))
        
        if shouldFailAchievementReport {
            completion(GameCenterServiceError.achievementNotFound)
        } else {
            completion(nil)
        }
    }
    
    func loadAchievements(completion: @escaping ([GKAchievement]?, Error?) -> Void) {
        achievementsLoaded += 1
        
        if shouldFailAchievementLoad {
            completion(nil, GameCenterServiceError.networkError)
        } else {
            completion(mockAchievements, nil)
        }
    }
    
    func showLeaderboards(from presentingViewController: UIViewController) {
        leaderboardsShown += 1
    }
    
    func showAchievements(from presentingViewController: UIViewController) {
        achievementsShown += 1
    }
    
    func generateChallengeCode(for courseData: String) -> String {
        let code = "TEST_\(challengeCodesGenerated.count + 1)"
        challengeCodesGenerated.append(code)
        return code
    }
    
    func validateChallengeCode(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        challengeCodesValidated.append(code)
        
        if shouldFailChallengeValidation {
            completion(.failure(GameCenterServiceError.invalidChallengeCode))
        } else {
            completion(.success("Mock course data for \(code)"))
        }
    }
    
    // Test helper methods
    func reset() {
        isAuthenticated = false
        playerDisplayName = nil
        authenticationAttempts = 0
        scoresSubmitted.removeAll()
        leaderboardsLoaded.removeAll()
        achievementsReported.removeAll()
        achievementsLoaded = 0
        leaderboardsShown = 0
        achievementsShown = 0
        challengeCodesGenerated.removeAll()
        challengeCodesValidated.removeAll()
        mockLeaderboardEntries.removeAll()
        mockAchievements.removeAll()
        shouldFailAuthentication = false
        shouldFailScoreSubmission = false
        shouldFailLeaderboardLoad = false
        shouldFailAchievementReport = false
        shouldFailAchievementLoad = false
        shouldFailChallengeValidation = false
    }
}

// MARK: - Mock Network Service

class MockNetworkService: NetworkServiceProtocol {
    // Configuration properties
    var shouldSimulateError = false
    var simulatedError: Error = NetworkServiceError.networkUnavailable
    var shouldFailInitially = false
    var simulateTimeout = false
    var shouldFailRequests = false
    var networkDelay: TimeInterval = 0.1
    
    // Mock data
    var mockWeeklySpecials: [WeeklySpecial] = [WeeklySpecial.sample()]
    var mockLeaderboardEntries: [WeeklySpecialLeaderboardEntry] = []
    var mockDailyRuns: [String: DailyRun] = [:]
    
    // Test tracking properties
    var challengesLoaded: [String] = []
    var weeklySpecialsLoaded: Int = 0
    var dailyRunResultsSubmitted: [DailyRunResult] = []
    var dailyRunsLoaded: [Date] = []
    var requestsPerformed: [String] = []
    
    // Callback for custom behavior
    var onRequest: (() throws -> String)?
    
    func loadChallenge(code: String) async throws -> Challenge {
        challengesLoaded.append(code)
        
        if shouldSimulateError {
            throw simulatedError
        }
        
        if code == "INVALID" {
            throw ChallengeError.invalidCode
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        
        return Challenge(
            id: "mock_challenge_\(code)",
            title: "Mock Challenge",
            description: "A mock challenge for testing",
            courseData: ChallengeData(
                environmentType: "sunny_meadows",
                obstacles: [
                    ObstacleConfiguration(type: "tree", position: CGPoint(x: 100, y: 200))
                ],
                collectibles: [
                    CollectibleConfiguration(type: "coin", position: CGPoint(x: 150, y: 100), value: 10)
                ],
                weatherConditions: WeatherConfiguration(windSpeed: 0.3, windDirection: 45),
                difficulty: .medium
            ),
            expirationDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            createdBy: "MockUser"
        )
    }
    
    func loadWeeklySpecial() async throws -> WeeklySpecial {
        weeklySpecialsLoaded += 1
        
        if shouldSimulateError || shouldFailRequests {
            throw simulatedError
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        
        return WeeklySpecial(
            id: "mock_weekly_\(Date().timeIntervalSince1970)",
            title: "Mock Weekly Special",
            description: "A mock weekly special for testing",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            challengeData: WeeklySpecialChallengeData(
                environmentType: "alpine_heights",
                specialRules: ["double_coins"],
                targetScore: 2000,
                leaderboardId: "mock_weekly_leaderboard"
            ),
            rewards: WeeklySpecialRewards(
                coins: 200,
                exclusiveAirplane: "weekly_special_plane",
                achievements: ["weekly_champion"]
            )
        )
    }
    
    func submitDailyRunResult(_ result: DailyRunResult) async throws {
        dailyRunResultsSubmitted.append(result)
        
        if shouldSimulateError || shouldFailRequests {
            throw simulatedError
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        
        // Mock successful submission
        Logger.shared.info("Mock: Submitted daily run result with score \(result.score)", category: .game)
    }
    
    func loadDailyRun(for date: Date) async throws -> DailyRun? {
        dailyRunsLoaded.append(date)
        
        if shouldSimulateError || shouldFailRequests {
            throw simulatedError
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        
        let dateKey = DateFormatter().string(from: date)
        return mockDailyRuns[dateKey]
    }
    
    // Additional methods for compatibility with different test implementations
    func performRequest(_ endpoint: String) async throws -> String {
        requestsPerformed.append(endpoint)
        
        if simulateTimeout {
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            throw NetworkError.timeout
        }
        
        if let onRequest = onRequest {
            return try onRequest()
        }
        
        if shouldFailInitially {
            throw NetworkError.connectionFailed
        }
        
        return "Mock response for \(endpoint)"
    }
    
    func get<T: Codable>(endpoint: String, responseType: T.Type) async throws -> T {
        requestsPerformed.append(endpoint)
        
        if shouldFailRequests {
            throw WeeklySpecialError.networkError
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        
        if endpoint.contains("weekly-specials") && !endpoint.contains("leaderboard") {
            if let specials = mockWeeklySpecials as? T {
                return specials
            }
        } else if endpoint.contains("leaderboard") {
            if let entries = mockLeaderboardEntries as? T {
                return entries
            }
        }
        
        throw WeeklySpecialError.notFound
    }
    
    func post<T: Codable>(endpoint: String, payload: [String: Any]) async throws -> T? {
        requestsPerformed.append(endpoint)
        
        if shouldFailRequests {
            throw WeeklySpecialError.submissionFailed
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        
        return nil
    }
    
    // Test helper methods
    func reset() {
        challengesLoaded.removeAll()
        weeklySpecialsLoaded = 0
        dailyRunResultsSubmitted.removeAll()
        dailyRunsLoaded.removeAll()
        requestsPerformed.removeAll()
        shouldSimulateError = false
        shouldFailInitially = false
        simulateTimeout = false
        shouldFailRequests = false
        networkDelay = 0.1
        onRequest = nil
        mockWeeklySpecials = [WeeklySpecial.sample()]
        mockLeaderboardEntries.removeAll()
        mockDailyRuns.removeAll()
    }
    
    func addMockDailyRun(_ dailyRun: DailyRun, for date: Date) {
        let dateKey = DateFormatter().string(from: date)
        mockDailyRuns[dateKey] = dailyRun
    }
    
    func addMockLeaderboardEntry(_ entry: WeeklySpecialLeaderboardEntry) {
        mockLeaderboardEntries.append(entry)
    }
}

// MARK: - Network Error Types

enum NetworkError: Error {
    case connectionFailed
    case timeout
    case invalidResponse
    case serverError(Int)
}

enum ChallengeError: Error {
    case invalidCode
    case expired
    case notFound
}

// MARK: - Mock SwiftData Manager (if needed for repository testing)

class MockSwiftDataManager {
    private var storage: [String: Any] = [:]
    
    // Test tracking properties
    var saveOperations: [String] = []
    var fetchOperations: [String] = []
    var deleteOperations: [String] = []
    
    func save<T>(_ object: T, type: String) {
        storage[type] = object
        saveOperations.append(type)
    }
    
    func fetch<T>(_ type: T.Type) -> [T] {
        fetchOperations.append(String(describing: type))
        if let objects = storage[String(describing: type)] as? [T] {
            return objects
        }
        return []
    }
    
    func delete<T>(_ object: T, type: String) {
        storage.removeValue(forKey: type)
        deleteOperations.append(type)
    }
    
    // Test helper methods
    func reset() {
        storage.removeAll()
        saveOperations.removeAll()
        fetchOperations.removeAll()
        deleteOperations.removeAll()
    }
}

// MARK: - Test Helper Extensions

extension MockAudioService {
    func simulateError(_ error: AudioServiceError) {
        // Could be used to test error handling scenarios
    }
    
    // Common test scenarios
    func simulateGameplayAudio() {
        playSound("game_start")
        playMusic("background_music")
        playSound("airplane_whoosh")
        playSound("coin_collect")
    }
    
    func simulateMenuAudio() {
        playSound("menu_select")
        playSound("menu_back")
        playMusic("menu_music")
    }
    
    func simulateVolumeChanges() {
        soundVolume = 0.5
        musicVolume = 0.3
        setMasterVolume(0.8)
    }
    
    func verifyGameplayAudioPlayed() -> Bool {
        return soundsPlayed.contains("game_start") &&
               musicTracksPlayed.contains("background_music") &&
               soundsPlayed.contains("airplane_whoosh")
    }
}

extension MockPhysicsService {
    func simulateError(_ error: PhysicsServiceError) {
        // Could be used to test error handling scenarios
    }
    
    // Common test scenarios
    func simulateGameplayPhysics(with airplane: PaperAirplane) {
        startDeviceMotionUpdates()
        startPhysicsSimulation()
        applyForces(to: airplane, tiltX: 0.5, tiltY: -0.3)
        _ = calculateLift(for: airplane)
        applyWind(to: airplane)
        applyTurbulence(to: airplane)
    }
    
    func simulateWindyConditions() {
        setWindVector(direction: 45, strength: 15)
        updateRandomWind()
        transitionWindVector(toDirection: 90, strength: 20, duration: 2.0)
    }
    
    func simulateCollisionScenario(nodeA: SKNode, nodeB: SKNode) {
        handleCollision(between: nodeA, and: nodeB)
    }
    
    func verifyPhysicsActive() -> Bool {
        return deviceMotionStarted && physicsSimulationStarted && isActive
    }
    
    func verifyForcesApplied(to airplane: PaperAirplane) -> Bool {
        return forcesApplied.contains { $0.airplane === airplane }
    }
}

extension MockGameCenterService {
    func simulateError(_ error: GameCenterServiceError) {
        // Could be used to test error handling scenarios
    }
    
    func addMockLeaderboardEntry(playerID: String, displayName: String, score: Int, rank: Int) {
        let entry = GameCenterLeaderboardEntry(
            playerID: playerID,
            displayName: displayName,
            score: score,
            rank: rank,
            date: Date()
        )
        mockLeaderboardEntries.append(entry)
    }
    
    func addMockAchievement(identifier: String, percentComplete: Double = 100.0) {
        let achievement = GKAchievement(identifier: identifier)
        achievement.percentComplete = percentComplete
        mockAchievements.append(achievement)
    }
    
    // Common test scenarios
    func simulateSuccessfulAuthentication() {
        isAuthenticated = true
        playerDisplayName = "Test Player"
    }
    
    func simulateGameCenterInteraction() {
        authenticate { _, _ in }
        submitScore(1000, to: "high_score") { _ in }
        loadLeaderboard(for: "high_score") { _, _ in }
        reportAchievement(identifier: "first_flight", percentComplete: 100.0) { _ in }
    }
    
    func simulateLeaderboardData() {
        addMockLeaderboardEntry(playerID: "player1", displayName: "Player 1", score: 1500, rank: 1)
        addMockLeaderboardEntry(playerID: "player2", displayName: "Player 2", score: 1200, rank: 2)
        addMockLeaderboardEntry(playerID: "player3", displayName: "Player 3", score: 1000, rank: 3)
    }
    
    func simulateAchievementData() {
        addMockAchievement(identifier: "first_flight", percentComplete: 100.0)
        addMockAchievement(identifier: "distance_master", percentComplete: 75.0)
        addMockAchievement(identifier: "coin_collector", percentComplete: 50.0)
    }
    
    func simulateNetworkFailures() {
        shouldFailAuthentication = true
        shouldFailScoreSubmission = true
        shouldFailLeaderboardLoad = true
        shouldFailAchievementReport = true
        shouldFailAchievementLoad = true
    }
    
    func verifyGameCenterActivity() -> Bool {
        return authenticationAttempts > 0 && 
               !scoresSubmitted.isEmpty && 
               !leaderboardsLoaded.isEmpty
    }
}

// MARK: - Common Test Scenario Helpers

class TestScenarioHelper {
    static func createMockAirplane() -> PaperAirplane {
        let airplane = PaperAirplane()
        airplane.position = CGPoint(x: 100, y: 100)
        airplane.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 10))
        return airplane
    }
    
    static func createMockScene() -> SKScene {
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        scene.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        return scene
    }
    
    static func setupMockServices() -> (MockAudioService, MockPhysicsService, MockGameCenterService) {
        let audioService = MockAudioService()
        let physicsService = MockPhysicsService()
        let gameCenterService = MockGameCenterService()
        
        // Set up common initial states
        audioService.soundEnabled = true
        audioService.musicEnabled = true
        physicsService.sensitivity = 1.0
        gameCenterService.simulateSuccessfulAuthentication()
        
        return (audioService, physicsService, gameCenterService)
    }
    
    static func resetAllMockServices(_ audioService: MockAudioService, 
                                   _ physicsService: MockPhysicsService, 
                                   _ gameCenterService: MockGameCenterService) {
        audioService.reset()
        physicsService.reset()
        gameCenterService.reset()
    }
}