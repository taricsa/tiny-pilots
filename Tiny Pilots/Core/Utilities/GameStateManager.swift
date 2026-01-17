//
//  GameStateManager.swift
//  Tiny Pilots
//
//  Created by Kiro on Build Fixes Implementation
//

import Foundation
import Combine

/// Concrete implementation of GameStateManagerProtocol
class GameStateManager: GameStateManagerProtocol {
    static let shared = GameStateManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var currentState: GameState = .initial
    
    // MARK: - Computed Properties
    
    var isGameActive: Bool {
        return currentState.isActive
    }
    
    var gameStatePublisher: AnyPublisher<GameState, Never> {
        return $currentState.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    
    private let logger = Logger.shared
    private let userDefaults = UserDefaults.standard
    private let gameStateKey = "TinyPilots.GameState"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    
    private init() {
        setupEncoder()
        loadGameState()
        logger.info("GameStateManager initialized", category: .game)
    }
    
    private func setupEncoder() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Public Methods
    
    func startGame(mode: GameState.Mode = .freePlay, environmentType: String = "standard") {
        logger.info("Starting game - Mode: \(mode.displayName), Environment: \(environmentType)", category: .game)
        
        let newState = GameState(
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
        
        updateGameState(newState)
        saveGameStateAsync() // Use async version to avoid blocking
    }
    
    func pauseGame() {
        guard currentState.canPause else {
            logger.warning("Cannot pause game in current state: \(currentState.status.displayName)", category: .game)
            return
        }
        
        logger.info("Pausing game", category: .game)
        let pausedState = currentState.pause()
        updateGameState(pausedState)
        saveGameStateAsync() // Use async version to avoid blocking
    }
    
    func resumeGame() {
        guard currentState.canResume else {
            logger.warning("Cannot resume game in current state: \(currentState.status.displayName)", category: .game)
            return
        }
        
        logger.info("Resuming game", category: .game)
        let resumedState = currentState.resume()
        updateGameState(resumedState)
        saveGameStateAsync() // Use async version to avoid blocking
    }
    
    func endGame() {
        guard currentState.isActive else {
            logger.warning("Cannot end game in current state: \(currentState.status.displayName)", category: .game)
            return
        }
        
        logger.info("Ending game - Final Score: \(currentState.score), Distance: \(currentState.distance)m", category: .game)
        let endedState = currentState.end()
        updateGameState(endedState)
        saveGameStateAsync() // Use async version to avoid blocking
    }
    
    func resetGame() {
        logger.info("Resetting game to initial state", category: .game)
        updateGameState(.initial)
        clearSavedState()
    }
    
    func updateGameState(_ newState: GameState) {
        guard newState.isValid else {
            logger.error("Attempted to update with invalid game state: \(newState)", category: .game)
            return
        }
        
        let oldState = currentState
        currentState = newState
        
        logger.debug("Game state updated - Status: \(newState.status.displayName), Score: \(newState.score)", category: .game)
        
        // Log significant state transitions
        if oldState.status != newState.status {
            logger.info("Game status changed: \(oldState.status.displayName) → \(newState.status.displayName)", category: .game)
        }
    }
    
    func saveGameState() {
        // Synchronous version for backward compatibility
        // Prefer saveGameStateAsync for better performance
        saveGameStateAsync(completion: nil)
    }
    
    func saveGameStateAsync(completion: ((Bool) -> Void)? = nil) {
        // Perform encoding and I/O on background queue
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else {
                completion?(false)
                return
            }
            
            do {
                let data = try self.encoder.encode(self.currentState)
                
                // UserDefaults.set is thread-safe, but we'll do it on main for consistency
                DispatchQueue.main.async {
                    self.userDefaults.set(data, forKey: self.gameStateKey)
                    self.logger.debug("Game state saved successfully", category: .game)
                    completion?(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.logger.error("Failed to save game state", error: error, category: .game)
                    completion?(false)
                }
            }
        }
    }
    
    func loadGameState() {
        guard let data = userDefaults.data(forKey: gameStateKey) else {
            logger.debug("No saved game state found, using initial state", category: .game)
            return
        }
        
        do {
            let savedState = try decoder.decode(GameState.self, from: data)
            
            // Validate the loaded state
            if savedState.isValid {
                currentState = savedState
                logger.info("Game state loaded successfully - Status: \(savedState.status.displayName)", category: .game)
            } else {
                logger.warning("Loaded game state is invalid, using initial state", category: .game)
                clearSavedState()
            }
        } catch {
            logger.error("Failed to load game state, using initial state", error: error, category: .game)
            clearSavedState()
        }
    }
    
    func clearSavedState() {
        userDefaults.removeObject(forKey: gameStateKey)
        logger.debug("Saved game state cleared", category: .game)
    }
}

// MARK: - Game Progress Helpers

extension GameStateManager {
    /// Update the score in the current game
    /// - Parameter newScore: New score value
    func updateScore(_ newScore: Int) {
        let updatedState = currentState.withScore(newScore)
        updateGameState(updatedState)
    }
    
    /// Add points to the current score
    /// - Parameter points: Points to add
    func addScore(_ points: Int) {
        let updatedState = currentState.addingScore(points)
        updateGameState(updatedState)
    }
    
    /// Update the distance traveled
    /// - Parameter newDistance: New distance value
    func updateDistance(_ newDistance: Float) {
        let updatedState = currentState.withDistance(newDistance)
        updateGameState(updatedState)
    }
    
    /// Add distance to the current total
    /// - Parameter additionalDistance: Distance to add
    func addDistance(_ additionalDistance: Float) {
        let updatedState = currentState.addingDistance(additionalDistance)
        updateGameState(updatedState)
    }
    
    /// Update the time elapsed
    /// - Parameter newTime: New time elapsed value
    func updateTimeElapsed(_ newTime: TimeInterval) {
        let updatedState = currentState.withTimeElapsed(newTime)
        updateGameState(updatedState)
    }
    
    /// Update coins collected
    /// - Parameter newCoins: New coins collected value
    func updateCoinsCollected(_ newCoins: Int) {
        let updatedState = currentState.withCoinsCollected(newCoins)
        updateGameState(updatedState)
    }
    
    /// Add a collected coin
    func addCoin() {
        let updatedState = currentState.addingCoin()
        updateGameState(updatedState)
    }
    
    /// Change the environment type
    /// - Parameter environmentType: New environment type
    func changeEnvironment(_ environmentType: String) {
        let updatedState = currentState.withEnvironmentType(environmentType)
        updateGameState(updatedState)
    }
}

// MARK: - State Validation Helpers

extension GameStateManager {
    /// Check if a specific game mode can be started
    /// - Parameter mode: Game mode to check
    /// - Returns: Whether the mode can be started
    func canStartMode(_ mode: GameState.Mode) -> Bool {
        return currentState.canStart
    }
    
    /// Get the current game session duration
    /// - Returns: Duration in seconds, or nil if game hasn't started
    func getCurrentSessionDuration() -> TimeInterval? {
        guard let startTime = currentState.startTime else { return nil }
        
        if let endTime = currentState.endTime {
            return endTime.timeIntervalSince(startTime)
        } else if currentState.isActive {
            return Date().timeIntervalSince(startTime)
        }
        
        return nil
    }
    
    /// Check if the current game is a new high score
    /// - Returns: Whether this is a new high score
    func isNewHighScore() -> Bool {
        // This would typically check against saved high scores
        // For now, we'll return false as a placeholder
        return false
    }
}