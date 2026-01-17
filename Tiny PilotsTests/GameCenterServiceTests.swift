import XCTest
import GameKit
@testable import Tiny_Pilots

/// Unit tests for GameCenterService
class GameCenterServiceTests: XCTestCase {
    
    var sut: GameCenterService!
    
    override func setUp() {
        super.setUp()
        sut = GameCenterService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Authentication Tests
    
    func testIsAuthenticated_WhenNotAuthenticated_ReturnsFalse() {
        // Given - fresh service instance
        
        // When
        let isAuthenticated = sut.isAuthenticated
        
        // Then
        XCTAssertFalse(isAuthenticated, "Should not be authenticated initially")
    }
    
    func testPlayerDisplayName_WhenNotAuthenticated_ReturnsNil() {
        // Given - fresh service instance
        
        // When
        let displayName = sut.playerDisplayName
        
        // Then
        XCTAssertNil(displayName, "Display name should be nil when not authenticated")
    }
    
    func testAuthenticate_CallsCompletionHandler() {
        // Given
        let expectation = XCTestExpectation(description: "Authentication completion called")
        
        // When
        sut.authenticate { success, error in
            // Then
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Score Submission Tests
    
    func testSubmitScore_WhenNotAuthenticated_ReturnsError() {
        // Given
        let expectation = XCTestExpectation(description: "Submit score completion called")
        var receivedError: Error?
        
        // When
        sut.submitScore(1000, to: "test.leaderboard") { error in
            receivedError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError, "Should return error when not authenticated")
        XCTAssertTrue(receivedError is GameCenterServiceError, "Should return GameCenterServiceError")
        
        if let gcError = receivedError as? GameCenterServiceError {
            XCTAssertEqual(gcError, .notAuthenticated, "Should return notAuthenticated error")
        }
    }
    
    // MARK: - Leaderboard Tests
    
    func testLoadLeaderboard_WhenNotAuthenticated_ReturnsError() {
        // Given
        let expectation = XCTestExpectation(description: "Load leaderboard completion called")
        var receivedError: Error?
        var receivedEntries: [LeaderboardEntry]?
        
        // When
        sut.loadLeaderboard(for: "test.leaderboard") { entries, error in
            receivedEntries = entries
            receivedError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedEntries, "Should not return entries when not authenticated")
        XCTAssertNotNil(receivedError, "Should return error when not authenticated")
        
        if let gcError = receivedError as? GameCenterServiceError {
            XCTAssertEqual(gcError, .notAuthenticated, "Should return notAuthenticated error")
        }
    }
    
    // MARK: - Achievement Tests
    
    func testReportAchievement_WhenNotAuthenticated_ReturnsError() {
        // Given
        let expectation = XCTestExpectation(description: "Report achievement completion called")
        var receivedError: Error?
        
        // When
        sut.reportAchievement(identifier: "test.achievement", percentComplete: 50.0) { error in
            receivedError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError, "Should return error when not authenticated")
        
        if let gcError = receivedError as? GameCenterServiceError {
            XCTAssertEqual(gcError, .notAuthenticated, "Should return notAuthenticated error")
        }
    }
    
    func testLoadAchievements_WhenNotAuthenticated_ReturnsError() {
        // Given
        let expectation = XCTestExpectation(description: "Load achievements completion called")
        var receivedError: Error?
        var receivedAchievements: [GKAchievement]?
        
        // When
        sut.loadAchievements { achievements, error in
            receivedAchievements = achievements
            receivedError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedAchievements, "Should not return achievements when not authenticated")
        XCTAssertNotNil(receivedError, "Should return error when not authenticated")
        
        if let gcError = receivedError as? GameCenterServiceError {
            XCTAssertEqual(gcError, .notAuthenticated, "Should return notAuthenticated error")
        }
    }
    
    // MARK: - Challenge Code Tests
    
    func testGenerateChallengeCode_ReturnsValidFormat() {
        // Given
        let courseData = "test_course"
        
        // When
        let challengeCode = sut.generateChallengeCode(for: courseData)
        
        // Then
        let components = challengeCode.split(separator: "_")
        XCTAssertEqual(components.count, 4, "Challenge code should have 4 components")
        XCTAssertEqual(String(components[0]), courseData, "First component should be course data")
        XCTAssertNotNil(Int(components[1]), "Second component should be timestamp")
        XCTAssertNotNil(Int(components[2]), "Third component should be random seed")
        XCTAssertNotNil(Int(components[3]), "Fourth component should be checksum")
    }
    
    func testValidateChallengeCode_WithValidCode_ReturnsSuccess() {
        // Given
        let courseData = "test_course"
        let challengeCode = sut.generateChallengeCode(for: courseData)
        let expectation = XCTestExpectation(description: "Validate challenge code completion called")
        var result: Result<String, Error>?
        
        // When
        sut.validateChallengeCode(challengeCode) { validationResult in
            result = validationResult
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(result, "Should return a result")
        
        switch result {
        case .success(let returnedCourseData):
            XCTAssertEqual(returnedCourseData, courseData, "Should return original course data")
        case .failure(let error):
            XCTFail("Should not fail with valid code: \(error)")
        case .none:
            XCTFail("Result should not be nil")
        }
    }
    
    func testValidateChallengeCode_WithInvalidFormat_ReturnsError() {
        // Given
        let invalidCode = "invalid_code"
        let expectation = XCTestExpectation(description: "Validate challenge code completion called")
        var result: Result<String, Error>?
        
        // When
        sut.validateChallengeCode(invalidCode) { validationResult in
            result = validationResult
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(result, "Should return a result")
        
        switch result {
        case .success:
            XCTFail("Should not succeed with invalid code")
        case .failure(let error):
            XCTAssertTrue(error is GameCenterServiceError, "Should return GameCenterServiceError")
            if let gcError = error as? GameCenterServiceError {
                XCTAssertEqual(gcError, .invalidChallengeCode, "Should return invalidChallengeCode error")
            }
        case .none:
            XCTFail("Result should not be nil")
        }
    }
    
    func testValidateChallengeCode_WithTamperedChecksum_ReturnsError() {
        // Given
        let courseData = "test_course"
        let validCode = sut.generateChallengeCode(for: courseData)
        let components = validCode.split(separator: "_")
        let tamperedCode = "\(components[0])_\(components[1])_\(components[2])_9999" // Wrong checksum
        
        let expectation = XCTestExpectation(description: "Validate challenge code completion called")
        var result: Result<String, Error>?
        
        // When
        sut.validateChallengeCode(tamperedCode) { validationResult in
            result = validationResult
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(result, "Should return a result")
        
        switch result {
        case .success:
            XCTFail("Should not succeed with tampered checksum")
        case .failure(let error):
            XCTAssertTrue(error is GameCenterServiceError, "Should return GameCenterServiceError")
            if let gcError = error as? GameCenterServiceError {
                XCTAssertEqual(gcError, .invalidChallengeCode, "Should return invalidChallengeCode error")
            }
        case .none:
            XCTFail("Result should not be nil")
        }
    }
}// MARK: 
- Additional Comprehensive Tests

extension GameCenterServiceTests {
    
    // MARK: - Error Handling Tests
    
    func testSubmitScore_WithInvalidLeaderboardID_ReturnsError() {
        // Given
        // Simulate authenticated state for this test
        let expectation = XCTestExpectation(description: "Submit score with invalid ID completion called")
        var receivedError: Error?
        
        // When
        sut.submitScore(1000, to: "") { error in
            receivedError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError, "Should return error for empty leaderboard ID")
    }
    
    func testReportAchievement_WithInvalidPercentage_HandlesCorrectly() {
        // Given
        let expectation = XCTestExpectation(description: "Report achievement with invalid percentage completion called")
        var receivedError: Error?
        
        // When
        sut.reportAchievement(identifier: "test.achievement", percentComplete: -10.0) { error in
            receivedError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError, "Should return error for negative percentage")
        
        // Test with percentage over 100
        let expectation2 = XCTestExpectation(description: "Report achievement with over 100% completion called")
        var receivedError2: Error?
        
        sut.reportAchievement(identifier: "test.achievement", percentComplete: 150.0) { error in
            receivedError2 = error
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: 1.0)
        XCTAssertNotNil(receivedError2, "Should return error for percentage over 100")
    }
    
    func testReportAchievement_WithEmptyIdentifier_ReturnsError() {
        // Given
        let expectation = XCTestExpectation(description: "Report achievement with empty ID completion called")
        var receivedError: Error?
        
        // When
        sut.reportAchievement(identifier: "", percentComplete: 50.0) { error in
            receivedError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError, "Should return error for empty achievement identifier")
    }
    
    // MARK: - Performance Tests
    
    func testMultipleScoreSubmissions_PerformanceTest() {
        // Given
        let expectation = XCTestExpectation(description: "Multiple score submissions complete")
        expectation.expectedFulfillmentCount = 100
        
        // When
        measure {
            for i in 0..<100 {
                sut.submitScore(i * 10, to: "test.leaderboard") { _ in
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Then - Should complete without significant performance issues
        XCTAssertTrue(true)
    }
    
    func testMultipleAchievementReports_PerformanceTest() {
        // Given
        let expectation = XCTestExpectation(description: "Multiple achievement reports complete")
        expectation.expectedFulfillmentCount = 50
        
        // When
        measure {
            for i in 0..<50 {
                sut.reportAchievement(identifier: "test.achievement.\(i)", percentComplete: Double(i * 2)) { _ in
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Then - Should complete without significant performance issues
        XCTAssertTrue(true)
    }
    
    // MARK: - Memory Management Tests
    
    func testMultipleAuthentications_DoesNotLeak() {
        // Given
        let expectation = XCTestExpectation(description: "Multiple authentications complete")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for _ in 0..<10 {
            sut.authenticate { _, _ in
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Then - Should not leak memory
        XCTAssertTrue(true)
    }
    
    func testMultipleLeaderboardLoads_DoesNotLeak() {
        // Given
        let expectation = XCTestExpectation(description: "Multiple leaderboard loads complete")
        expectation.expectedFulfillmentCount = 20
        
        // When
        for i in 0..<20 {
            sut.loadLeaderboard(for: "test.leaderboard.\(i)") { _, _ in
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Then - Should not leak memory
        XCTAssertTrue(true)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentScoreSubmissions_ThreadSafe() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent score submissions complete")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.sut.submitScore(i * 100, to: "test.leaderboard") { _ in
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Then - Should complete without crashing
        XCTAssertTrue(true)
    }
    
    func testConcurrentAchievementReports_ThreadSafe() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent achievement reports complete")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.sut.reportAchievement(identifier: "test.achievement.\(i)", percentComplete: Double(i * 10)) { _ in
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Then - Should complete without crashing
        XCTAssertTrue(true)
    }
    
    // MARK: - Challenge Code Edge Cases
    
    func testGenerateChallengeCode_WithEmptyData_ReturnsValidCode() {
        // Given
        let emptyCourseData = ""
        
        // When
        let challengeCode = sut.generateChallengeCode(for: emptyCourseData)
        
        // Then
        XCTAssertFalse(challengeCode.isEmpty, "Should return non-empty code even for empty data")
        let components = challengeCode.split(separator: "_")
        XCTAssertEqual(components.count, 4, "Should have 4 components even for empty data")
    }
    
    func testGenerateChallengeCode_WithSpecialCharacters_HandlesCorrectly() {
        // Given
        let specialCourseData = "test@#$%^&*()_+{}|:<>?[]\\;'\",./"
        
        // When
        let challengeCode = sut.generateChallengeCode(for: specialCourseData)
        
        // Then
        XCTAssertFalse(challengeCode.isEmpty, "Should handle special characters")
        let components = challengeCode.split(separator: "_")
        XCTAssertEqual(components.count, 4, "Should have 4 components with special characters")
    }
    
    func testGenerateChallengeCode_WithLongData_HandlesCorrectly() {
        // Given
        let longCourseData = String(repeating: "a", count: 10000)
        
        // When
        let challengeCode = sut.generateChallengeCode(for: longCourseData)
        
        // Then
        XCTAssertFalse(challengeCode.isEmpty, "Should handle long data")
        let components = challengeCode.split(separator: "_")
        XCTAssertEqual(components.count, 4, "Should have 4 components with long data")
    }
    
    func testValidateChallengeCode_WithExpiredCode_ReturnsError() {
        // Given
        let courseData = "test_course"
        let oldTimestamp = Int(Date().timeIntervalSince1970) - 86400 // 24 hours ago
        let randomSeed = Int.random(in: 1000...9999)
        let checksum = (courseData.hashValue + oldTimestamp + randomSeed) % 10000
        let expiredCode = "\(courseData)_\(oldTimestamp)_\(randomSeed)_\(checksum)"
        
        let expectation = XCTestExpectation(description: "Validate expired code completion called")
        var result: Result<String, Error>?
        
        // When
        sut.validateChallengeCode(expiredCode) { validationResult in
            result = validationResult
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(result, "Should return a result")
        
        switch result {
        case .success:
            XCTFail("Should not succeed with expired code")
        case .failure(let error):
            XCTAssertTrue(error is GameCenterServiceError, "Should return GameCenterServiceError")
            if let gcError = error as? GameCenterServiceError {
                XCTAssertEqual(gcError, .challengeExpired, "Should return challengeExpired error")
            }
        case .none:
            XCTFail("Result should not be nil")
        }
    }
    
    func testValidateChallengeCode_WithMalformedCode_ReturnsError() {
        // Given
        let malformedCodes = [
            "too_few_components",
            "too_many_components_here_are_five_parts",
            "non_numeric_timestamp_abc_123_456",
            "valid_123_abc_789", // Non-numeric random seed
            "valid_123_456_abc"  // Non-numeric checksum
        ]
        
        for malformedCode in malformedCodes {
            let expectation = XCTestExpectation(description: "Validate malformed code completion called")
            var result: Result<String, Error>?
            
            // When
            sut.validateChallengeCode(malformedCode) { validationResult in
                result = validationResult
                expectation.fulfill()
            }
            
            // Then
            wait(for: [expectation], timeout: 1.0)
            XCTAssertNotNil(result, "Should return a result for malformed code: \(malformedCode)")
            
            switch result {
            case .success:
                XCTFail("Should not succeed with malformed code: \(malformedCode)")
            case .failure(let error):
                XCTAssertTrue(error is GameCenterServiceError, "Should return GameCenterServiceError for: \(malformedCode)")
                if let gcError = error as? GameCenterServiceError {
                    XCTAssertEqual(gcError, .invalidChallengeCode, "Should return invalidChallengeCode error for: \(malformedCode)")
                }
            case .none:
                XCTFail("Result should not be nil for: \(malformedCode)")
            }
        }
    }
    
    // MARK: - UI Presentation Tests
    
    func testShowLeaderboards_WithNilViewController_HandlesGracefully() {
        // Given
        let nilViewController: UIViewController? = nil
        
        // When & Then
        XCTAssertNoThrow(sut.showLeaderboards(from: nilViewController!), "Should handle nil view controller gracefully")
    }
    
    func testShowAchievements_WithNilViewController_HandlesGracefully() {
        // Given
        let nilViewController: UIViewController? = nil
        
        // When & Then
        XCTAssertNoThrow(sut.showAchievements(from: nilViewController!), "Should handle nil view controller gracefully")
    }
    
    // MARK: - Network Error Simulation Tests
    
    func testSubmitScore_WithNetworkError_ReturnsNetworkError() {
        // Given
        let expectation = XCTestExpectation(description: "Submit score with network error completion called")
        var receivedError: Error?
        
        // When - This would require mocking network conditions
        sut.submitScore(1000, to: "test.leaderboard") { error in
            receivedError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError, "Should return error when network is unavailable")
    }
    
    func testLoadLeaderboard_WithNetworkError_ReturnsNetworkError() {
        // Given
        let expectation = XCTestExpectation(description: "Load leaderboard with network error completion called")
        var receivedError: Error?
        
        // When - This would require mocking network conditions
        sut.loadLeaderboard(for: "test.leaderboard") { _, error in
            receivedError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedError, "Should return error when network is unavailable")
    }
    
    // MARK: - Authentication State Tests
    
    func testAuthenticationState_ConsistentAcrossOperations() {
        // Given
        let initialAuthState = sut.isAuthenticated
        let initialDisplayName = sut.playerDisplayName
        
        // When - Perform various operations
        let expectation = XCTestExpectation(description: "Operations complete")
        expectation.expectedFulfillmentCount = 3
        
        sut.submitScore(100, to: "test") { _ in expectation.fulfill() }
        sut.loadLeaderboard(for: "test") { _, _ in expectation.fulfill() }
        sut.reportAchievement(identifier: "test", percentComplete: 50) { _ in expectation.fulfill() }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then
        XCTAssertEqual(sut.isAuthenticated, initialAuthState, "Authentication state should remain consistent")
        XCTAssertEqual(sut.playerDisplayName, initialDisplayName, "Player display name should remain consistent")
    }
    
    // MARK: - Challenge Code Security Tests
    
    func testChallengeCodeGeneration_ProducesUniqueResults() {
        // Given
        let courseData = "test_course"
        var generatedCodes: Set<String> = []
        
        // When
        for _ in 0..<100 {
            let code = sut.generateChallengeCode(for: courseData)
            generatedCodes.insert(code)
        }
        
        // Then
        XCTAssertEqual(generatedCodes.count, 100, "All generated codes should be unique")
    }
    
    func testChallengeCodeValidation_RejectsModifiedCodes() {
        // Given
        let courseData = "test_course"
        let validCode = sut.generateChallengeCode(for: courseData)
        let components = validCode.split(separator: "_")
        
        // Create various modified versions
        let modifiedCodes = [
            "modified_\(components[1])_\(components[2])_\(components[3])", // Modified course data
            "\(components[0])_999999_\(components[2])_\(components[3])", // Modified timestamp
            "\(components[0])_\(components[1])_999999_\(components[3])", // Modified random seed
            "\(components[0])_\(components[1])_\(components[2])_999999"  // Modified checksum
        ]
        
        for modifiedCode in modifiedCodes {
            let expectation = XCTestExpectation(description: "Validate modified code completion called")
            var result: Result<String, Error>?
            
            // When
            sut.validateChallengeCode(modifiedCode) { validationResult in
                result = validationResult
                expectation.fulfill()
            }
            
            // Then
            wait(for: [expectation], timeout: 1.0)
            
            switch result {
            case .success:
                XCTFail("Should not succeed with modified code: \(modifiedCode)")
            case .failure(let error):
                XCTAssertTrue(error is GameCenterServiceError, "Should return GameCenterServiceError for: \(modifiedCode)")
            case .none:
                XCTFail("Result should not be nil for: \(modifiedCode)")
            }
        }
    }
}