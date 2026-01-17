//
//  GameManager.swift
//  Tiny Pilots
//
//  Created by Kiro on Build Fixes Implementation
//

import Foundation
import Combine

/// Game mode enumeration for GameManager
enum GameMode: String, CaseIterable, Codable {
    case tutorial = "tutorial"
    case freePlay = "freePlay"
    case challenge = "challenge"
    case dailyRun = "dailyRun"
    case weeklySpecial = "weeklySpecial"
    
    var displayName: String {
        switch self {
        case .tutorial: return "Tutorial"
        case .freePlay: return "Free Play"
        case .challenge: return "Challenge"
        case .dailyRun: return "Daily Run"
        case .weeklySpecial: return "Weekly Special"
        }
    }
    
    var iconName: String {
        switch self {
        case .tutorial: return "📘"
        case .freePlay: return "🛩️"
        case .challenge: return "🏁"
        case .dailyRun: return "📅"
        case .weeklySpecial: return "⭐️"
        }
    }
    
    var description: String {
        switch self {
        case .tutorial: return "Learn the basics of flight"
        case .freePlay: return "Practice with no limits"
        case .challenge: return "Custom challenges with friends"
        case .dailyRun: return "A new challenge every day"
        case .weeklySpecial: return "Limited-time weekly event"
        }
    }
    
    // requiredLevel defined in MainMenuViewModel extension
}

/// Concrete implementation of GameManagerProtocol
class GameManager: GameManagerProtocol {
    // Expose nested type alias so callers can reference GameManager.GameMode
    // This maps to the app-wide GameMode enum declared above
    typealias GameMode = Tiny_Pilots.GameMode
    static let shared = GameManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var score: Int = 0
    @Published private(set) var level: Int = 1
    @Published private(set) var gameState: GameState = .initial
    
    // MARK: - Computed Properties
    
    var scorePublisher: AnyPublisher<Int, Never> {
        return $score.eraseToAnyPublisher()
    }
    
    var levelPublisher: AnyPublisher<Int, Never> {
        return $level.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    
    private let gameStateManager = GameStateManager.shared
    private let logger = Logger.shared
    private let analytics = AnalyticsManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var pendingMode: GameState.Mode = .freePlay
    private var lastUpdateTimestamp: TimeInterval?
    
    // Temporary player data store (to be integrated with SwiftData)
    private(set) var playerData: PlayerData = PlayerData()
    
    // Game configuration constants
    private let baseScorePerLevel = 1000
    private let difficultyIncrement: Float = 0.15
    private let maxDifficulty: Float = 3.0
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
        logger.info("GameManager initialized", category: .game)
    }
    
    private func setupObservers() {
        // Observe game state changes from GameStateManager
        gameStateManager.gameStatePublisher
            .sink { [weak self] newState in
                self?.handleGameStateChange(newState)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func initializeGame(mode: GameState.Mode = .freePlay, environmentType: String = "standard") {
        logger.info("Initializing game - Mode: \(mode.displayName), Environment: \(environmentType)", category: .game)
        
        // Reset local state
        score = 0
        level = 1
        
        // Start the game through GameStateManager
        gameStateManager.startGame(mode: mode, environmentType: environmentType)
        
        // Track analytics
        let analyticsMode: GameMode = convertToAnalyticsGameMode(mode)
        analytics.trackEvent(.gameStarted(mode: analyticsMode, environment: environmentType))
        
        logger.info("Game initialized successfully", category: .game)
    }

    // MARK: - Back-compat API used by scenes
    
    var currentState: GameState { gameStateManager.currentState }
    var currentMode: GameState.Mode { gameStateManager.currentState.mode }
    var currentEnvironmentType: String { gameStateManager.currentState.environmentType }
    var distanceTraveled: Float { gameStateManager.currentState.distance }
    var gameTime: TimeInterval { gameStateManager.currentState.timeElapsed }
    
    func setGameMode(_ mode: GameState.Mode) {
        pendingMode = mode
    }
    
    func startGame() {
        gameStateManager.startGame(mode: pendingMode, environmentType: currentEnvironmentType)
        lastUpdateTimestamp = nil
    }
    
    func pauseGame() {
        gameStateManager.pauseGame()
    }
    
    func resumeGame() {
        gameStateManager.resumeGame()
    }
    
    func endGame() {
        gameStateManager.endGame()
    }
    
    func stopGame() {
        gameStateManager.resetGame()
        lastUpdateTimestamp = nil
    }
    
    func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTimestamp = currentTime }
        guard let last = lastUpdateTimestamp else { return }
        let delta = max(0, currentTime - last)
        let newTime = gameStateManager.currentState.timeElapsed + delta
        gameStateManager.updateTimeElapsed(newTime)
    }
    
