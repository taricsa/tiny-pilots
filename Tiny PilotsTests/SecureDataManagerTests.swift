import XCTest
import Foundation
import CryptoKit

@testable import Tiny_Pilots

final class SecureDataManagerTests: XCTestCase {
    
    var secureDataManager: SecureDataManager!
    let testKey = "test_key"
    
    override func setUp() {
        super.setUp()
        secureDataManager = SecureDataManager.shared
        
        // Clean up any existing test data
        try? secureDataManager.deleteSecureData(forKey: testKey)
    }
    
    override func tearDown() {
        // Clean up test data
        try? secureDataManager.deleteSecureData(forKey: testKey)
        super.tearDown()
    }
    
    // MARK: - Basic Storage Tests
    
    func testStoreAndRetrieveSecureData() throws {
        let testData = TestSecureData(name: "Test", value: 42, timestamp: Date())
        
        // Store data
        try secureDataManager.storeSecureData(testData, forKey: testKey)
        
        // Retrieve data
        let retrievedData: TestSecureData? = try secureDataManager.retrieveSecureData(TestSecureData.self, forKey: testKey)
        
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData?.name, testData.name)
        XCTAssertEqual(retrievedData?.value, testData.value)
    }
    
    func testRetrieveNonExistentData() throws {
        let retrievedData: TestSecureData? = try secureDataManager.retrieveSecureData(TestSecureData.self, forKey: "non_existent_key")
        
        XCTAssertNil(retrievedData)
    }
    
    func testDeleteSecureData() throws {
        let testData = TestSecureData(name: "Test", value: 42, timestamp: Date())
        
        // Store data
        try secureDataManager.storeSecureData(testData, forKey: testKey)
        
        // Verify it exists
        let retrievedData: TestSecureData? = try secureDataManager.retrieveSecureData(TestSecureData.self, forKey: testKey)
        XCTAssertNotNil(retrievedData)
        
        // Delete data
        try secureDataManager.deleteSecureData(forKey: testKey)
        
        // Verify it's gone
        let deletedData: TestSecureData? = try secureDataManager.retrieveSecureData(TestSecureData.self, forKey: testKey)
        XCTAssertNil(deletedData)
    }
    
    func testOverwriteExistingData() throws {
        let originalData = TestSecureData(name: "Original", value: 1, timestamp: Date())
        let newData = TestSecureData(name: "New", value: 2, timestamp: Date())
        
        // Store original data
        try secureDataManager.storeSecureData(originalData, forKey: testKey)
        
        // Overwrite with new data
        try secureDataManager.storeSecureData(newData, forKey: testKey)
        
        // Retrieve and verify new data
        let retrievedData: TestSecureData? = try secureDataManager.retrieveSecureData(TestSecureData.self, forKey: testKey)
        
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData?.name, newData.name)
        XCTAssertEqual(retrievedData?.value, newData.value)
    }
    
    // MARK: - Encryption Tests
    
    func testEncryptAndDecryptData() throws {
        let testData = TestSecureData(name: "Encrypt Test", value: 123, timestamp: Date())
        
        // Encrypt data
        let encryptedData = try secureDataManager.encryptData(testData)
        
        // Verify encrypted data is different from original
        let originalJSON = try JSONEncoder().encode(testData)
        XCTAssertNotEqual(encryptedData, originalJSON)
        
        // Decrypt data
        let decryptedData = try secureDataManager.decryptData(encryptedData, as: TestSecureData.self)
        
        // Verify decrypted data matches original
        XCTAssertEqual(decryptedData.name, testData.name)
        XCTAssertEqual(decryptedData.value, testData.value)
    }
    
    func testEncryptionProducesUniqueResults() throws {
        let testData = TestSecureData(name: "Unique Test", value: 456, timestamp: Date())
        
        // Encrypt same data twice
        let encrypted1 = try secureDataManager.encryptData(testData)
        let encrypted2 = try secureDataManager.encryptData(testData)
        
        // Results should be different due to random nonce
        XCTAssertNotEqual(encrypted1, encrypted2)
        
        // But both should decrypt to same original data
        let decrypted1 = try secureDataManager.decryptData(encrypted1, as: TestSecureData.self)
        let decrypted2 = try secureDataManager.decryptData(encrypted2, as: TestSecureData.self)
        
        XCTAssertEqual(decrypted1.name, testData.name)
        XCTAssertEqual(decrypted2.name, testData.name)
        XCTAssertEqual(decrypted1.value, testData.value)
        XCTAssertEqual(decrypted2.value, testData.value)
    }
    
    // MARK: - Data Integrity Tests
    
    func testGenerateDataHash() throws {
        let testData = TestSecureData(name: "Hash Test", value: 789, timestamp: Date())
        
        let hash1 = try secureDataManager.generateDataHash(testData)
        let hash2 = try secureDataManager.generateDataHash(testData)
        
        // Same data should produce same hash
        XCTAssertEqual(hash1, hash2)
        XCTAssertFalse(hash1.isEmpty)
        
        // Different data should produce different hash
        let differentData = TestSecureData(name: "Different", value: 999, timestamp: Date())
        let differentHash = try secureDataManager.generateDataHash(differentData)
        
        XCTAssertNotEqual(hash1, differentHash)
    }
    
    func testValidateDataIntegrity() throws {
        let testData = TestSecureData(name: "Integrity Test", value: 101112, timestamp: Date())
        
        let hash = try secureDataManager.generateDataHash(testData)
        
        // Valid hash should pass validation
        XCTAssertTrue(secureDataManager.validateDataIntegrity(testData, expectedHash: hash))
        
        // Invalid hash should fail validation
        XCTAssertFalse(secureDataManager.validateDataIntegrity(testData, expectedHash: "invalid_hash"))
        
        // Modified data should fail validation with original hash
        let modifiedData = TestSecureData(name: "Modified", value: 101112, timestamp: Date())
        XCTAssertFalse(secureDataManager.validateDataIntegrity(modifiedData, expectedHash: hash))
    }
    
    // MARK: - Complex Data Tests
    
    func testStoreComplexPlayerData() throws {
        let playerData = createTestPlayerData()
        
        // Store complex player data
        try secureDataManager.storeSecureData(playerData, forKey: testKey)
        
        // Retrieve and verify
        let retrievedData: TestPlayerData? = try secureDataManager.retrieveSecureData(TestPlayerData.self, forKey: testKey)
        
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData?.id, playerData.id)
        XCTAssertEqual(retrievedData?.level, playerData.level)
        XCTAssertEqual(retrievedData?.experiencePoints, playerData.experiencePoints)
        XCTAssertEqual(retrievedData?.unlockedAirplanes, playerData.unlockedAirplanes)
        XCTAssertEqual(retrievedData?.gameResults.count, playerData.gameResults.count)
    }
    
    func testLargeDataStorage() throws {
        // Create large dataset
        var largeDataSet: [TestSecureData] = []
        for i in 0..<1000 {
            largeDataSet.append(TestSecureData(name: "Item \(i)", value: i, timestamp: Date()))
        }
        
        // Store large dataset
        try secureDataManager.storeSecureData(largeDataSet, forKey: testKey)
        
        // Retrieve and verify
        let retrievedData: [TestSecureData]? = try secureDataManager.retrieveSecureData([TestSecureData].self, forKey: testKey)
        
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData?.count, 1000)
        XCTAssertEqual(retrievedData?.first?.name, "Item 0")
        XCTAssertEqual(retrievedData?.last?.name, "Item 999")
    }
    
    // MARK: - Error Handling Tests
    
    func testDecryptInvalidData() {
        let invalidData = Data("invalid encrypted data".utf8)
        
        XCTAssertThrowsError(try secureDataManager.decryptData(invalidData, as: TestSecureData.self)) { error in
            // Should throw decryption error
            XCTAssertTrue(error is SecureDataError || error is CryptoKitError)
        }
    }
    
    func testDeleteNonExistentData() {
        // Should not throw error when deleting non-existent data
        XCTAssertNoThrow(try secureDataManager.deleteSecureData(forKey: "non_existent_key"))
    }
    
    // MARK: - Performance Tests
    
    func testEncryptionPerformance() throws {
        let testData = createTestPlayerData()
        
        measure {
            do {
                _ = try secureDataManager.encryptData(testData)
            } catch {
                XCTFail("Encryption failed: \(error)")
            }
        }
    }
    
    func testDecryptionPerformance() throws {
        let testData = createTestPlayerData()
        let encryptedData = try secureDataManager.encryptData(testData)
        
        measure {
            do {
                _ = try secureDataManager.decryptData(encryptedData, as: TestPlayerData.self)
            } catch {
                XCTFail("Decryption failed: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestPlayerData() -> TestPlayerData {
        let gameResults = [
            TestGameResult(score: 1000, distance: 500.0, timeElapsed: 60.0),
            TestGameResult(score: 1500, distance: 750.0, timeElapsed: 90.0),
            TestGameResult(score: 2000, distance: 1000.0, timeElapsed: 120.0)
        ]
        
        return TestPlayerData(
            id: UUID(),
            level: 5,
            experiencePoints: 450,
            totalScore: 4500,
            unlockedAirplanes: ["basic", "dart", "glider"],
            gameResults: gameResults
        )
    }
}

// MARK: - Test Data Structures

private struct TestSecureData: Codable, Equatable {
    let name: String
    let value: Int
    let timestamp: Date
}

private struct TestPlayerData: Codable {
    let id: UUID
    let level: Int
    let experiencePoints: Int
    let totalScore: Int
    let unlockedAirplanes: [String]
    let gameResults: [TestGameResult]
}

private struct TestGameResult: Codable {
    let score: Int
    let distance: Float
    let timeElapsed: TimeInterval
}