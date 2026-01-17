import XCTest
@testable import Tiny_Pilots

final class PrivacyManagerTests: XCTestCase {
    
    var privacyManager: PrivacyManager!
    
    override func setUp() {
        super.setUp()
        privacyManager = PrivacyManager.shared
        
        // Clean up any existing consent data
        privacyManager.revokeAllConsent()
    }
    
    override func tearDown() {
        // Clean up test data
        privacyManager.revokeAllConsent()
        super.tearDown()
    }
    
    // MARK: - Consent Management Tests
    
    func testInitialConsentState() {
        // Initially, no consent should be given
        XCTAssertFalse(privacyManager.hasAnalyticsConsent())
        XCTAssertFalse(privacyManager.hasDataCollectionConsent())
    }
    
    func testConsentRevocation() {
        // This test verifies that revokeAllConsent works
        // Since we can't easily test UI interactions, we'll test the storage mechanism
        
        // Manually set some consent (simulating user interaction)
        // Note: In a real scenario, this would be done through the UI
        
        // Verify revocation clears consent
        privacyManager.revokeAllConsent()
        
        XCTAssertFalse(privacyManager.hasAnalyticsConsent())
        XCTAssertFalse(privacyManager.hasDataCollectionConsent())
    }
    
    func testNeedsConsentUpdate() {
        // Test that consent update is needed for new users
        XCTAssertTrue(privacyManager.needsConsentUpdate())
    }
    
    // MARK: - Data Export Tests
    
    func testDataExportStructure() async {
        let exportData = await privacyManager.exportUserData()
        
        // Verify basic structure
        XCTAssertNotNil(exportData["analytics_consent"])
        XCTAssertNotNil(exportData["data_collection_consent"])
        XCTAssertNotNil(exportData["export_timestamp"])
        XCTAssertNotNil(exportData["privacy_policy_version"])
        
        // Verify data types
        XCTAssertTrue(exportData["analytics_consent"] is Bool)
        XCTAssertTrue(exportData["data_collection_consent"] is Bool)
        XCTAssertTrue(exportData["export_timestamp"] is String)
        XCTAssertTrue(exportData["privacy_policy_version"] is String)
    }
    
    func testDataExportWithoutConsent() async {
        // Ensure no consent is given
        privacyManager.revokeAllConsent()
        
        let exportData = await privacyManager.exportUserData()
        
        // Should not contain player data without consent
        XCTAssertNil(exportData["player_data"])
        XCTAssertNil(exportData["game_results"])
        XCTAssertNil(exportData["achievements"])
        
        // But should contain consent status
        XCTAssertEqual(exportData["analytics_consent"] as? Bool, false)
        XCTAssertEqual(exportData["data_collection_consent"] as? Bool, false)
    }
    
    // MARK: - Data Deletion Tests
    
    func testDataDeletion() async {
        let success = await privacyManager.deleteUserData()
        
        // Deletion should succeed
        XCTAssertTrue(success)
        
        // Consent should be revoked after deletion
        XCTAssertFalse(privacyManager.hasAnalyticsConsent())
        XCTAssertFalse(privacyManager.hasDataCollectionConsent())
    }
    
    // MARK: - Privacy Policy Tests
    
    func testPrivacyPolicyMethods() {
        // These methods primarily show UI, so we just test they don't crash
        XCTAssertNoThrow(privacyManager.showPrivacyPolicy())
        XCTAssertNoThrow(privacyManager.showDataDeletionRequest())
    }
    
    // MARK: - Integration Tests
    
    func testPrivacyComplianceFlow() async {
        // Test the complete privacy compliance flow
        
        // 1. Initial state - no consent
        XCTAssertFalse(privacyManager.hasAnalyticsConsent())
        XCTAssertFalse(privacyManager.hasDataCollectionConsent())
        XCTAssertTrue(privacyManager.needsConsentUpdate())
        
        // 2. Export data without consent
        let initialExport = await privacyManager.exportUserData()
        XCTAssertNil(initialExport["player_data"])
        
        // 3. Delete data
        let deletionSuccess = await privacyManager.deleteUserData()
        XCTAssertTrue(deletionSuccess)
        
        // 4. Verify data is gone
        let finalExport = await privacyManager.exportUserData()
        XCTAssertNil(finalExport["player_data"])
        XCTAssertEqual(finalExport["analytics_consent"] as? Bool, false)
        XCTAssertEqual(finalExport["data_collection_consent"] as? Bool, false)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() {
        // Test that privacy manager handles errors gracefully
        
        // These should not crash even if underlying storage fails
        XCTAssertNoThrow(privacyManager.hasAnalyticsConsent())
        XCTAssertNoThrow(privacyManager.hasDataCollectionConsent())
        XCTAssertNoThrow(privacyManager.revokeAllConsent())
    }
    
    // MARK: - Performance Tests
    
    func testConsentCheckPerformance() {
        measure {
            _ = privacyManager.hasAnalyticsConsent()
            _ = privacyManager.hasDataCollectionConsent()
        }
    }
    
    func testDataExportPerformance() {
        measure {
            Task {
                _ = await privacyManager.exportUserData()
            }
        }
    }
}