    func addDistance(_ additionalDistance: Float) {
        gameStateManager.addDistance(additionalDistance)
    }
    
    func updateScore(_ newScore: Int) {
        let previousScore = score
        score = max(0, newScore)
        
        // Update the game state manager
        gameStateManager.updateScore(score)
        
        logger.debug("Score updated: \(previousScore) → \(score)", category: .game)
        
        // Check for level progression
        checkLevelProgression()
    }
    
    func addScore(_ points: Int) {
        updateScore(score + points)
    }
    
    func nextLevel() {
        let previousLevel = level
        level += 1
        
        logger.info("Advanced to level \(level)", category: .game)
        
        // Track analytics
        analytics.trackEvent(.achievementUnlocked(achievementId: "level_\(level)"))
        
        // Notify about level change
        NotificationCenter.default.post(
            name: .gameManagerLevelChanged,
            object: self,
            userInfo: ["previousLevel": previousLevel, "newLevel": level]
        )
    }
    
    /// Legacy adapter used by scenes to adjust score on obstacle collision
    func adjustScoreForObstacle() {
        // Treat as collision and apply a score penalty
        // Use existing collision handling to keep behavior consistent
        handleCollision(.obstacle)
        // Apply an additional mild penalty to make collisions impactful
        let penalty = max(50, calculateCollectiblePoints() / 2)
        updateScore(max(0, score - penalty))
    }
    
    /// Legacy adapter used by scenes to add a collected coin and award points
    func addCoin() {
        gameStateManager.addCoin()
        let points = calculateCollectiblePoints()
        addScore(points)
    }
    
    func handleCollision(_ collision: CollisionType) {
        logger.debug("Handling collision: \(collision)", category: .game)
        
        switch collision {
        case .obstacle:
            handleObstacleCollision()
        case .collectible:
            handleCollectibleCollision()
        case .powerUp:
            handlePowerUpCollision()
        case .boundary:
            handleBoundaryCollision()
        }
    }
    
    func getGameConfiguration() -> GameConfiguration {
        return GameConfiguration(
            level: level,
            difficulty: calculateDifficulty(),
            environmentType: gameState.environmentType,
            mode: gameState.mode,
            targetScore: getNextLevelThreshold(),
            timeLimit: getTimeLimitForMode(),
            specialRules: getSpecialRulesForMode()
        )
    }
    
    func canProgressToNextLevel() -> Bool {
        return score >= getNextLevelThreshold()
    }
    
    func getNextLevelThreshold() -> Int {
        return level * baseScorePerLevel
    }
    
    func reset() {
        logger.info("Resetting GameManager", category: .game)
        
        score = 0
        level = 1
        gameState = .initial
        
        // Reset the game state manager
        gameStateManager.resetGame()
    }
    
    // MARK: - Private Methods
    
    private func handleGameStateChange(_ newState: GameState) {
        let previousState = gameState
        gameState = newState
        
        // Sync local properties with game state
        if gameState.score != score {
            score = gameState.score
        }
        
        // Handle state transitions
        if previousState.status != newState.status {
            handleStatusChange(from: previousState.status, to: newState.status)
        }
        
        logger.debug("Game state synchronized: \(newState.status.displayName)", category: .game)
    }
    
    private func handleStatusChange(from oldStatus: GameState.Status, to newStatus: GameState.Status) {
        switch (oldStatus, newStatus) {
        case (_, .playing):
            logger.info("Game started/resumed", category: .game)
            
        case (.playing, .paused):
            let duration = gameStateManager.getCurrentSessionDuration() ?? 0
            analytics.trackEvent(.gamePaused(duration: duration))
            
        case (.paused, .playing):
            analytics.trackEvent(.gameResumed)
            
        case (_, .ended) where oldStatus != .ended:
            handleGameEnd()
            
        default:
            break
        }
    }
    
    private func handleGameEnd() {
        let duration = gameStateManager.getCurrentSessionDuration() ?? 0
        let analyticsMode: GameMode = convertToAnalyticsGameMode(gameState.mode)
        analytics.trackEvent(.gameCompleted(mode: analyticsMode, score: score, duration: duration, environment: gameState.environmentType))
        
        logger.info("Game ended - Final Score: \(score), Level: \(level), Duration: \(String(format: "%.1f", duration))s", category: .game)
    }
    
    private func checkLevelProgression() {
        if canProgressToNextLevel() {
            nextLevel()
        }
    }
    
    private func calculateDifficulty() -> Float {
        let baseDifficulty: Float = 1.0
        let levelDifficulty = baseDifficulty + Float(level - 1) * difficultyIncrement
        return min(levelDifficulty, maxDifficulty)
    }
    
