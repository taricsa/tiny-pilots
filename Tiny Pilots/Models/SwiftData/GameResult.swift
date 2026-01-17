import Foundation
import SwiftData

/// SwiftData model representing a completed game session result
@Model
class GameResult {
    @Attribute(.unique) var id: UUID
    var mode: String
    var score: Int
    var distance: Float
    var timeElapsed: TimeInterval
    var coinsCollected: Int
    var environmentType: String
    var airplaneType: String
    var foldType: String
    var designType: String
    var completedAt: Date
    
    // Relationship
    var player: PlayerData?
    
    init(
        mode: String,
        score: Int,
        distance: Float,
        timeElapsed: TimeInterval,
        coinsCollected: Int,
        environmentType: String,
        airplaneType: String = "basic",
        foldType: String = "basic",
        designType: String = "plain"
    ) {
        self.id = UUID()
        self.mode = mode
        self.score = score
        self.distance = distance
        self.timeElapsed = timeElapsed
        self.coinsCollected = coinsCollected
        self.environmentType = environmentType
        self.airplaneType = airplaneType
        self.foldType = foldType
        self.designType = designType
        self.completedAt = Date()
    }
    
    /// Calculate experience points earned from this game result
    var experienceEarned: Int {
        let baseXP = score / 100 // 1 XP per 100 points
        let distanceXP = Int(distance / 50) // 1 XP per 50 units of distance
        let timeXP = Int(timeElapsed / 60) // 1 XP per minute
        let coinXP = coinsCollected * 2 // 2 XP per coin
        
        return max(1, baseXP + distanceXP + timeXP + coinXP) // Minimum 1 XP
    }
    
    /// Check if this is a personal best for the player
    func isPersonalBest(for player: PlayerData) -> Bool {
        let playerResults = player.gameResults.filter { $0.mode == self.mode }
        return playerResults.allSatisfy { $0.score < self.score }
    }
    
    /// Get rank among all results for this mode
    func getRank(among results: [GameResult]) -> Int {
        let sameMode = results.filter { $0.mode == self.mode }
        let betterScores = sameMode.filter { $0.score > self.score }
        return betterScores.count + 1
    }
}

// MARK: - Codable Support for Backup/Restore

/// Codable representation of GameResult for backup purposes
struct GameResultCodable: Codable {
    let id: UUID
    let mode: String
    let score: Int
    let distance: Float
    let timeElapsed: TimeInterval
    let coinsCollected: Int
    let environmentType: String
    let airplaneType: String
    let foldType: String
    let designType: String
    let completedAt: Date
    
    init(from gameResult: GameResult) {
        self.id = gameResult.id
        self.mode = gameResult.mode
        self.score = gameResult.score
        self.distance = gameResult.distance
        self.timeElapsed = gameResult.timeElapsed
        self.coinsCollected = gameResult.coinsCollected
        self.environmentType = gameResult.environmentType
        self.airplaneType = gameResult.airplaneType
        self.foldType = gameResult.foldType
        self.designType = gameResult.designType
        self.completedAt = gameResult.completedAt
    }
    
    // Convert codable backup to SwiftData model
    @MainActor
    func toModel(in context: ModelContext, player: PlayerData) -> GameResult {
        let result = GameResult(
            mode: mode,
            score: score,
            distance: distance,
            timeElapsed: timeElapsed,
            coinsCollected: coinsCollected,
            environmentType: environmentType,
            airplaneType: airplaneType,
            foldType: foldType,
            designType: designType
        )
        result.player = player
        result.completedAt = completedAt
        return result
    }
}