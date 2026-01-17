//
//  GameState.swift
//  Tiny Pilots
//
//  Created on 2025-01-15.
//

import Foundation

/// Immutable value object representing the current state of a game session
struct GameState: Equatable, Codable {
    
    // MARK: - Types
    
    /// Game status enumeration
    enum Status: String, Codable, CaseIterable {
        case notStarted = "not_started"
        case playing = "playing"
        case paused = "paused"
        case ended = "ended"
        
        var displayName: String {
            switch self {
            case .notStarted: return "Not Started"
            case .playing: return "Playing"
            case .paused: return "Paused"
            case .ended: return "Ended"
            }
        }
    }
    
    /// Game mode enumeration
    enum Mode: String, Codable, CaseIterable {
        case tutorial = "tutorial"
        case freePlay = "free_play"
        case challenge = "challenge"
        case dailyRun = "daily_run"
        case weeklySpecial = "weekly_special"
        
        var displayName: String {
            switch self {
            case .tutorial: return "Tutorial"
            case .freePlay: return "Free Play"
            case .challenge: return "Challenge"
            case .dailyRun: return "Daily Run"
            case .weeklySpecial: return "Weekly Special"
            }
        }
    }
    
    // MARK: - Properties
    
    /// Current game mode
    let mode: Mode
    
    /// Current game status
    let status: Status
    
    /// Current score
    let score: Int
    
    /// Distance traveled in meters
    let distance: Float
    
    /// Time elapsed in seconds
    let timeElapsed: TimeInterval
    
    /// Number of coins collected
    let coinsCollected: Int
    
    /// Environment type for this game session
    let environmentType: String
    
    /// Game session start time
    let startTime: Date?
    
    /// Game session end time
    let endTime: Date?
    
    // MARK: - Computed Properties
    
    /// Whether the game is currently active (playing or paused)
    var isActive: Bool {
        return status == .playing || status == .paused
    }
    
    /// Whether the game has been completed
    var isCompleted: Bool {
        return status == .ended
    }
    
    /// Whether the game can be paused
    var canPause: Bool {
        return status == .playing
    }
    
    /// Whether the game can be resumed
    var canResume: Bool {
        return status == .paused
    }
    
    /// Whether the game can be started
    var canStart: Bool {
        return status == .notStarted
    }
    
    // MARK: - Static Instances
    
    /// Initial game state
    static let initial = GameState(
        mode: .freePlay,
        status: .notStarted,
        score: 0,
        distance: 0,
        timeElapsed: 0,
        coinsCollected: 0,
        environmentType: "standard",
        startTime: nil,
        endTime: nil
    )
    
    // MARK: - Initialization
    
    /// Initialize a new game state
    /// - Parameters:
    ///   - mode: Game mode
    ///   - status: Current status
    ///   - score: Current score
    ///   - distance: Distance traveled
    ///   - timeElapsed: Time elapsed in seconds
    ///   - coinsCollected: Number of coins collected
    ///   - environmentType: Environment type identifier
    ///   - startTime: Game start time
    ///   - endTime: Game end time
    init(
        mode: Mode,
        status: Status,
        score: Int,
        distance: Float,
        timeElapsed: TimeInterval,
        coinsCollected: Int,
        environmentType: String,
        startTime: Date? = nil,
        endTime: Date? = nil
    ) {
        self.mode = mode
        self.status = status
        self.score = max(0, score) // Ensure score is never negative
        self.distance = max(0, distance) // Ensure distance is never negative
        self.timeElapsed = max(0, timeElapsed) // Ensure time is never negative
        self.coinsCollected = max(0, coinsCollected) // Ensure coins is never negative
        self.environmentType = environmentType
        self.startTime = startTime
        self.endTime = endTime
    }
    
    // MARK: - State Transitions
    
