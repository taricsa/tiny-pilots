//
//  GameStateManagerProtocol.swift
//  Tiny Pilots
//
//  Created by Kiro on Build Fixes Implementation
//

import Foundation
import Combine

/// Protocol defining game state management functionality
protocol GameStateManagerProtocol: ObservableObject {
    /// Current game state
    var currentState: GameState { get }
    
    /// Whether the game is currently active (playing or paused)
    var isGameActive: Bool { get }
    
    /// Publisher for game state changes
    var gameStatePublisher: AnyPublisher<GameState, Never> { get }
    
    /// Start a new game with the specified mode and environment
    /// - Parameters:
    ///   - mode: Game mode to start
    ///   - environmentType: Environment type for the game
    func startGame(mode: GameState.Mode, environmentType: String)
    
    /// Pause the current game
    func pauseGame()
    
    /// Resume the paused game
    func resumeGame()
    
    /// End the current game
    func endGame()
    
    /// Reset to initial state
    func resetGame()
    
    /// Update the current game state
    /// - Parameter newState: New game state
    func updateGameState(_ newState: GameState)
    
    /// Save the current game state to persistent storage
    func saveGameState()
    func saveGameStateAsync(completion: ((Bool) -> Void)?)
    
    /// Load the game state from persistent storage
    func loadGameState()
    
    /// Clear all saved game state data
    func clearSavedState()
}