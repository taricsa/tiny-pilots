import Foundation
import SwiftData

/// Secure wrapper for SwiftData operations with encryption and integrity validation
class SecureSwiftDataManager {
    static let shared = SecureSwiftDataManager()
    
    private let swiftDataManager = SwiftDataManager.shared
    private let secureDataManager = SecureDataManager.shared
    private let logger = Logger.shared
    
    // Keys for secure storage
    private let playerDataBackupKey = "player_data_backup"
    private let gameResultsBackupKey = "game_results_backup"
    private let achievementsBackupKey = "achievements_backup"
    private let dataIntegrityKey = "data_integrity_hash"
    
    private init() {}
    
    // MARK: - Secure Player Data Operations
    
    /// Get current player with integrity validation
    @MainActor
    func getSecureCurrentPlayer() async -> PlayerData? {
        guard let player = swiftDataManager.getCurrentPlayer() else {
            logger.warning("No player data found", category: .security)
            return await attemptDataRecovery()
        }
        
        // Validate data integrity
        if await validatePlayerDataIntegrity(player) {
            return player
        } else {
            logger.warning("Player data integrity check failed, attempting recovery", category: .security)
            return await attemptDataRecovery()
        }
    }
    
    /// Save player data with secure backup
    @MainActor
    func saveSecurePlayerData(_ player: PlayerData) async {
        // Validate data before saving
        let validationErrors = player.validateDataIntegrity()
        if !validationErrors.isEmpty {
            logger.error("Player data validation failed: \(validationErrors.joined(separator: ", "))", category: .security)
            return
        }
        
        // Save to SwiftData
        swiftDataManager.save()
        
        // Create secure backup
        await createSecureBackup(player)
        
        logger.info("Player data saved securely with backup", category: .security)
    }
    
    /// Create encrypted backup of player data
    @MainActor
    private func createSecureBackup(_ player: PlayerData) async {
        do {
            // Create backup data structure
            let backupData = PlayerDataBackup(
                playerData: PlayerDataCodable(from: player),
                gameResults: player.gameResults.map { GameResultCodable(from: $0) },
                achievements: player.achievements.map { AchievementCodable(from: $0) },
                timestamp: Date(),
                version: "1.0"
            )
            
            // Store encrypted backup
            try secureDataManager.storeSecureData(backupData, forKey: playerDataBackupKey)
            
            // Generate and store integrity hash
            let integrityHash = try secureDataManager.generateDataHash(backupData)
            try secureDataManager.storeSecureData(integrityHash, forKey: dataIntegrityKey)
            
            logger.info("Secure backup created successfully", category: .security)
            
        } catch {
            logger.error("Failed to create secure backup", error: error, category: .security)
        }
    }
    
    /// Validate player data integrity
    @MainActor
    private func validatePlayerDataIntegrity(_ player: PlayerData) async -> Bool {
        do {
            // Check if we have a stored integrity hash
            guard let storedHash: String = try secureDataManager.retrieveSecureData(String.self, forKey: dataIntegrityKey) else {
                logger.debug("No integrity hash found, assuming first run", category: .security)
                return true
            }
            
            // Get current backup data
            guard let backupData: PlayerDataBackup = try secureDataManager.retrieveSecureData(PlayerDataBackup.self, forKey: playerDataBackupKey) else {
                logger.warning("No backup data found for integrity check", category: .security)
                return false
            }
            
            // Validate integrity
            let isValid = secureDataManager.validateDataIntegrity(backupData, expectedHash: storedHash)
            
            if !isValid {
                logger.error("Data integrity validation failed", category: .security)
            }
            
            return isValid
            
        } catch {
            logger.error("Error during integrity validation", error: error, category: .security)
            return false
        }
    }
    
    /// Attempt to recover data from secure backup
    @MainActor
    private func attemptDataRecovery() async -> PlayerData? {
        logger.info("Attempting data recovery from secure backup", category: .security)
        
        do {
            guard let backupData: PlayerDataBackup = try secureDataManager.retrieveSecureData(PlayerDataBackup.self, forKey: playerDataBackupKey) else {
                logger.warning("No backup data available for recovery", category: .security)
                return createNewPlayerData()
            }
            
            // Validate backup integrity
            guard let storedHash: String = try secureDataManager.retrieveSecureData(String.self, forKey: dataIntegrityKey),
                  secureDataManager.validateDataIntegrity(backupData, expectedHash: storedHash) else {
                logger.error("Backup data integrity check failed", category: .security)
                return createNewPlayerData()
            }
            
            // Restore data to SwiftData
            let context = await swiftDataManager.mainContext
            
            // Clear existing corrupted data
            try clearCorruptedData(in: context)
            
            // Insert recovered player data
            let recoveredPlayer = backupData.playerData.toModel(in: context)
            
            // Insert game results
            for resultBackup in backupData.gameResults {
                let gameResult = resultBackup.toModel(in: context, player: recoveredPlayer)
                context.insert(gameResult)
            }
            
            // Insert achievements
            for achievementBackup in backupData.achievements {
                let achievement = achievementBackup.toModel(in: context, player: recoveredPlayer)
                context.insert(achievement)
            }
            
            try context.save()
            
            logger.info("Data recovery completed successfully", category: .security)
            return recoveredPlayer
            
        } catch {
            logger.error("Data recovery failed", error: error, category: .security)
            return createNewPlayerData()
        }
    }
    
