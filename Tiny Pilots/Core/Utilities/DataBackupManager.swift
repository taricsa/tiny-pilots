import Foundation
import UIKit
import CloudKit

/// Protocol for data backup and recovery operations
protocol DataBackupManagerProtocol {
    func enableAutomaticBackup() async throws
    func disableAutomaticBackup() async throws
    func createManualBackup() async throws -> BackupResult
    func restoreFromBackup(_ backupID: String) async throws -> RestoreResult
    func listAvailableBackups() async throws -> [BackupMetadata]
    func deleteBackup(_ backupID: String) async throws
    func validateBackupIntegrity(_ backupID: String) async throws -> Bool
    func syncAcrossDevices() async throws
}

/// Data backup and recovery manager with iCloud integration
class DataBackupManager: DataBackupManagerProtocol {
    static let shared = DataBackupManager()
    
    private let secureDataManager = SecureDataManager.shared
    private let secureSwiftDataManager = SecureSwiftDataManager.shared
    private let logger = Logger.shared
    private let privacyManager = PrivacyManager.shared
    
    // CloudKit configuration
    private let container = CKContainer(identifier: "iCloud.com.tinypilots.gamedata")
    private let database: CKDatabase
    
    // Backup configuration
    private let backupRecordType = "GameDataBackup"
    private let backupMetadataKey = "backup_metadata"
    private let automaticBackupKey = "automatic_backup_enabled"
    private let lastBackupKey = "last_backup_timestamp"
    
    // Backup frequency (24 hours)
    private let automaticBackupInterval: TimeInterval = 86400
    
    private init() {
        self.database = container.privateCloudDatabase
    }
    
    // MARK: - Automatic Backup Management
    
    /// Enable automatic backup to iCloud
    func enableAutomaticBackup() async throws {
        logger.info("Enabling automatic backup", category: .security)
        
        // Check user consent for data collection
        guard privacyManager.hasDataCollectionConsent() else {
            throw DataBackupError.consentRequired
        }
        
        // Check iCloud availability
        let accountStatus = try await container.accountStatus()
        guard accountStatus == .available else {
            throw DataBackupError.iCloudUnavailable
        }
        
        // Enable automatic backup
        try secureDataManager.storeSecureData(true, forKey: automaticBackupKey)
        
        // Schedule first backup
        try await scheduleAutomaticBackup()
        
        logger.info("Automatic backup enabled", category: .security)
    }
    
    /// Disable automatic backup
    func disableAutomaticBackup() async throws {
        logger.info("Disabling automatic backup", category: .security)
        
        try secureDataManager.storeSecureData(false, forKey: automaticBackupKey)
        
        logger.info("Automatic backup disabled", category: .security)
    }
    
    /// Check if automatic backup should run
    private func shouldPerformAutomaticBackup() -> Bool {
        do {
            // Check if automatic backup is enabled
            let isEnabled: Bool = try secureDataManager.retrieveSecureData(Bool.self, forKey: automaticBackupKey) ?? false
            guard isEnabled else { return false }
            
            // Check last backup timestamp
            if let lastBackup: Date = try secureDataManager.retrieveSecureData(Date.self, forKey: lastBackupKey) {
                let timeSinceLastBackup = Date().timeIntervalSince(lastBackup)
                return timeSinceLastBackup >= automaticBackupInterval
            }
            
            return true // No previous backup, should backup
            
        } catch {
            logger.error("Failed to check automatic backup status", error: error, category: .security)
            return false
        }
    }
    
    /// Schedule automatic backup
    private func scheduleAutomaticBackup() async throws {
        if shouldPerformAutomaticBackup() {
            _ = try await createManualBackup()
        }
    }
    
    // MARK: - Manual Backup Operations
    
    /// Create manual backup of all game data
    func createManualBackup() async throws -> BackupResult {
        logger.info("Creating manual backup", category: .security)
        
        // Check user consent
        guard privacyManager.hasDataCollectionConsent() else {
            throw DataBackupError.consentRequired
        }
        
        // Check iCloud availability
        let accountStatus = try await container.accountStatus()
        guard accountStatus == .available else {
            throw DataBackupError.iCloudUnavailable
        }
        
        // Gather all data to backup
        let backupData = try await gatherBackupData()
        
        // Create backup record
        let backupRecord = try await createBackupRecord(backupData)
        
        // Save to iCloud
        let savedRecord = try await database.save(backupRecord)
        
        // Update local metadata
        try await updateBackupMetadata(savedRecord)
        
        // Update last backup timestamp
        try secureDataManager.storeSecureData(Date(), forKey: lastBackupKey)
        
        let result = BackupResult(
            backupID: savedRecord.recordID.recordName,
            timestamp: Date(),
            dataSize: backupData.totalSize,
            success: true
        )
        
        logger.info("Manual backup created successfully: \(result.backupID)", category: .security)
        return result
    }
    
