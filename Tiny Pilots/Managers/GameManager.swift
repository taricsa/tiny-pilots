//
//  GameManager.swift
//  Tiny Pilots
//
//  Created on 2025-03-01.
//

import Foundation
import SpriteKit
import GameplayKit

/// A singleton manager class that handles game state and coordinates between different components
class GameManager {
    
    // MARK: - Singleton
    
    /// Shared instance for singleton access
    static let shared = GameManager()
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Load saved player data if available
        loadPlayerData()
    }
    
    // MARK: - Game State
    
    /// Current game state
    enum GameState {
        case mainMenu
        case playing
        case paused
        case gameOver
    }
    
    /// Game mode for the current session
    enum GameMode {
        case freeFlight
        case challenge
        case dailyRun
    }
    
    /// The current state of the game
    var currentState: GameState = .mainMenu
    
    /// The current game mode
    var currentMode: GameMode = .freeFlight
    
    /// The player's current environment
    var currentEnvironment: Int = 0
    
    /// The active paper airplane
    var activeAirplane: PaperAirplane?
    
    // MARK: - Player Data
    
    /// Struct to hold player data for saving
    struct PlayerData: Codable {
        var level: Int = 1
        var experiencePoints: Int = 0
        var highScores: [String: Int] = [:]
        var unlockedEnvironments: [Int] = [0] // First environment is always unlocked
        var unlockedAirplaneDesigns: [String] = ["Plain"] // First design is always unlocked
        var unlockedFoldTypes: [String] = ["Basic"] // First fold type is always unlocked
        var completedChallenges: [String] = []
        var lastDailyRunDate: Date?
    }
    
    /// The player's persistent data
    var playerData = PlayerData()
    
    // MARK: - Session Data
    
    /// Data for the current game session
    struct SessionData {
        var score: Int = 0
        var distance: Float = 0.0
        var collectiblesGathered: Int = 0
        var timeElapsed: TimeInterval = 0.0
        var obstaclesAvoided: Int = 0
    }
    
    /// Data for the current game session
    var sessionData = SessionData()
    
    // MARK: - Game Management Methods
    
    /// Start a new game with the specified mode
    func startNewGame(mode: GameMode) {
        // Reset session data
        sessionData = SessionData()
        
        // Set game state
        currentMode = mode
        currentState = .playing
        
        // Create the active airplane if needed
        if activeAirplane == nil {
            activeAirplane = PaperAirplane()
        }
        
        // Notify observers that a new game is starting
        NotificationCenter.default.post(name: .gameDidStart, object: nil)
    }
    
    /// Pause the current game
    func pauseGame() {
        if currentState == .playing {
            currentState = .paused
            NotificationCenter.default.post(name: .gameDidPause, object: nil)
        }
    }
    
    /// Resume the current game
    func resumeGame() {
        if currentState == .paused {
            currentState = .playing
            NotificationCenter.default.post(name: .gameDidResume, object: nil)
        }
    }
    
    /// End the current game and process results
    func endGame() {
        // Calculate final score and rewards
        let earnedXP = calculateEarnedXP()
        addExperiencePoints(earnedXP)
        
        // Update high scores if needed
        updateHighScores()
        
        // Change game state
        currentState = .gameOver
        
        // Save player data
        savePlayerData()
        
        // Notify observers that the game has ended
        NotificationCenter.default.post(name: .gameDidEnd, object: nil, userInfo: [
            "score": sessionData.score,
            "earnedXP": earnedXP
        ])
    }
    
    // MARK: - Player Progression Methods
    
    /// Add experience points to the player's total
    func addExperiencePoints(_ points: Int) {
        playerData.experiencePoints += points
        
        // Check for level up
        let nextLevelThreshold = GameConfig.Progression.xpRequiredForLevel(playerData.level + 1)
        if playerData.experiencePoints >= nextLevelThreshold {
            levelUp()
        }
        
        // Save changes
        savePlayerData()
    }
    
    /// Level up the player and unlock rewards
    private func levelUp() {
        playerData.level += 1
        
        // Unlock new content based on level
        unlockContentForLevel(playerData.level)
        
        // Notify observers that player leveled up
        NotificationCenter.default.post(name: .playerDidLevelUp, object: nil, userInfo: [
            "level": playerData.level
        ])
    }
    
    /// Unlock content for the current level
    private func unlockContentForLevel(_ level: Int) {
        // Unlock environments
        for (index, unlockLevel) in GameConfig.Environments.environmentUnlockLevels.enumerated() {
            if level >= unlockLevel && !playerData.unlockedEnvironments.contains(index) {
                playerData.unlockedEnvironments.append(index)
                
                // Notify about unlocked environment
                NotificationCenter.default.post(name: .contentDidUnlock, object: nil, userInfo: [
                    "type": "environment",
                    "id": index
                ])
            }
        }
        
        // Unlock airplane designs
        for design in PaperAirplane.DesignType.allCases {
            if level >= design.unlockLevel && !playerData.unlockedAirplaneDesigns.contains(design.rawValue) {
                playerData.unlockedAirplaneDesigns.append(design.rawValue)
                
                // Notify about unlocked design
                NotificationCenter.default.post(name: .contentDidUnlock, object: nil, userInfo: [
                    "type": "airplaneDesign",
                    "id": design.rawValue
                ])
            }
        }
        
        // Unlock fold types
        for fold in PaperAirplane.FoldType.allCases {
            if level >= fold.unlockLevel && !playerData.unlockedFoldTypes.contains(fold.rawValue) {
                playerData.unlockedFoldTypes.append(fold.rawValue)
                
                // Notify about unlocked fold type
                NotificationCenter.default.post(name: .contentDidUnlock, object: nil, userInfo: [
                    "type": "foldType",
                    "id": fold.rawValue
                ])
            }
        }
    }
    
    // MARK: - Score and XP Calculation
    
    /// Calculate the experience points earned in the current session
    private func calculateEarnedXP() -> Int {
        let baseXP = Int(sessionData.timeElapsed) * Int(GameConfig.Progression.baseXpPerSecond)
        let distanceXP = Int(sessionData.distance * Float(GameConfig.Progression.baseXpPerMeter))
        let collectiblesXP = sessionData.collectiblesGathered * Int(GameConfig.Progression.bonusXpPerCollectible)
        
        return baseXP + distanceXP + collectiblesXP
    }
    
    /// Update high scores based on the current session
    private func updateHighScores() {
        // Create a key for the current environment and mode
        let key = "\(currentEnvironment)_\(currentMode)"
        
        // Check if we have a new high score
        if sessionData.score > (playerData.highScores[key] ?? 0) {
            playerData.highScores[key] = sessionData.score
            
            // Notify about new high score
            NotificationCenter.default.post(name: .newHighScoreAchieved, object: nil, userInfo: [
                "environment": currentEnvironment,
                "mode": currentMode,
                "score": sessionData.score
            ])
        }
    }
    
    // MARK: - Persistence
    
    /// Save player data to disk
    func savePlayerData() {
        do {
            let data = try JSONEncoder().encode(playerData)
            try data.write(to: getPlayerDataURL())
        } catch {
            print("Error saving player data: \(error.localizedDescription)")
        }
    }
    
    /// Load player data from disk
    private func loadPlayerData() {
        do {
            let data = try Data(contentsOf: getPlayerDataURL())
            playerData = try JSONDecoder().decode(PlayerData.self, from: data)
        } catch {
            print("Could not load player data: \(error.localizedDescription)")
            // Use default player data if no save exists
            playerData = PlayerData()
        }
    }
    
    /// Get the URL for player data
    private func getPlayerDataURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("playerData.json")
    }
    
    // MARK: - Daily Run
    
    /// Check if the player can participate in today's daily run
    func canParticipateDailyRun() -> Bool {
        guard let lastDailyRun = playerData.lastDailyRunDate else {
            // No previous daily runs
            return true
        }
        
        // Check if we've already done a daily run today
        let calendar = Calendar.current
        return !calendar.isDateInToday(lastDailyRun)
    }
    
    /// Record that player participated in today's daily run
    func recordDailyRunParticipation() {
        playerData.lastDailyRunDate = Date()
        savePlayerData()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let gameDidStart = Notification.Name("gameDidStart")
    static let gameDidPause = Notification.Name("gameDidPause")
    static let gameDidResume = Notification.Name("gameDidResume")
    static let gameDidEnd = Notification.Name("gameDidEnd")
    static let playerDidLevelUp = Notification.Name("playerDidLevelUp")
    static let contentDidUnlock = Notification.Name("contentDidUnlock")
    static let newHighScoreAchieved = Notification.Name("newHighScoreAchieved")
} 