    /// Start the game
    /// - Returns: New game state with playing status
    func start() -> GameState {
        guard canStart else { return self }
        
        return GameState(
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
    }
    
    /// Pause the game
    /// - Returns: New game state with paused status
    func pause() -> GameState {
        guard canPause else { return self }
        
        return GameState(
            mode: mode,
            status: .paused,
            score: score,
            distance: distance,
            timeElapsed: timeElapsed,
            coinsCollected: coinsCollected,
            environmentType: environmentType,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    /// Resume the game
    /// - Returns: New game state with playing status
    func resume() -> GameState {
        guard canResume else { return self }
        
        return GameState(
            mode: mode,
            status: .playing,
            score: score,
            distance: distance,
            timeElapsed: timeElapsed,
            coinsCollected: coinsCollected,
            environmentType: environmentType,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    /// End the game
    /// - Returns: New game state with ended status
    func end() -> GameState {
        guard isActive else { return self }
        
        return GameState(
            mode: mode,
            status: .ended,
            score: score,
            distance: distance,
            timeElapsed: timeElapsed,
            coinsCollected: coinsCollected,
            environmentType: environmentType,
            startTime: startTime,
            endTime: Date()
        )
    }
    
    // MARK: - Game Progress Updates
    
    /// Update the score
    /// - Parameter newScore: New score value
    /// - Returns: New game state with updated score
    func withScore(_ newScore: Int) -> GameState {
        guard status == .playing else { return self }
        
        return GameState(
            mode: mode,
            status: status,
            score: max(0, newScore),
            distance: distance,
            timeElapsed: timeElapsed,
            coinsCollected: coinsCollected,
            environmentType: environmentType,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    /// Add points to the score
    /// - Parameter points: Points to add
    /// - Returns: New game state with updated score
    func addingScore(_ points: Int) -> GameState {
        return withScore(score + points)
    }
    
    /// Update the distance
    /// - Parameter newDistance: New distance value
    /// - Returns: New game state with updated distance
    func withDistance(_ newDistance: Float) -> GameState {
        guard status == .playing else { return self }
        
        return GameState(
            mode: mode,
            status: status,
            score: score,
            distance: max(0, newDistance),
            timeElapsed: timeElapsed,
            coinsCollected: coinsCollected,
            environmentType: environmentType,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    /// Add distance traveled
    /// - Parameter additionalDistance: Distance to add
    /// - Returns: New game state with updated distance
    func addingDistance(_ additionalDistance: Float) -> GameState {
        return withDistance(distance + additionalDistance)
    }
    
    /// Update the time elapsed
    /// - Parameter newTime: New time elapsed value
    /// - Returns: New game state with updated time
    func withTimeElapsed(_ newTime: TimeInterval) -> GameState {
        guard status == .playing else { return self }
        
        return GameState(
            mode: mode,
            status: status,
            score: score,
            distance: distance,
            timeElapsed: max(0, newTime),
            coinsCollected: coinsCollected,
            environmentType: environmentType,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    /// Update coins collected
    /// - Parameter newCoins: New coins collected value
    /// - Returns: New game state with updated coins
    func withCoinsCollected(_ newCoins: Int) -> GameState {
        guard status == .playing else { return self }
        
        return GameState(
            mode: mode,
            status: status,
            score: score,
            distance: distance,
            timeElapsed: timeElapsed,
            coinsCollected: max(0, newCoins),
            environmentType: environmentType,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    /// Add a collected coin
    /// - Returns: New game state with incremented coins
    func addingCoin() -> GameState {
        return withCoinsCollected(coinsCollected + 1)
    }
    
    /// Change environment type
    /// - Parameter newEnvironmentType: New environment type
    /// - Returns: New game state with updated environment
    func withEnvironmentType(_ newEnvironmentType: String) -> GameState {
        return GameState(
            mode: mode,
            status: status,
            score: score,
            distance: distance,
            timeElapsed: timeElapsed,
            coinsCollected: coinsCollected,
            environmentType: newEnvironmentType,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    // MARK: - Business Rules Validation
    
    /// Validate state transition
    /// - Parameter newStatus: Target status
    /// - Returns: Whether the transition is valid
    func canTransition(to newStatus: Status) -> Bool {
        switch (status, newStatus) {
        case (.notStarted, .playing):
            return true
        case (.playing, .paused):
            return true
        case (.paused, .playing):
            return true
        case (.playing, .ended):
            return true
        case (.paused, .ended):
            return true
        case (.ended, .notStarted):
            return true // Allow restarting
        default:
            return false
        }
    }
    
    /// Check if the game state is valid
    var isValid: Bool {
        // Basic validation rules
        guard score >= 0,
              distance >= 0,
              timeElapsed >= 0,
              coinsCollected >= 0 else {
            return false
        }
        
        // Status-specific validation
        switch status {
        case .notStarted:
            return score == 0 && distance == 0 && timeElapsed == 0 && coinsCollected == 0
        case .playing, .paused:
            return startTime != nil && endTime == nil
        case .ended:
            return startTime != nil
        }
    }
}

// MARK: - CustomStringConvertible

extension GameState: CustomStringConvertible {
    var description: String {
        return """
        GameState(
            mode: \(mode.displayName),
            status: \(status.displayName),
            score: \(score),
            distance: \(String(format: "%.1f", distance))m,
            time: \(String(format: "%.1f", timeElapsed))s,
            coins: \(coinsCollected),
            environment: \(environmentType)
        )
        """
    }
}