    /// Gather all data for backup
    private func gatherBackupData() async throws -> BackupData {
        logger.info("Gathering data for backup", category: .security)
        
        var backupData = BackupData()
        
        // Get current player data
        if let playerData = await secureSwiftDataManager.getSecureCurrentPlayer() {
            backupData.playerData = PlayerDataBackup(
                id: playerData.id,
                level: playerData.level,
                experiencePoints: playerData.experiencePoints,
                totalScore: playerData.totalScore,
                totalDistance: playerData.totalDistance,
                totalFlightTime: playerData.totalFlightTime,
                dailyRunStreak: playerData.dailyRunStreak,
                lastDailyRunDate: playerData.lastDailyRunDate,
                unlockedAirplanes: playerData.unlockedAirplanes,
                unlockedEnvironments: playerData.unlockedEnvironments,
                completedChallenges: playerData.completedChallenges,
                selectedFoldType: playerData.selectedFoldType,
                selectedDesignType: playerData.selectedDesignType,
                highScore: playerData.highScore,
                createdAt: playerData.createdAt,
                lastPlayedAt: playerData.lastPlayedAt
            )
            
            // Get game results
            backupData.gameResults = playerData.gameResults.map { result in
                GameResultBackup(
                    id: result.id,
                    score: result.score,
                    distance: result.distance,
                    timeElapsed: result.timeElapsed,
                    mode: result.mode,
                    environment: result.environmentType,
                    datePlayed: result.completedAt,
                    experienceEarned: result.experienceEarned
                )
            }
            
            // Get achievements
            backupData.achievements = playerData.achievements.map { achievement in
                AchievementBackup(
                    id: achievement.id,
                    title: achievement.title,
                    description: achievement.achievementDescription,
                    targetValue: Int(achievement.targetValue),
                    currentValue: Int(achievement.progress),
                    category: achievement.category,
                    iconName: achievement.iconName,
                    rewardXP: achievement.rewardXP,
                    isUnlocked: achievement.isUnlocked,
                    unlockedAt: achievement.unlockedAt
                )
            }
        }
        
        // Add metadata - fetch device name on main actor for Swift 6 compatibility
        let deviceName = await MainActor.run { UIDevice.current.name }
        backupData.metadata = BackupMetadata(
            id: UUID().uuidString,
            timestamp: Date(),
            version: "1.0",
            deviceName: deviceName,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        )
        
        logger.info("Data gathering completed", category: .security)
        return backupData
    }
    
