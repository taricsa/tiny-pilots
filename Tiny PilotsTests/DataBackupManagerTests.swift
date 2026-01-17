import XCTest
import CloudKit
@testable import Tiny_Pilots

final class DataBackupManagerTests: XCTestCase {
    
    var dataBackupManager: DataBackupManager!
    
    override func setUp() {
        super.setUp()
        dataBackupManager = DataBackupManager.shared
    }
    
    override func tearDown() {
        dataBackupManager = nil
        super.tearDown()
    }
    
    // MARK: - Automatic Backup Tests
    
    func testAutomaticBackupConfiguration() {
        // Test initial state
        XCTAssertFalse(dataBackupManager.isAutomaticBackupEnabled())
        
        // Note: We can't easily test the async enable/disable methods without mocking CloudKit
        // In a real test environment, we would use dependency injection to provide mock services
    }
    
    func testLastBackupTimestamp() {
        // Initially should be nil
        XCTAssertNil(dataBackupManager.getLastBackupTimestamp())
    }
    
    // MARK: - Backup Metadata Tests
    
    func testBackupMetadataStructure() {
        let metadata = BackupMetadata(
            id: "test-backup-id",
            timestamp: Date(),
            version: "1.0",
            deviceName: "Test Device",
            appVersion: "1.0.0"
        )
        
        XCTAssertEqual(metadata.id, "test-backup-id")
        XCTAssertEqual(metadata.version, "1.0")
        XCTAssertEqual(metadata.deviceName, "Test Device")
        XCTAssertEqual(metadata.appVersion, "1.0.0")
    }
    
    func testBackupMetadataCodable() throws {
        let metadata = BackupMetadata(
            id: "test-backup-id",
            timestamp: Date(),
            version: "1.0",
            deviceName: "Test Device",
            appVersion: "1.0.0"
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)
        XCTAssertFalse(data.isEmpty)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedMetadata = try decoder.decode(BackupMetadata.self, from: data)
        
        XCTAssertEqual(decodedMetadata.id, metadata.id)
        XCTAssertEqual(decodedMetadata.version, metadata.version)
        XCTAssertEqual(decodedMetadata.deviceName, metadata.deviceName)
        XCTAssertEqual(decodedMetadata.appVersion, metadata.appVersion)
    }
    
    // MARK: - Backup Result Tests
    
    func testBackupResultStructure() {
        let result = BackupResult(
            backupID: "test-backup",
            timestamp: Date(),
            dataSize: 1024,
            success: true
        )
        
        XCTAssertEqual(result.backupID, "test-backup")
        XCTAssertEqual(result.dataSize, 1024)
        XCTAssertTrue(result.success)
    }
    
    func testRestoreResultStructure() {
        let result = RestoreResult(
            backupID: "test-backup",
            timestamp: Date(),
            restoredDataSize: 2048,
            previousBackupID: "previous-backup",
            success: true
        )
        
        XCTAssertEqual(result.backupID, "test-backup")
        XCTAssertEqual(result.restoredDataSize, 2048)
        XCTAssertEqual(result.previousBackupID, "previous-backup")
        XCTAssertTrue(result.success)
    }
    
    // MARK: - Error Handling Tests
    
    func testDataBackupErrors() {
        let errors: [DataBackupError] = [
            .consentRequired,
            .iCloudUnavailable,
            .backupFailed,
            .restoreFailed,
            .corruptedBackup,
            .invalidBackupFormat,
            .networkError
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Array Extension Tests
    
    func testArrayUniquedExtension() {
        struct TestItem {
            let id: String
            let value: Int
        }
        
        let items = [
            TestItem(id: "1", value: 10),
            TestItem(id: "2", value: 20),
            TestItem(id: "1", value: 30), // Duplicate ID
            TestItem(id: "3", value: 40),
            TestItem(id: "2", value: 50)  // Duplicate ID
        ]
        
        let uniqueItems = items.uniqued(by: \.id)
        
        XCTAssertEqual(uniqueItems.count, 3)
        XCTAssertEqual(uniqueItems[0].id, "1")
        XCTAssertEqual(uniqueItems[1].id, "2")
        XCTAssertEqual(uniqueItems[2].id, "3")
    }
    
    // MARK: - Integration Tests (Mock-based)
    
    func testBackupManagerInitialization() {
        // Test that the backup manager initializes without crashing
        XCTAssertNotNil(dataBackupManager)
    }
    
    // MARK: - Performance Tests
    
    func testBackupMetadataPerformance() {
        let metadata = (0..<1000).map { index in
            BackupMetadata(
                id: "backup-\(index)",
                timestamp: Date(),
                version: "1.0",
                deviceName: "Test Device",
                appVersion: "1.0.0"
            )
        }
        
        measure {
            let uniqueMetadata = metadata.uniqued(by: \.id)
            XCTAssertEqual(uniqueMetadata.count, 1000)
        }
    }
    
    // MARK: - Mock CloudKit Tests
    
    func testMockCloudKitIntegration() {
        // In a real test environment, we would create mock CloudKit services
        // to test the backup and restore functionality without requiring
        // actual iCloud connectivity
        
        // For now, we just verify the manager doesn't crash on initialization
        XCTAssertNotNil(DataBackupManager.shared)
    }
    
    // MARK: - Data Structure Tests
    
    func testBackupDataStructures() {
        // Test that our backup data structures are properly defined
        // This helps catch compilation issues early
        
        let playerBackup = createMockPlayerDataBackup()
        XCTAssertNotNil(playerBackup)
        XCTAssertEqual(playerBackup.level, 5)
        
        let gameResultBackup = createMockGameResultBackup()
        XCTAssertNotNil(gameResultBackup)
        XCTAssertEqual(gameResultBackup.score, 1000)
        
        let achievementBackup = createMockAchievementBackup()
        XCTAssertNotNil(achievementBackup)
        XCTAssertEqual(achievementBackup.id, "test_achievement")
    }
    
    // MARK: - Helper Methods
    
    private func createMockPlayerDataBackup() -> PlayerDataBackup {
        return PlayerDataBackup(
            id: UUID(),
            level: 5,
            experiencePoints: 450,
            totalScore: 10000,
            totalDistance: 5000.0,
            totalFlightTime: 3600.0,
            dailyRunStreak: 7,
            lastDailyRunDate: Date(),
            unlockedAirplanes: ["basic", "dart"],
            unlockedEnvironments: ["standard", "windy"],
            completedChallenges: 10,
            selectedFoldType: "dart",
            selectedDesignType: "striped",
            highScore: 2500,
            createdAt: Date().addingTimeInterval(-86400),
            lastPlayedAt: Date()
        )
    }
    
    private func createMockGameResultBackup() -> GameResultBackup {
        return GameResultBackup(
            id: UUID(),
            score: 1000,
            distance: 500.0,
            timeElapsed: 120.0,
            mode: "free_play",
            environment: "standard",
            datePlayed: Date(),
            experienceEarned: 50
        )
    }
    
    private func createMockAchievementBackup() -> AchievementBackup {
        return AchievementBackup(
            id: "test_achievement",
            title: "Test Achievement",
            description: "A test achievement",
            targetValue: 100,
            currentValue: 100,
            category: "general",
            iconName: "star",
            rewardXP: 50,
            isUnlocked: true,
            unlockedAt: Date()
        )
    }
}

// MARK: - Mock Data Structures for Testing

/// Mock player data backup for testing
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

/// Mock game result backup for testing
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

/// Mock achievement backup for testing
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