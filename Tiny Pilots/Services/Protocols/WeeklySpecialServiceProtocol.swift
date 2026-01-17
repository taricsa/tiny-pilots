import Foundation

/// Protocol defining weekly special service functionality
protocol WeeklySpecialServiceProtocol {
    /// Load current weekly specials from the server
    /// - Parameter forceRefresh: Whether to force a refresh from server
    /// - Returns: Array of current weekly specials
    /// - Throws: WeeklySpecialError if loading fails
    func loadWeeklySpecials(forceRefresh: Bool) async throws -> [WeeklySpecial]
    
    /// Get a specific weekly special by ID
    /// - Parameter id: The weekly special ID
    /// - Returns: The weekly special if found
    /// - Throws: WeeklySpecialError if not found or loading fails
    func getWeeklySpecial(id: String) async throws -> WeeklySpecial
    
    /// Submit a score for a weekly special
    /// - Parameters:
    ///   - score: The player's score
    ///   - weeklySpecialId: The weekly special ID
    ///   - gameData: Additional game data for validation
    /// - Throws: WeeklySpecialError if submission fails
    func submitScore(score: Int, weeklySpecialId: String, gameData: [String: Any]) async throws
    
    /// Load leaderboard for a weekly special
    /// - Parameter weeklySpecialId: The weekly special ID
    /// - Returns: Array of leaderboard entries
    /// - Throws: WeeklySpecialError if loading fails
    func loadLeaderboard(weeklySpecialId: String) async throws -> [WeeklySpecialLeaderboardEntry]
    
    /// Generate a share code for a weekly special
    /// - Parameter weeklySpecial: The weekly special to share
    /// - Returns: A shareable code
    func generateShareCode(for weeklySpecial: WeeklySpecial) -> String
    
    /// Load weekly special from a share code
    /// - Parameter shareCode: The share code
    /// - Returns: The weekly special
    /// - Throws: WeeklySpecialError if invalid or expired
    func loadFromShareCode(_ shareCode: String) async throws -> WeeklySpecial
    
    /// Check if player has participated in a weekly special
    /// - Parameter weeklySpecialId: The weekly special ID
    /// - Returns: True if player has participated
    func hasParticipated(in weeklySpecialId: String) -> Bool
    
    /// Get player's best score for a weekly special
    /// - Parameter weeklySpecialId: The weekly special ID
    /// - Returns: The player's best score, or nil if not participated
    func getPlayerBestScore(for weeklySpecialId: String) -> Int?
    
    /// Cache weekly specials locally for offline access
    /// - Parameter weeklySpecials: The weekly specials to cache
    func cacheWeeklySpecials(_ weeklySpecials: [WeeklySpecial])
    
    /// Load cached weekly specials
    /// - Returns: Array of cached weekly specials
    func loadCachedWeeklySpecials() -> [WeeklySpecial]
}