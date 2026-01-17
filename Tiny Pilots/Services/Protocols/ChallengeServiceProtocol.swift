import Foundation

/// Protocol defining challenge service functionality
protocol ChallengeServiceProtocol {
    /// Load a challenge from a challenge code
    /// - Parameter code: The challenge code to load
    /// - Returns: The loaded challenge
    /// - Throws: ChallengeError if loading fails
    func loadChallenge(code: String) async throws -> Challenge
    
    /// Generate a challenge code for sharing
    /// - Parameter challenge: The challenge to generate a code for
    /// - Returns: A shareable challenge code
    func generateChallengeCode(for challenge: Challenge) -> String
    
    /// Validate a challenge code format and expiration
    /// - Parameter code: The challenge code to validate
    /// - Returns: True if the code is valid and not expired
    /// - Throws: ChallengeError if validation fails
    func validateChallengeCode(_ code: String) async throws -> Bool
    
    /// Create a new challenge from course data
    /// - Parameters:
    ///   - title: The challenge title
    ///   - description: The challenge description
    ///   - courseData: The course configuration
    ///   - createdBy: The creator's name
    ///   - targetScore: Optional target score
    /// - Returns: The created challenge
    func createChallenge(
        title: String,
        description: String,
        courseData: ChallengeData,
        createdBy: String,
        targetScore: Int?
    ) -> Challenge
    
    /// Save a challenge locally for offline access
    /// - Parameter challenge: The challenge to save
    /// - Throws: ChallengeError if saving fails
    func saveChallenge(_ challenge: Challenge) throws
    
    /// Load saved challenges from local storage
    /// - Returns: Array of saved challenges
    func loadSavedChallenges() -> [Challenge]
    
    /// Delete a saved challenge
    /// - Parameter challengeID: The ID of the challenge to delete
    /// - Throws: ChallengeError if deletion fails
    func deleteSavedChallenge(challengeID: String) throws
}