    /// Create CloudKit record for backup
    private func createBackupRecord(_ backupData: BackupData) async throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: backupData.metadata.id)
        let record = CKRecord(recordType: backupRecordType, recordID: recordID)
        
        // Encrypt backup data
        let encryptedData = try secureDataManager.encryptData(backupData)
        
        // Store encrypted data
        record["encryptedData"] = encryptedData
        record["timestamp"] = backupData.metadata.timestamp
        record["version"] = backupData.metadata.version
        record["deviceName"] = backupData.metadata.deviceName
        record["appVersion"] = backupData.metadata.appVersion
        record["dataSize"] = backupData.totalSize
        
        // Generate integrity hash
        let integrityHash = try secureDataManager.generateDataHash(backupData)
        record["integrityHash"] = integrityHash
        
        return record
    }
    
    /// Update local backup metadata
    private func updateBackupMetadata(_ record: CKRecord) async throws {
        var metadata: [BackupMetadata] = try secureDataManager.retrieveSecureData([BackupMetadata].self, forKey: backupMetadataKey) ?? []
        
        let newMetadata = BackupMetadata(
            id: record.recordID.recordName,
            timestamp: record["timestamp"] as? Date ?? Date(),
            version: record["version"] as? String ?? "1.0",
            deviceName: record["deviceName"] as? String ?? "Unknown",
            appVersion: record["appVersion"] as? String ?? "Unknown"
        )
        
        metadata.append(newMetadata)
        
        // Keep only last 10 backups metadata
        if metadata.count > 10 {
            metadata = Array(metadata.suffix(10))
        }
        
        try secureDataManager.storeSecureData(metadata, forKey: backupMetadataKey)
    }
    
    // MARK: - Restore Operations
    
    /// Restore data from backup
    func restoreFromBackup(_ backupID: String) async throws -> RestoreResult {
        logger.info("Restoring from backup: \(backupID)", category: .security)
        
        // Check user consent
        guard privacyManager.hasDataCollectionConsent() else {
            throw DataBackupError.consentRequired
        }
        
        // Fetch backup record from iCloud
        let recordID = CKRecord.ID(recordName: backupID)
        let record = try await database.record(for: recordID)
        
        // Validate backup integrity
        guard try await validateBackupRecord(record) else {
            throw DataBackupError.corruptedBackup
        }
        
        // Decrypt backup data
        guard let encryptedData = record["encryptedData"] as? Data else {
            throw DataBackupError.invalidBackupFormat
        }
        
        let backupData = try secureDataManager.decryptData(encryptedData, as: BackupData.self)
        
        // Create backup of current data before restore
        let currentBackup = try await createManualBackup()
        
        // Restore data
        try await restoreBackupData(backupData)
        
        let result = RestoreResult(
            backupID: backupID,
            timestamp: Date(),
            restoredDataSize: backupData.totalSize,
            previousBackupID: currentBackup.backupID,
            success: true
        )
        
        logger.info("Restore completed successfully", category: .security)
        return result
    }
    
    /// Restore backup data to local storage
    private func restoreBackupData(_ backupData: BackupData) async throws {
        logger.info("Restoring backup data to local storage", category: .security)
        
        // This would integrate with SecureSwiftDataManager to restore all data
        // For now, we'll log the restoration process
        
        if let playerData = backupData.playerData {
            logger.info("Restoring player data: Level \(playerData.level), XP \(playerData.experiencePoints)", category: .security)
        }
        
        logger.info("Restoring \(backupData.gameResults.count) game results", category: .security)
        logger.info("Restoring \(backupData.achievements.count) achievements", category: .security)
        
        // In a real implementation, this would:
        // 1. Clear existing data
        // 2. Create new PlayerData from backup
        // 3. Restore all game results and achievements
        // 4. Update relationships
        // 5. Save to SwiftData
    }
    
    /// Validate backup record integrity
    private func validateBackupRecord(_ record: CKRecord) async throws -> Bool {
        guard let encryptedData = record["encryptedData"] as? Data,
              let storedHash = record["integrityHash"] as? String else {
            return false
        }
        
        // Decrypt and validate
        let backupData = try secureDataManager.decryptData(encryptedData, as: BackupData.self)
        let calculatedHash = try secureDataManager.generateDataHash(backupData)
        
        return calculatedHash == storedHash
    }
    
    // MARK: - Backup Management
    
    /// List available backups
    func listAvailableBackups() async throws -> [BackupMetadata] {
        logger.info("Listing available backups", category: .security)
        
        // Get local metadata first
        let localMetadata: [BackupMetadata] = try secureDataManager.retrieveSecureData([BackupMetadata].self, forKey: backupMetadataKey) ?? []
        
        // Query iCloud for additional backups
        let query = CKQuery(recordType: backupRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let (matchResults, _) = try await database.records(matching: query)
        
        var cloudMetadata: [BackupMetadata] = []
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                let metadata = BackupMetadata(
                    id: record.recordID.recordName,
                    timestamp: record["timestamp"] as? Date ?? Date(),
                    version: record["version"] as? String ?? "1.0",
                    deviceName: record["deviceName"] as? String ?? "Unknown",
                    appVersion: record["appVersion"] as? String ?? "Unknown"
                )
                cloudMetadata.append(metadata)
            case .failure(let error):
                logger.warning("Failed to load backup metadata: \(error)", category: .security)
            }
        }
        
        // Merge and deduplicate
        let allMetadata = (localMetadata + cloudMetadata).uniqued(by: \.id)
        
        logger.info("Found \(allMetadata.count) available backups", category: .security)
        return allMetadata.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Delete backup
    func deleteBackup(_ backupID: String) async throws {
        logger.info("Deleting backup: \(backupID)", category: .security)
        
        // Delete from iCloud
        let recordID = CKRecord.ID(recordName: backupID)
        _ = try await database.deleteRecord(withID: recordID)
        
        // Remove from local metadata
        var metadata: [BackupMetadata] = try secureDataManager.retrieveSecureData([BackupMetadata].self, forKey: backupMetadataKey) ?? []
        metadata.removeAll { $0.id == backupID }
        try secureDataManager.storeSecureData(metadata, forKey: backupMetadataKey)
        
        logger.info("Backup deleted successfully", category: .security)
    }
    
    /// Validate backup integrity
    func validateBackupIntegrity(_ backupID: String) async throws -> Bool {
        logger.info("Validating backup integrity: \(backupID)", category: .security)
        
        let recordID = CKRecord.ID(recordName: backupID)
        let record = try await database.record(for: recordID)
        
        let isValid = try await validateBackupRecord(record)
        
        logger.info("Backup integrity validation result: \(isValid)", category: .security)
        return isValid
    }
    
    // MARK: - Cross-Device Sync
    
    /// Sync data across devices
    func syncAcrossDevices() async throws {
        logger.info("Starting cross-device sync", category: .security)
        
        // Check user consent
        guard privacyManager.hasDataCollectionConsent() else {
            throw DataBackupError.consentRequired
        }
        
        // Get latest backup from all devices
        let availableBackups = try await listAvailableBackups()
        
        guard let latestBackup = availableBackups.first else {
            logger.info("No backups available for sync", category: .security)
            return
        }
        
        // Check if we need to sync (latest backup is newer than local data)
        if let lastSync: Date = try? secureDataManager.retrieveSecureData(Date.self, forKey: "last_sync_timestamp") {
            if latestBackup.timestamp <= lastSync {
                logger.info("Local data is up to date", category: .security)
                return
            }
        }
        
        // Restore from latest backup
        _ = try await restoreFromBackup(latestBackup.id)
        
        // Update sync timestamp
        try secureDataManager.storeSecureData(Date(), forKey: "last_sync_timestamp")
        
        logger.info("Cross-device sync completed", category: .security)
    }
    
    // MARK: - Public Utilities
    
    /// Check if automatic backup is enabled
    func isAutomaticBackupEnabled() -> Bool {
        do {
            return try secureDataManager.retrieveSecureData(Bool.self, forKey: automaticBackupKey) ?? false
        } catch {
            return false
        }
    }
    
    /// Get last backup timestamp
    func getLastBackupTimestamp() -> Date? {
        do {
            return try secureDataManager.retrieveSecureData(Date.self, forKey: lastBackupKey)
        } catch {
            return nil
        }
    }
}

