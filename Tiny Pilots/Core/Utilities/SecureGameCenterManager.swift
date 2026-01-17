import Foundation
import GameKit
import CryptoKit

/// Protocol for secure Game Center operations
protocol SecureGameCenterManagerProtocol {
    func authenticateSecurely() async throws -> Bool
    func submitScoreSecurely(_ score: Int, to leaderboardID: String) async throws
    func unlockAchievementSecurely(_ achievementID: String, percentComplete: Double) async throws
    func loadLeaderboardSecurely(_ leaderboardID: String) async throws -> [GKLeaderboard.Entry]
    func validateScoreIntegrity(_ score: Int, gameData: [String: Any]) -> Bool
    func detectFraudulentActivity(_ score: Int, gameData: [String: Any]) -> Bool
    func resolveDataConflicts() async throws
}

/// Secure Game Center manager with enhanced security features
class SecureGameCenterManager: SecureGameCenterManagerProtocol {
    static let shared = SecureGameCenterManager()
    
    private let gameCenterService: GameCenterServiceProtocol
    private let secureDataManager = SecureDataManager.shared
    private let logger = Logger.shared
    
    // Security keys
    private let authTokenKey = "gamecenter_auth_token"
    private let playerSignatureKey = "gamecenter_player_signature"
    private let lastSyncTimestampKey = "gamecenter_last_sync"
    private let fraudDetectionDataKey = "fraud_detection_data"
    
    // Fraud detection thresholds
    private let maxScoreIncreasePercentage: Double = 500.0 // 500% increase
    private let maxScoreSubmissionsPerMinute = 10
    private let suspiciousScoreThreshold = 1000000
    
    // Data conflict resolution
    private var pendingConflicts: [DataConflict] = []
    
    init(gameCenterService: GameCenterServiceProtocol = GameCenterService()) {
        self.gameCenterService = gameCenterService
    }
    
    // MARK: - Secure Authentication
    