    /// Clear corrupted data from context
    @MainActor
    private func clearCorruptedData(in context: ModelContext) throws {
        // Delete all existing player data
        let playerFetch = FetchDescriptor<PlayerData>()
        let players = try context.fetch(playerFetch)
        for player in players {
            context.delete(player)
        }
        
        // Delete all game results
        let gameResultsFetch = FetchDescriptor<GameResult>()
        let gameResults = try context.fetch(gameResultsFetch)
        for result in gameResults {
            context.delete(result)
        }
        
        // Delete all achievements
        let achievementsFetch = FetchDescriptor<Achievement>()
        let achievements = try context.fetch(achievementsFetch)
        for achievement in achievements {
            context.delete(achievement)
        }
        
        try context.save()
        logger.info("Cleared corrupted data from context", category: .security)
    }
    
    /// Create new player data when recovery fails
    @MainActor
    private func createNewPlayerData() -> PlayerData? {
        logger.info("Creating new player data after recovery failure", category: .security)
        
        let context = swiftDataManager.mainContext
        let newPlayer = PlayerData()
        context.insert(newPlayer)
        
        // Create initial achievements
        createInitialAchievements(for: newPlayer, in: context)
        
        do {
            try context.save()
            logger.info("New player data created successfully", category: .security)
            return newPlayer
        } catch {
            logger.error("Failed to create new player data", error: error, category: .security)
            return nil
        }
    }
    
    /// Create initial achievements for a new player
    private func createInitialAchievements(for player: PlayerData, in context: ModelContext) {
        let initialAchievements = [
            Achievement(
                id: "first_flight",
                title: "First Flight",
                description: "Complete your first flight",
                targetValue: 1,
                category: "general",
                iconName: "airplane",
                rewardXP: 25
            ),
            Achievement(
                id: "distance_1000",
                title: "Sky Explorer",
                description: "Travel 1000 units in a single flight",
                targetValue: 1000,
                category: "distance",
                iconName: "map",
                rewardXP: 50
            )
        ]
        
        for achievement in initialAchievements {
            achievement.player = player
            context.insert(achievement)
        }
    }
    
    // MARK: - Migration Support
    
    /// Migrate existing unencrypted data to secure storage
    @MainActor
    func migrateToSecureStorage() async {
        logger.info("Starting migration to secure storage", category: .security)
        
        guard let currentPlayer = swiftDataManager.getCurrentPlayer() else {
            logger.info("No existing data to migrate", category: .security)
            return
        }
        
        // Create secure backup of existing data
        await createSecureBackup(currentPlayer)
        
        logger.info("Migration to secure storage completed", category: .security)
    }
    
    /// Verify secure storage is working correctly
    func verifySecureStorage() async -> Bool {
        do {
            // Test encryption/decryption with sample data
            let testData = TestData(value: "test", timestamp: Date())
            let testKey = "security_test"
            
            // Store test data
            try secureDataManager.storeSecureData(testData, forKey: testKey)
            
            // Retrieve and verify
            guard let retrievedData: TestData = try secureDataManager.retrieveSecureData(TestData.self, forKey: testKey) else {
                logger.error("Failed to retrieve test data", category: .security)
                return false
            }
            
            let isValid = retrievedData.value == testData.value
            
            // Clean up test data
            try secureDataManager.deleteSecureData(forKey: testKey)
            
            if isValid {
                logger.info("Secure storage verification passed", category: .security)
            } else {
                logger.error("Secure storage verification failed", category: .security)
            }
            
            return isValid
            
        } catch {
            logger.error("Secure storage verification error", error: error, category: .security)
            return false
        }
    }
}

// MARK: - Supporting Data Structures

/// Backup data structure for secure storage
private struct PlayerDataBackup: Codable {
    let playerData: PlayerDataCodable
    let gameResults: [GameResultCodable]
    let achievements: [AchievementCodable]
    let timestamp: Date
    let version: String
}

/// Test data structure for verification
private struct TestData: Codable {
    let value: String
    let timestamp: Date
}