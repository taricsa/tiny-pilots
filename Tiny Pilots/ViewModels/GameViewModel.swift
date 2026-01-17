//
//  GameViewModel.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation
import Observation
import SwiftData
import SpriteKit

/// ViewModel for managing game state and coordinating gameplay
@Observable
class GameViewModel: BaseViewModel {
    
    // MARK: - Properties
    
    /// Current game state
    private(set) var gameState: GameState = GameState.initial
    
    /// Current player data
    private(set) var playerData: PlayerData?
    
    /// Whether the game is currently active
    var isGameActive: Bool {
        return gameState.isActive
    }
    
    /// Whether the game can be paused
    var canPause: Bool {
        return gameState.canPause
    }
    
    /// Whether the game can be resumed
    var canResume: Bool {
        return gameState.canResume
    }
    
    /// Whether the game can be started
    var canStart: Bool {
        return gameState.canStart
    }
    
    /// Current score formatted for display
    var formattedScore: String {
        return NumberFormatter.localizedString(from: NSNumber(value: gameState.score), number: .decimal)
    }
    
    /// Current distance formatted for display
    var formattedDistance: String {
        return String(format: "%.1f m", gameState.distance)
    }
    
    /// Current time formatted for display
    var formattedTime: String {
        let minutes = Int(gameState.timeElapsed) / 60
        let seconds = Int(gameState.timeElapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Current coins formatted for display
    var formattedCoins: String {
        return "\(gameState.coinsCollected)"
    }
    
    // MARK: - Dependencies
    
    private var physicsService: PhysicsServiceProtocol
    private let audioService: AudioServiceProtocol
    private let gameCenterService: GameCenterServiceProtocol
    private let modelContext: ModelContext
    
    // MARK: - Private Properties
    
    private var gameStartTime: Date?
    private var gamePauseTime: Date?
    private var totalPauseDuration: TimeInterval = 0
    private var gameUpdateTimer: Timer?
    
    // MARK: - Initialization
    
    init(
        physicsService: PhysicsServiceProtocol,
        audioService: AudioServiceProtocol,
        gameCenterService: GameCenterServiceProtocol,
        modelContext: ModelContext
    ) {
        self.physicsService = physicsService
        self.audioService = audioService
        self.gameCenterService = gameCenterService
        self.modelContext = modelContext
        
        super.init()
    }
    
    // MARK: - BaseViewModel Overrides
    
    override func performInitialization() {
        loadPlayerData()
        setupPhysicsService()
    }
    
    override func performCleanup() {
        stopGameUpdateTimer()
        physicsService.stopDeviceMotionUpdates()
        physicsService.stopPhysicsSimulation()
    }
    
    override func handle(_ action: ViewAction) {
        switch action {
        case let startAction as StartGameAction:
            handleStartGame(mode: startAction.gameMode)
        case is PauseGameAction:
            handlePauseGame()
        case is ResumeGameAction:
            handleResumeGame()
        case is EndGameAction:
            handleEndGame()
        case let tiltAction as TiltInputAction:
            handleTiltInput(x: tiltAction.x, y: tiltAction.y)
        default:
            super.handle(action)
        }
    }
    
    // MARK: - Game Flow Methods
    
    /// Start a new game with the specified mode
    /// - Parameter mode: The game mode to start
    func startGame(mode: GameState.Mode) {
        startGame(mode: mode, challengeCode: nil, weeklySpecialID: nil)
    }
    
    /// Start a new game with the specified mode and optional parameters
    /// - Parameters:
    ///   - mode: The game mode to start
    ///   - challengeCode: Optional challenge code for challenge mode
    ///   - weeklySpecialID: Optional weekly special ID for weekly special mode
    func startGame(mode: GameState.Mode, challengeCode: String? = nil, weeklySpecialID: String? = nil) {
        guard canStart else { return }
        
        setLoading(true)
        clearError()
        
        // Determine environment type based on mode and parameters
        var environmentType = playerData?.unlockedEnvironments.first ?? "standard"
        
        // For weekly specials, load the specific environment
        if mode == .weeklySpecial, let weeklySpecialID = weeklySpecialID {
            Task {
                do {
                    let weeklySpecialService = try DIContainer.shared.resolve(WeeklySpecialServiceProtocol.self)
                    let weeklySpecial = try await weeklySpecialService.getWeeklySpecial(id: weeklySpecialID)
                    
                    await MainActor.run {
                        environmentType = weeklySpecial.environment
                        self.continueGameStart(mode: mode, environmentType: environmentType, challengeCode: challengeCode, weeklySpecialID: weeklySpecialID)
                    }
                } catch {
                    await MainActor.run {
                        self.setError(error)
                        self.setLoading(false)
                    }
                    return
                }
            }
        } else {
            continueGameStart(mode: mode, environmentType: environmentType, challengeCode: challengeCode, weeklySpecialID: weeklySpecialID)
        }
    }
    
    private func continueGameStart(mode: GameState.Mode, environmentType: String, challengeCode: String?, weeklySpecialID: String?) {
        // Create new game state
        gameState = GameState(
            mode: mode,
            status: .playing,
            score: 0,
            distance: 0,
            timeElapsed: 0,
            coinsCollected: 0,
            environmentType: environmentType,
            startTime: Date(),
            endTime: nil
        )
        
        // Store additional context for special modes
        if let challengeCode = challengeCode {
            // Store challenge code for later use
            UserDefaults.standard.set(challengeCode, forKey: "current_challenge_code")
        }
        
        if let weeklySpecialID = weeklySpecialID {
            // Store weekly special ID for later use
            UserDefaults.standard.set(weeklySpecialID, forKey: "current_weekly_special_id")
        }
        
        // Initialize game systems
        gameStartTime = Date()
        gamePauseTime = nil
        totalPauseDuration = 0
        
        // Start physics and audio
        physicsService.startDeviceMotionUpdates()
        physicsService.startPhysicsSimulation()
        
        // Play background music based on mode
        let musicTrack = getMusicTrack(for: mode)
        audioService.playMusic(musicTrack, volume: nil, loop: true, fadeIn: 1.0)
        
        // Start game update timer
        startGameUpdateTimer()
        
        setLoading(false)
        
        // Play start sound
        audioService.playSound("game_start", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Pause the current game
    func pauseGame() {
        guard canPause else { return }
        
        gameState = gameState.pause()
        gamePauseTime = Date()
        
        // Pause physics and audio
        physicsService.stopDeviceMotionUpdates()
        audioService.pauseMusic()
        
        // Stop update timer
        stopGameUpdateTimer()
        
        // Play pause sound
        audioService.playSound("game_pause", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Resume the paused game
    func resumeGame() {
        guard canResume else { return }
        
        gameState = gameState.resume()
        
        // Calculate pause duration
        if let pauseTime = gamePauseTime {
            totalPauseDuration += Date().timeIntervalSince(pauseTime)
            gamePauseTime = nil
        }
        
        // Resume physics and audio
        physicsService.startDeviceMotionUpdates()
        audioService.resumeMusic()
        
        // Restart update timer
        startGameUpdateTimer()
        
        // Play resume sound
        audioService.playSound("game_resume", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// End the current game
    func endGame() {
        guard gameState.isActive else { return }
        
        gameState = gameState.end()
        
        // Stop game systems
        stopGameUpdateTimer()
        physicsService.stopDeviceMotionUpdates()
        physicsService.stopPhysicsSimulation()
        
        // Stop music with fade out
        audioService.stopMusic(fadeOut: 2.0)
        
        // Save game result
        saveGameResult()
        
        // Submit score to Game Center
        submitScoreToGameCenter()
        
        // Check achievements
        checkAchievements()
        
        // Track significant events for rating system
        trackSignificantEventsForRating()
        
        // Track game session completion
        AppRatingManager.shared.trackGameSessionCompleted()
        
        // Play end sound
        audioService.playSound("game_end", volume: nil, pitch: 1.0, completion: nil)
    }
    
    // MARK: - Game Update Methods
    
    /// Update game state with new score
    /// - Parameter score: New score value
    func updateScore(_ score: Int) {
        guard gameState.status == .playing else { return }
        gameState = gameState.withScore(score)
    }
    
    /// Add points to the current score
    /// - Parameter points: Points to add
    func addScore(_ points: Int) {
        guard gameState.status == .playing else { return }
        let oldScore = gameState.score
        gameState = gameState.addingScore(points)
        
        // Check for high score and announce if needed
        let isNewHighScore = checkForNewHighScore(oldScore: oldScore, newScore: gameState.score)
        AccessibilityManager.shared.announceScoreUpdate(gameState.score, isNewHighScore: isNewHighScore)
    }
    
    /// Check if the new score is a high score
    /// - Parameters:
    ///   - oldScore: Previous score
    ///   - newScore: New score
    /// - Returns: True if this is a new high score
    private func checkForNewHighScore(oldScore: Int, newScore: Int) -> Bool {
        guard let player = playerData else { return false }
        
        let currentHighScoreValue = player.highScore
        let currentHighScore = { (_: String) in currentHighScoreValue }(gameState.mode.rawValue)
        return newScore > currentHighScore && newScore > oldScore
    }
    
    /// Update distance traveled
    /// - Parameter distance: New distance value
    func updateDistance(_ distance: Float) {
        guard gameState.status == .playing else { return }
        gameState = gameState.withDistance(distance)
    }
    
    /// Add distance traveled
    /// - Parameter additionalDistance: Distance to add
    func addDistance(_ additionalDistance: Float) {
        guard gameState.status == .playing else { return }
        gameState = gameState.addingDistance(additionalDistance)
    }
    
    /// Add a collected coin
    func addCoin() {
        guard gameState.status == .playing else { return }
        gameState = gameState.addingCoin()
        
        // Play coin collection sound
        audioService.playSound("coin_collect", volume: nil, pitch: 1.0, completion: nil)
        
        // Add score bonus for coin
        addScore(100)
    }
    
    /// Handle obstacle collision
    func handleObstacleCollision() {
        guard gameState.status == .playing else { return }
        
        // Reduce score
        let penalty = 50
        let newScore = max(0, gameState.score - penalty)
        gameState = gameState.withScore(newScore)
        
        // Play collision sound
        audioService.playSound("obstacle_hit", volume: nil, pitch: 1.0, completion: nil)
    }
    
    // MARK: - Input Handling
    
    /// Handle tilt input for airplane control
    /// - Parameters:
    ///   - x: Horizontal tilt value (-1.0 to 1.0)
    ///   - y: Vertical tilt value (-1.0 to 1.0)
    func handleTiltInput(x: Double, y: Double) {
        guard gameState.status == .playing else { return }
        
        // Apply physics forces through the physics service
        // Note: This would typically be called from the game scene
        // The ViewModel coordinates but doesn't directly manipulate SpriteKit nodes
    }
    
    // MARK: - Private Methods
    
    private func handleStartGame(mode: String) {
        guard let gameMode = GameState.Mode(rawValue: mode) else {
            setErrorMessage("Invalid game mode: \(mode)")
            return
        }
        startGame(mode: gameMode)
    }
    
    private func handlePauseGame() {
        pauseGame()
    }
    
    private func handleResumeGame() {
        resumeGame()
    }
    
    private func handleEndGame() {
        endGame()
    }
    

    
    private func loadPlayerData() {
        let fetchDescriptor = FetchDescriptor<PlayerData>()
        
        do {
            let players = try modelContext.fetch(fetchDescriptor)
            playerData = players.first
            
            if playerData == nil {
                // Create new player data if none exists
                let newPlayer = PlayerData()
                modelContext.insert(newPlayer)
                try modelContext.save()
                playerData = newPlayer
            }
        } catch {
            setError(error)
        }
    }
    
    private func setupPhysicsService() {
        // Configure physics service sensitivity based on player preferences
        // This could be loaded from player settings
        physicsService.sensitivity = 1.0
    }
    
    private func startGameUpdateTimer() {
        stopGameUpdateTimer()
        
        gameUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateGameTime()
        }
    }
    
    private func stopGameUpdateTimer() {
        gameUpdateTimer?.invalidate()
        gameUpdateTimer = nil
    }
    
    private func updateGameTime() {
        guard gameState.status == .playing,
              let startTime = gameStartTime else { return }
        
        let currentTime = Date()
        let elapsedTime = currentTime.timeIntervalSince(startTime) - totalPauseDuration
        gameState = gameState.withTimeElapsed(elapsedTime)
    }
    
    private func getMusicTrack(for mode: GameState.Mode) -> String {
        switch mode {
        case .tutorial:
            return "tutorial_music"
        case .freePlay:
            return "freeplay_music"
        case .challenge:
            return "challenge_music"
        case .dailyRun:
            return "daily_run_music"
        case .weeklySpecial:
            return "special_music"
        }
    }
    
    private func saveGameResult() {
        guard let player = playerData else { return }
        
        // Create game result
        let gameResult = GameResult(
            mode: gameState.mode.rawValue,
            score: gameState.score,
            distance: gameState.distance,
            timeElapsed: gameState.timeElapsed,
            coinsCollected: gameState.coinsCollected,
            environmentType: gameState.environmentType
        )
        
        // Add to player data
        player.addGameResult(gameResult)
        
        // Update daily run streak if applicable
        if gameState.mode == .dailyRun {
            player.updateDailyRunStreak()
        }
        
        // Save to SwiftData
        do {
            modelContext.insert(gameResult)
            try modelContext.save()
        } catch {
            setError(error)
        }
    }
    
    private func submitScoreToGameCenter() {
        guard gameCenterService.isAuthenticated else { return }
        
        let leaderboardID = getLeaderboardID(for: gameState.mode)
        
        gameCenterService.submitScore(gameState.score, to: leaderboardID) { [weak self] error in
            if let error = error {
                // Don't show Game Center errors to user, just log them
                Logger.shared.warning("Failed to submit score to Game Center", category: .game)
            }
        }
        
        // Submit to weekly special service if applicable
        if gameState.mode == .weeklySpecial {
            submitScoreToWeeklySpecial()
        }
    }
    
    private func submitScoreToWeeklySpecial() {
        guard let weeklySpecialID = UserDefaults.standard.string(forKey: "current_weekly_special_id") else {
            Logger.shared.warning("No weekly special ID found for score submission", category: .game)
            return
        }
        
        Task {
            do {
                let weeklySpecialService = try DIContainer.shared.resolve(WeeklySpecialServiceProtocol.self)
                
                let gameData: [String: Any] = [
                    "score": gameState.score,
                    "distance": gameState.distance,
                    "timeElapsed": gameState.timeElapsed,
                    "coinsCollected": gameState.coinsCollected,
                    "environmentType": gameState.environmentType
                ]
                
                try await weeklySpecialService.submitScore(
                    score: gameState.score,
                    weeklySpecialId: weeklySpecialID,
                    gameData: gameData
                )
                
                Logger.shared.info("Successfully submitted score to weekly special", category: .game)
                
            } catch {
                Logger.shared.error("Failed to submit score to weekly special", error: error, category: .game)
            }
        }
    }
    
    private func getLeaderboardID(for mode: GameState.Mode) -> String {
        switch mode {
        case .tutorial:
            return "tutorial_leaderboard"
        case .freePlay:
            return "freeplay_leaderboard"
        case .challenge:
            return "challenge_leaderboard"
        case .dailyRun:
            return "daily_run_leaderboard"
        case .weeklySpecial:
            return "weekly_special_leaderboard"
        }
    }
}

// MARK: - Game Actions

extension GameViewModel {
    
    /// Restart the current game with the same mode
    func restartGame() {
        let currentMode = gameState.mode
        endGame()
        
        // Small delay to allow cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startGame(mode: currentMode)
        }
    }
    
    /// Change environment type (if unlocked)
    /// - Parameter environmentType: New environment type
    func changeEnvironment(_ environmentType: String) {
        guard let player = playerData,
              player.isContentUnlocked(environmentType, type: .environment) else {
            setErrorMessage("Environment not unlocked: \(environmentType)")
            return
        }
        
        gameState = gameState.withEnvironmentType(environmentType)
    }
    
    /// Get available environments for the current player
    var availableEnvironments: [String] {
        return playerData?.unlockedEnvironments ?? ["standard"]
    }
    
    /// Get player statistics
    var playerStatistics: PlayerStatistics? {
        return playerData?.statisticsSummary
    }
    
    /// Check if a specific achievement should be unlocked
    func checkAchievements() {
        guard let player = playerData else { return }
        
        // Check distance achievements
        if gameState.distance >= 1000 {
            unlockAchievement("distance_1000")
        }
        if gameState.distance >= 5000 {
            unlockAchievement("distance_5000")
        }
        if gameState.distance >= 10000 {
            unlockAchievement("distance_10000")
        }
        
        // Check time achievements
        if player.totalFlightTime >= 3600 { // 1 hour
            unlockAchievement("flight_time_1_hour")
        }
        
        // Check streak achievements
        if player.dailyRunStreak >= 3 {
            unlockAchievement("daily_streak_3")
        }
        if player.dailyRunStreak >= 7 {
            unlockAchievement("daily_streak_7")
        }
        if player.dailyRunStreak >= 30 {
            unlockAchievement("daily_streak_30")
        }
    }
    
    private func unlockAchievement(_ achievementId: String) {
        guard let player = playerData else { return }
        
        // Find the achievement
        if let achievement = player.achievements.first(where: { $0.id == achievementId }),
           !achievement.isUnlocked {
            
            // Update progress to completion which will unlock the achievement
            achievement.updateProgress(achievement.targetValue)
            
            // Report to Game Center
            gameCenterService.reportAchievement(
                identifier: achievementId,
                percentComplete: 100.0
            ) { error in
                if let error = error {
                    print("Failed to report achievement to Game Center: \(error)")
                }
            }
            
            // Save to SwiftData
            do {
                try modelContext.save()
            } catch {
                setError(error)
            }
            
            // Play achievement sound
            audioService.playSound("achievement_unlock", volume: nil, pitch: 1.0, completion: nil)
            
            // Announce achievement unlock for VoiceOver users
            AccessibilityManager.shared.announceAchievementUnlock(achievement.title)
            
            // Track achievement unlock for rating system
            AppRatingManager.shared.trackSignificantEvent(.achievementUnlocked)
        }
    }
    
    // MARK: - Rating and Feedback Integration
    
    /// Track significant events that might warrant a rating prompt
    private func trackSignificantEventsForRating() {
        guard let player = playerData else { return }
        
        // Track game completion
        AppRatingManager.shared.trackSignificantEvent(.gameCompleted)
        
        // Check for high score achievement
        let currentHighScoreValue = player.highScore
        let currentHighScore = { (_: String) in currentHighScoreValue }(gameState.mode.rawValue)
        if gameState.score > currentHighScore {
            AppRatingManager.shared.trackSignificantEvent(.highScoreAchieved)
        }
        
        // Check for perfect landing (high score with good distance)
        if gameState.score > 1000 && gameState.distance > 500 {
            AppRatingManager.shared.trackSignificantEvent(.perfectLanding)
        }
        
        // Check for long flight
        if gameState.distance > 1000 {
            AppRatingManager.shared.trackSignificantEvent(.longFlightCompleted)
        }
        
        // Check for weekly special completion
        if gameState.mode == .weeklySpecial {
            AppRatingManager.shared.trackSignificantEvent(.weeklySpecialCompleted)
        }
        
        // Check for multiple games in session (based on recent game results)
        let recentGames = player.gameResults.filter { result in
            let timeSinceGame = Date().timeIntervalSince(result.completedAt)
            return timeSinceGame < 3600 // Within last hour
        }
        
        if recentGames.count >= 3 {
            AppRatingManager.shared.trackSignificantEvent(.multipleGamesInSession)
        }
    }
}