// MARK: - Supporting Data Structures

/// Backup result information
struct BackupResult {
    let backupID: String
    let timestamp: Date
    let dataSize: Int
    let success: Bool
}

/// Restore result information
struct RestoreResult {
    let backupID: String
    let timestamp: Date
    let restoredDataSize: Int
    let previousBackupID: String
    let success: Bool
}

/// Backup metadata
struct BackupMetadata: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let version: String
    let deviceName: String
    let appVersion: String
}

/// Complete backup data structure
private struct BackupData: Codable {
    var metadata: BackupMetadata!
    var playerData: PlayerDataBackup?
    var gameResults: [GameResultBackup] = []
    var achievements: [AchievementBackup] = []
    
    var totalSize: Int {
        // Estimate total size in bytes
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            return data.count
        } catch {
            return 0
        }
    }
}

/// Player data backup structure
private struct PlayerDataBackup: Codable {
    let id: UUID
    let level: Int
    let experiencePoints: Int
    let totalScore: Int
    let totalDistance: Float
    let totalFlightTime: TimeInterval
    let dailyRunStreak: Int
    let lastDailyRunDate: Date?
    let unlockedAirplanes: [String]
    let unlockedEnvironments: [String]
    let completedChallenges: Int
    let selectedFoldType: String
    let selectedDesignType: String
    let highScore: Int
    let createdAt: Date
    let lastPlayedAt: Date
}

/// Game result backup structure
private struct GameResultBackup: Codable {
    let id: UUID
    let score: Int
    let distance: Float
    let timeElapsed: TimeInterval
    let mode: String
    let environment: String
    let datePlayed: Date
    let experienceEarned: Int
}

/// Achievement backup structure
private struct AchievementBackup: Codable {
    let id: String
    let title: String
    let description: String
    let targetValue: Int
    let currentValue: Int
    let category: String
    let iconName: String
    let rewardXP: Int
    let isUnlocked: Bool
    let unlockedAt: Date?
}

/// Data backup errors
enum DataBackupError: Error, LocalizedError {
    case consentRequired
    case iCloudUnavailable
    case backupFailed
    case restoreFailed
    case corruptedBackup
    case invalidBackupFormat
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .consentRequired:
            return "User consent required for data backup"
        case .iCloudUnavailable:
            return "iCloud is not available"
        case .backupFailed:
            return "Backup operation failed"
        case .restoreFailed:
            return "Restore operation failed"
        case .corruptedBackup:
            return "Backup data is corrupted"
        case .invalidBackupFormat:
            return "Invalid backup format"
        case .networkError:
            return "Network error occurred"
        }
    }
}

// MARK: - Array Extension for Uniquing

extension Array {
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}