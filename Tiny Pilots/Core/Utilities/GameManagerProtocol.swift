//
//  GameManagerProtocol.swift
//  Tiny Pilots
//
//  Created by Kiro on Build Fixes Implementation
//

import Foundation
import Combine

/// Collision types for game interactions
enum CollisionType {
    case obstacle
    case collectible
    case powerUp
    case boundary
}

/// Game configuration for different levels and modes
struct GameConfiguration {
    let level: Int
    let difficulty: Float
    let environmentType: String
    let mode: GameState.Mode
    let targetScore: Int?
    let timeLimit: TimeInterval?
    let specialRules: [String: Any]
    
    init(
        level: Int = 1,
        difficulty: Float = 1.0,
        environmentType: String = "standard",
        mode: GameState.Mode = .freePlay,
        targetScore: Int? = nil,
        timeLimit: TimeInterval? = nil,
        specialRules: [String: Any] = [:]
    ) {
        self.level = level
        self.difficulty = difficulty
        self.environmentType = environmentType
        self.mode = mode
        self.targetScore = targetScore
        self.timeLimit = timeLimit
        self.specialRules = specialRules
    }
}

/// Protocol defining game management functionality
protocol GameManagerProtocol: ObservableObject {
    /// Current score
    var score: Int { get }
    
    /// Current level
    var level: Int { get }
    
    /// Current game state
    var gameState: GameState { get }
    
    /// Publisher for score changes
    var scorePublisher: AnyPublisher<Int, Never> { get }
    
    /// Publisher for level changes
    var levelPublisher: AnyPublisher<Int, Never> { get }
    
    /// Initialize a new game with the specified configuration
    /// - Parameters:
    ///   - mode: Game mode to initialize
    ///   - environmentType: Environment type for the game
    func initializeGame(mode: GameState.Mode, environmentType: String)
    
    /// Update the score with a new value
    /// - Parameter newScore: New score value
    func updateScore(_ newScore: Int)
    
    /// Add points to the current score
    /// - Parameter points: Points to add
    func addScore(_ points: Int)
    
    /// Progress to the next level
    func nextLevel()
    
    /// Handle collision events
    /// - Parameter collision: Type of collision that occurred
    func handleCollision(_ collision: CollisionType)
    
    /// Get the current game configuration
    /// - Returns: Current game configuration
    func getGameConfiguration() -> GameConfiguration
    
    /// Check if level progression is available
    /// - Returns: Whether the player can advance to the next level
    func canProgressToNextLevel() -> Bool
    
    /// Get the score required for the next level
    /// - Returns: Score threshold for next level
    func getNextLevelThreshold() -> Int
    
    /// Reset the game manager to initial state
    func reset()
}