    private func getTimeLimitForMode() -> TimeInterval? {
        switch gameState.mode {
        case .dailyRun:
            return 300 // 5 minutes for daily runs
        case .challenge:
            return 180 // 3 minutes for challenges
        default:
            return nil // No time limit for other modes
        }
    }
    
    private func getSpecialRulesForMode() -> [String: Any] {
        switch gameState.mode {
        case .tutorial:
            return [
                "showHints": true,
                "reducedDifficulty": true,
                "skipObstacles": false
            ]
        case .dailyRun:
            return [
                "fixedSeed": true,
                "noRetries": true,
                "leaderboardEligible": true
            ]
        case .challenge:
            return [
                "customObstacles": true,
                "bonusMultiplier": 2.0
            ]
        default:
            return [:]
        }
    }
    
    private func convertToAnalyticsGameMode(_ mode: GameState.Mode) -> GameMode {
        switch mode {
        case .tutorial: return .tutorial
        case .freePlay: return .freePlay
        case .challenge: return .challenge
        case .dailyRun: return .dailyRun
        case .weeklySpecial: return .weeklySpecial
        }
    }
    
    // MARK: - Collision Handlers
    
    private func handleObstacleCollision() {
        logger.info("Obstacle collision - ending game", category: .game)
        gameStateManager.endGame()
    }
    
    private func handleCollectibleCollision() {
        let points = calculateCollectiblePoints()
        addScore(points)
        gameStateManager.addCoin()
        
        logger.debug("Collectible collected - awarded \(points) points", category: .game)
    }
    
    private func handlePowerUpCollision() {
        let points = calculatePowerUpPoints()
        addScore(points)
        
        logger.debug("Power-up collected - awarded \(points) points", category: .game)
        
        // Power-ups could trigger special effects here
        NotificationCenter.default.post(
            name: .gameManagerPowerUpCollected,
            object: self,
            userInfo: ["points": points, "level": level]
        )
    }
    
    private func handleBoundaryCollision() {
        logger.warning("Boundary collision detected", category: .game)
        // Boundary collisions might not end the game but could apply penalties
        // For now, we'll just log it
    }
    
    private func calculateCollectiblePoints() -> Int {
        let basePoints = 100
        let levelMultiplier = Float(level)
        let difficultyBonus = calculateDifficulty() - 1.0
        
        return Int(Float(basePoints) * levelMultiplier * (1.0 + difficultyBonus))
    }
    
    private func calculatePowerUpPoints() -> Int {
        return calculateCollectiblePoints() * 2 // Power-ups are worth double
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let gameManagerLevelChanged = Notification.Name("GameManagerLevelChanged")
    static let gameManagerPowerUpCollected = Notification.Name("GameManagerPowerUpCollected")
}

// MARK: - GameManager Statistics

extension GameManager {
    /// Get current game statistics
    func getGameStatistics() -> GameStatistics {
        return GameStatistics(
            score: score,
            level: level,
            difficulty: calculateDifficulty(),
            timeElapsed: gameState.timeElapsed,
            distance: gameState.distance,
            coinsCollected: gameState.coinsCollected,
            mode: gameState.mode,
            environmentType: gameState.environmentType
        )
    }
    
    /// Get performance metrics for the current game
    func getPerformanceMetrics() -> [String: Any] {
        let sessionDuration = gameStateManager.getCurrentSessionDuration() ?? 0
        let scorePerSecond = sessionDuration > 0 ? Double(score) / sessionDuration : 0
        
        return [
            "score_per_second": scorePerSecond,
            "level_progression_rate": sessionDuration > 0 ? Double(level) / sessionDuration : 0,
            "coins_per_minute": sessionDuration > 0 ? Double(gameState.coinsCollected) / (sessionDuration / 60) : 0,
            "distance_per_second": sessionDuration > 0 ? Double(gameState.distance) / sessionDuration : 0
        ]
    }
}

/// Game statistics structure
struct GameStatistics {
    let score: Int
    let level: Int
    let difficulty: Float
    let timeElapsed: TimeInterval
    let distance: Float
    let coinsCollected: Int
    let mode: GameState.Mode
    let environmentType: String
    
    var description: String {
        return """
        Game Statistics:
        - Score: \(score)
        - Level: \(level)
        - Difficulty: \(String(format: "%.2f", difficulty))
        - Time: \(String(format: "%.1f", timeElapsed))s
        - Distance: \(String(format: "%.1f", distance))m
        - Coins: \(coinsCollected)
        - Mode: \(mode.displayName)
        - Environment: \(environmentType)
        """
    }
}