import Foundation
import GameKit

/// Protocol defining Game Center service functionality
protocol GameCenterServiceProtocol {
    /// Whether Game Center is available and authenticated
    var isAuthenticated: Bool { get }
    
    /// The local player's display name
    var playerDisplayName: String? { get }
    
    /// Authenticate the local player with Game Center
    /// - Parameter completion: Completion handler with success status and optional error
    func authenticate(completion: @escaping (Bool, Error?) -> Void)
    
    /// Submit a score to a specific leaderboard
    /// - Parameters:
    ///   - score: The score to submit
    ///   - leaderboardID: The identifier of the leaderboard
    ///   - completion: Completion handler with optional error
    func submitScore(_ score: Int, to leaderboardID: String, completion: @escaping (Error?) -> Void)
    
    /// Load leaderboard entries for a specific leaderboard
    /// - Parameters:
    ///   - leaderboardID: The identifier of the leaderboard
    ///   - completion: Completion handler with leaderboard entries and optional error
    func loadLeaderboard(for leaderboardID: String, completion: @escaping ([GameCenterLeaderboardEntry]?, Error?) -> Void)
    
    /// Report progress for an achievement
    /// - Parameters:
    ///   - identifier: The achievement identifier
    ///   - percentComplete: Progress percentage (0.0 to 100.0)
    ///   - completion: Completion handler with optional error
    func reportAchievement(identifier: String, percentComplete: Double, completion: @escaping (Error?) -> Void)
    
    /// Load all achievements for the local player
    /// - Parameter completion: Completion handler with achievements and optional error
    func loadAchievements(completion: @escaping ([GKAchievement]?, Error?) -> Void)
    
    /// Show the Game Center leaderboards UI
    /// - Parameter presentingViewController: The view controller to present from
    func showLeaderboards(from presentingViewController: UIViewController)
    
    /// Show the Game Center achievements UI
    /// - Parameter presentingViewController: The view controller to present from
    func showAchievements(from presentingViewController: UIViewController)
    
    /// Generate a challenge code for friend challenges
    /// - Parameter courseData: Data representing the challenge course
    /// - Returns: A challenge code string
    func generateChallengeCode(for courseData: String) -> String
    
    /// Validate and process a challenge code
    /// - Parameters:
    ///   - code: The challenge code to validate
    ///   - completion: Completion handler with course data or error
    func validateChallengeCode(_ code: String, completion: @escaping (Result<String, Error>) -> Void)
}

/// Represents a leaderboard entry from Game Center
struct GameCenterLeaderboardEntry {
    let playerID: String
    let displayName: String
    let score: Int
    let rank: Int
    let date: Date
}

/// Game Center service errors
enum GameCenterServiceError: Error, LocalizedError {
    case notAuthenticated
    case leaderboardNotFound
    case achievementNotFound
    case submissionFailed
    case invalidChallengeCode
    case challengeExpired
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in to Game Center. Please sign in through Settings."
        case .leaderboardNotFound:
            return "Leaderboard not found. Please check your Game Center configuration."
        case .achievementNotFound:
            return "Achievement not found. Please check your Game Center configuration."
        case .submissionFailed:
            return "Failed to submit score or achievement. Please try again later."
        case .invalidChallengeCode:
            return "Invalid challenge code. Please check and try again."
        case .challengeExpired:
            return "This challenge has expired. Please request a new code."
        case .networkError:
            return "Network error. Please check your connection and try again."
        }
    }
}