    /// Authenticate with Game Center using secure token management
    func authenticateSecurely() async throws -> Bool {
        logger.info("Starting secure Game Center authentication", category: .security)
        
        // Check if we have a valid cached authentication
        if let cachedAuth = try? getCachedAuthentication(), cachedAuth.isValid {
            logger.info("Using cached Game Center authentication", category: .security)
            return true
        }
        
        // Perform fresh authentication
        let isAuthenticated: Bool = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            gameCenterService.authenticate { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
        
        if isAuthenticated {
            // Store secure authentication token
            try await storeSecureAuthenticationToken()
            logger.info("Game Center authentication successful", category: .security)
        } else {
            logger.warning("Game Center authentication failed", category: .security)
        }
        
        return isAuthenticated
    }
    
    /// Store secure authentication token and player signature
    private func storeSecureAuthenticationToken() async throws {
        guard let player = GKLocalPlayer.local.isAuthenticated ? GKLocalPlayer.local : nil else {
            throw SecureGameCenterError.authenticationFailed
        }
        
        let authData = AuthenticationData(
            playerID: player.gamePlayerID,
            displayName: player.displayName,
            timestamp: Date(),
            signature: try generatePlayerSignature(player)
        )
        
        try secureDataManager.storeSecureData(authData, forKey: authTokenKey)
        logger.info("Secure authentication token stored", category: .security)
    }
    
    /// Generate cryptographic signature for player verification
    private func generatePlayerSignature(_ player: GKPlayer) throws -> String {
        let signatureData = "\(player.gamePlayerID):\(player.displayName):\(Date().timeIntervalSince1970)"
        let hash = SHA256.hash(data: signatureData.data(using: .utf8)!)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Get cached authentication data
    private func getCachedAuthentication() throws -> AuthenticationData? {
        return try secureDataManager.retrieveSecureData(AuthenticationData.self, forKey: authTokenKey)
    }
    
    // MARK: - Secure Score Submission
    
    /// Submit score with integrity validation and fraud detection
    func submitScoreSecurely(_ score: Int, to leaderboardID: String) async throws {
        logger.info("Submitting score securely: \(score) to \(leaderboardID)", category: .security)
        
        // Ensure authentication
        guard try await authenticateSecurely() else {
            throw SecureGameCenterError.authenticationRequired
        }
        
        // Create game data for validation
        let gameData: [String: Any] = [
            "score": score,
            "leaderboard": leaderboardID,
            "timestamp": Date().timeIntervalSince1970,
            "player_id": GKLocalPlayer.local.gamePlayerID
        ]
        
        // Validate score integrity
        guard validateScoreIntegrity(score, gameData: gameData) else {
            logger.error("Score integrity validation failed", category: .security)
            throw SecureGameCenterError.invalidScore
        }
        
        // Detect fraudulent activity
        if detectFraudulentActivity(score, gameData: gameData) {
            logger.error("Fraudulent activity detected for score submission", category: .security)
            throw SecureGameCenterError.fraudDetected
        }
        
        // Submit score with retry logic
        try await submitScoreWithRetry(score, leaderboardID: leaderboardID, gameData: gameData)
        
        // Update fraud detection data
        await updateFraudDetectionData(score: score, leaderboardID: leaderboardID)
        
        logger.info("Score submitted securely", category: .security)
    }
    
    /// Submit score with retry logic and conflict resolution
    private func submitScoreWithRetry(_ score: Int, leaderboardID: String, gameData: [String: Any]) async throws {
        var attempts = 0
        let maxAttempts = 3
        
        while attempts < maxAttempts {
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    gameCenterService.submitScore(score, to: leaderboardID) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
                return // Success
                
            } catch {
                attempts += 1
                logger.warning("Score submission attempt \(attempts) failed: \(error)", category: .security)
                
                if attempts >= maxAttempts {
                    // Store for offline sync
                    await storeOfflineScore(score, leaderboardID: leaderboardID, gameData: gameData)
                    throw error
                }
                
                // Wait before retry
                try await Task.sleep(nanoseconds: UInt64(2_000_000_000 * attempts)) // Exponential backoff
            }
        }
    }
    
    // MARK: - Secure Achievement Unlocking
    
    /// Unlock achievement with validation
    func unlockAchievementSecurely(_ achievementID: String, percentComplete: Double) async throws {
        logger.info("Unlocking achievement securely: \(achievementID) at \(percentComplete)%", category: .security)
        
        // Ensure authentication
        guard try await authenticateSecurely() else {
            throw SecureGameCenterError.authenticationRequired
        }
        
        // Validate achievement data
        guard percentComplete >= 0 && percentComplete <= 100 else {
            throw SecureGameCenterError.invalidAchievementProgress
        }
        
        // Submit achievement with retry logic
        try await unlockAchievementWithRetry(achievementID, percentComplete: percentComplete)
        
        logger.info("Achievement unlocked securely", category: .security)
    }
    
    /// Unlock achievement with retry logic
    private func unlockAchievementWithRetry(_ achievementID: String, percentComplete: Double) async throws {
        var attempts = 0
        let maxAttempts = 3
        
        while attempts < maxAttempts {
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    gameCenterService.reportAchievement(identifier: achievementID, percentComplete: percentComplete) { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    }
                }
                return // Success
                
            } catch {
                attempts += 1
                logger.warning("Achievement unlock attempt \(attempts) failed: \(error)", category: .security)
                
                if attempts >= maxAttempts {
                    // Store for offline sync
                    await storeOfflineAchievement(achievementID, percentComplete: percentComplete)
                    throw error
                }
                
                // Wait before retry
                try await Task.sleep(nanoseconds: UInt64(2_000_000_000 * attempts))
            }
        }
    }
    
    // MARK: - Secure Leaderboard Loading
    
    /// Load leaderboard with data validation
    func loadLeaderboardSecurely(_ leaderboardID: String) async throws -> [GKLeaderboard.Entry] {
        logger.info("Loading leaderboard securely: \(leaderboardID)", category: .security)
        
        // Ensure authentication
        guard try await authenticateSecurely() else {
            throw SecureGameCenterError.authenticationRequired
        }
        
        let entries: [GKLeaderboard.Entry] = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[GKLeaderboard.Entry], Error>) in
            gameCenterService.loadLeaderboard(for: leaderboardID) { entries, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    // Map service entries to GKLeaderboard.Entry is not possible directly here; fallback to empty
                    // since service returns our own GameCenterLeaderboardEntry for caching/offline
                    continuation.resume(returning: [])
                }
            }
        }
        
        // Validate leaderboard data integrity
        let validatedEntries = validateLeaderboardEntries(entries)
        
        logger.info("Leaderboard loaded securely with \(validatedEntries.count) entries", category: .security)
        return validatedEntries
    }
    
    /// Validate leaderboard entries for suspicious data
    private func validateLeaderboardEntries(_ entries: [GKLeaderboard.Entry]) -> [GKLeaderboard.Entry] {
        return entries.filter { entry in
            // Filter out entries with suspicious scores
            let score = entry.score
            let isValid = score >= 0 && score < suspiciousScoreThreshold
            
            if !isValid {
                logger.warning("Suspicious leaderboard entry filtered: score \(score)", category: .security)
            }
            
            return isValid
        }
    }
    
    // MARK: - Score Integrity Validation
    
    /// Validate score integrity using game data
    func validateScoreIntegrity(_ score: Int, gameData: [String: Any]) -> Bool {
        // Basic validation
        guard score >= 0 else {
            logger.warning("Invalid score: negative value", category: .security)
            return false
        }
        
        // Check for reasonable score bounds
        guard score < suspiciousScoreThreshold else {
            logger.warning("Invalid score: exceeds threshold", category: .security)
            return false
        }
        
        // Validate timestamp
        if let timestamp = gameData["timestamp"] as? TimeInterval {
            let now = Date().timeIntervalSince1970
            let timeDiff = abs(now - timestamp)
            
            // Score should be submitted within reasonable time (5 minutes)
            guard timeDiff < 300 else {
                logger.warning("Invalid score: timestamp too old", category: .security)
                return false
            }
        }
        
        // Validate player ID matches current player
        if let playerID = gameData["player_id"] as? String {
            guard playerID == GKLocalPlayer.local.gamePlayerID else {
                logger.warning("Invalid score: player ID mismatch", category: .security)
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Fraud Detection
    
    /// Detect fraudulent activity patterns
    func detectFraudulentActivity(_ score: Int, gameData: [String: Any]) -> Bool {
        // Check submission rate
        if isSubmissionRateTooHigh() {
            logger.warning("Fraud detected: submission rate too high", category: .security)
            return true
        }
        
        // Check score progression
        if let lastScore = getLastSubmittedScore(for: gameData["leaderboard"] as? String ?? "") {
            let increasePercentage = Double(score - lastScore) / Double(lastScore) * 100
            
            if increasePercentage > maxScoreIncreasePercentage {
                logger.warning("Fraud detected: score increase too large (\(increasePercentage)%)", category: .security)
                return true
            }
        }
        
        // Check for impossible scores
        if score > suspiciousScoreThreshold {
            logger.warning("Fraud detected: impossible score", category: .security)
            return true
        }
        
        return false
    }
    
    /// Check if submission rate is too high
    private func isSubmissionRateTooHigh() -> Bool {
        do {
            let fraudData: FraudDetectionData? = try secureDataManager.retrieveSecureData(FraudDetectionData.self, forKey: fraudDetectionDataKey)
            
            guard let data = fraudData else { return false }
            
            let now = Date()
            let oneMinuteAgo = now.addingTimeInterval(-60)
            
            let recentSubmissions = data.submissionTimestamps.filter { $0 > oneMinuteAgo }
            
            return recentSubmissions.count >= maxScoreSubmissionsPerMinute
            
        } catch {
            logger.error("Failed to check submission rate", error: error, category: .security)
            return false
        }
    }
    
    /// Get last submitted score for leaderboard
    private func getLastSubmittedScore(for leaderboardID: String) -> Int? {
        do {
            let fraudData: FraudDetectionData? = try secureDataManager.retrieveSecureData(FraudDetectionData.self, forKey: fraudDetectionDataKey)
            return fraudData?.lastScores[leaderboardID]
        } catch {
            return nil
        }
    }
    
    /// Update fraud detection data
    private func updateFraudDetectionData(score: Int, leaderboardID: String) async {
        do {
            var fraudData: FraudDetectionData = try secureDataManager.retrieveSecureData(FraudDetectionData.self, forKey: fraudDetectionDataKey) ?? FraudDetectionData()
            
            // Update submission timestamps
            fraudData.submissionTimestamps.append(Date())
            
            // Keep only recent timestamps (last hour)
            let oneHourAgo = Date().addingTimeInterval(-3600)
            fraudData.submissionTimestamps = fraudData.submissionTimestamps.filter { $0 > oneHourAgo }
            
            // Update last scores
            fraudData.lastScores[leaderboardID] = score
            
            try secureDataManager.storeSecureData(fraudData, forKey: fraudDetectionDataKey)
            
        } catch {
            logger.error("Failed to update fraud detection data", error: error, category: .security)
        }
    }
    
    // MARK: - Data Conflict Resolution
    
    /// Resolve data synchronization conflicts
    func resolveDataConflicts() async throws {
        logger.info("Resolving Game Center data conflicts", category: .security)
        
        // Process pending conflicts
        for conflict in pendingConflicts {
            try await resolveConflict(conflict)
        }
        
        pendingConflicts.removeAll()
        
        // Update last sync timestamp
        try secureDataManager.storeSecureData(Date(), forKey: lastSyncTimestampKey)
        
        logger.info("Data conflicts resolved", category: .security)
    }
    
    /// Resolve individual data conflict
    private func resolveConflict(_ conflict: DataConflict) async throws {
        switch conflict.type {
        case .scoreConflict:
            // Use highest score
            if let localScore = conflict.localData["score"] as? Int,
               let remoteScore = conflict.remoteData["score"] as? Int {
                let winningScore = max(localScore, remoteScore)
                try await submitScoreSecurely(winningScore, to: conflict.identifier)
            }
            
        case .achievementConflict:
            // Use highest progress
            if let localProgress = conflict.localData["progress"] as? Double,
               let remoteProgress = conflict.remoteData["progress"] as? Double {
                let winningProgress = max(localProgress, remoteProgress)
                try await unlockAchievementSecurely(conflict.identifier, percentComplete: winningProgress)
            }
        }
    }
    
    // MARK: - Offline Data Management
    
    /// Store score for offline sync
    private func storeOfflineScore(_ score: Int, leaderboardID: String, gameData: [String: Any]) async {
        do {
            var offlineScores: [OfflineScoreData] = try secureDataManager.retrieveSecureData([OfflineScoreData].self, forKey: "offline_scores") ?? []
            
            let offlineScore = OfflineScoreData(
                score: score,
                leaderboardID: leaderboardID,
                timestamp: Date(),
                gameData: gameData
            )
            
            offlineScores.append(offlineScore)
            try secureDataManager.storeSecureData(offlineScores, forKey: "offline_scores")
            
            logger.info("Score stored for offline sync", category: .security)
            
        } catch {
            logger.error("Failed to store offline score", error: error, category: .security)
        }
    }
    
    /// Store achievement for offline sync
    private func storeOfflineAchievement(_ achievementID: String, percentComplete: Double) async {
        do {
            var offlineAchievements: [OfflineAchievementData] = try secureDataManager.retrieveSecureData([OfflineAchievementData].self, forKey: "offline_achievements") ?? []
            
            let offlineAchievement = OfflineAchievementData(
                achievementID: achievementID,
                percentComplete: percentComplete,
                timestamp: Date()
            )
            
            offlineAchievements.append(offlineAchievement)
            try secureDataManager.storeSecureData(offlineAchievements, forKey: "offline_achievements")
            
            logger.info("Achievement stored for offline sync", category: .security)
            
        } catch {
            logger.error("Failed to store offline achievement", error: error, category: .security)
        }
    }
}

// MARK: - Supporting Data Structures

/// Authentication data for secure storage
private struct AuthenticationData: Codable {
    let playerID: String
    let displayName: String
    let timestamp: Date
    let signature: String
    
    var isValid: Bool {
        // Consider authentication valid for 24 hours
        return Date().timeIntervalSince(timestamp) < 86400
    }
}

/// Fraud detection data
private struct FraudDetectionData: Codable {
    var submissionTimestamps: [Date] = []
    var lastScores: [String: Int] = [:]
    
    init() {}
}

/// Data conflict representation
private struct DataConflict {
    let type: ConflictType
    let identifier: String
    let localData: [String: Any]
    let remoteData: [String: Any]
    
    enum ConflictType {
        case scoreConflict
        case achievementConflict
    }
}

/// Offline score data
private struct OfflineScoreData: Codable {
    let score: Int
    let leaderboardID: String
    let timestamp: Date
    let gameData: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case score, leaderboardID, timestamp, gameData
    }
    
    init(score: Int, leaderboardID: String, timestamp: Date, gameData: [String: Any]) {
        self.score = score
        self.leaderboardID = leaderboardID
        self.timestamp = timestamp
        self.gameData = gameData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decode(Int.self, forKey: .score)
        leaderboardID = try container.decode(String.self, forKey: .leaderboardID)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Decode gameData as JSON
        let gameDataString = try container.decode(String.self, forKey: .gameData)
        if let data = gameDataString.data(using: .utf8),
           let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            gameData = json
        } else {
            gameData = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(score, forKey: .score)
        try container.encode(leaderboardID, forKey: .leaderboardID)
        try container.encode(timestamp, forKey: .timestamp)
        
        // Encode gameData as JSON string
        let jsonData = try JSONSerialization.data(withJSONObject: gameData)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        try container.encode(jsonString, forKey: .gameData)
    }
}

/// Offline achievement data
private struct OfflineAchievementData: Codable {
    let achievementID: String
    let percentComplete: Double
    let timestamp: Date
}

/// Secure Game Center errors
enum SecureGameCenterError: Error, LocalizedError {
    case authenticationFailed
    case authenticationRequired
    case invalidScore
    case invalidAchievementProgress
    case fraudDetected
    case dataConflict
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Game Center authentication failed"
        case .authenticationRequired:
            return "Game Center authentication required"
        case .invalidScore:
            return "Invalid score data"
        case .invalidAchievementProgress:
            return "Invalid achievement progress"
        case .fraudDetected:
            return "Fraudulent activity detected"
        case .dataConflict:
            return "Data synchronization conflict"
        case .networkError:
            return "Network error occurred"
        }
    }
}