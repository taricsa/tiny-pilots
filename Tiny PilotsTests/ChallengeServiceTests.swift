import XCTest
import GameKit
@testable import Tiny_Pilots

class ChallengeServiceTests: XCTestCase {
    
    var challengeService: ChallengeService!
    var mockGameCenterService: MockGameCenterService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockGameCenterService = MockGameCenterService()
        challengeService = ChallengeService(gameCenterService: mockGameCenterService)
    }
    
    override func tearDownWithError() throws {
        challengeService = nil
        mockGameCenterService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Challenge Creation Tests
    
    func testCreateChallenge() {
        // Given
        let title = "Test Challenge"
        let description = "A test challenge"
        let courseData = ChallengeData(
            environmentType: "sunny_meadows",
            obstacles: [ObstacleConfiguration(type: "tree", position: CGPoint(x: 100, y: 200))],
            difficulty: .medium
        )
        let createdBy = "Test Player"
        let targetScore = 1000
        
        // When
        let challenge = challengeService.createChallenge(
            title: title,
            description: description,
            courseData: courseData,
            createdBy: createdBy,
            targetScore: targetScore
        )
        
        // Then
        XCTAssertEqual(challenge.title, title)
        XCTAssertEqual(challenge.description, description)
        XCTAssertEqual(challenge.courseData.environmentType, courseData.environmentType)
        XCTAssertEqual(challenge.createdBy, createdBy)
        XCTAssertEqual(challenge.targetScore, targetScore)
        XCTAssertTrue(challenge.isValid)
        XCTAssertFalse(challenge.id.isEmpty)
    }
    
    // MARK: - Challenge Code Generation Tests
    
    func testGenerateChallengeCode() {
        // Given
        let challenge = createSampleChallenge()
        mockGameCenterService.mockChallengeCode = "test_challenge_code_1234"
        
        // When
        let challengeCode = challengeService.generateChallengeCode(for: challenge)
        
        // Then
        XCTAssertEqual(challengeCode, "test_challenge_code_1234")
        XCTAssertTrue(mockGameCenterService.generateChallengeCodeCalled)
    }
    
    // MARK: - Challenge Code Validation Tests
    
    func testValidateChallengeCodeSuccess() async throws {
        // Given
        let validCode = "valid_code_123"
        mockGameCenterService.mockValidationResult = .success("encoded_course_data")
        
        // When
        let isValid = try await challengeService.validateChallengeCode(validCode)
        
        // Then
        XCTAssertTrue(isValid)
        XCTAssertTrue(mockGameCenterService.validateChallengeCodeCalled)
    }
    
    func testValidateChallengeCodeInvalidFormat() async {
        // Given
        let invalidCode = ""
        
        // When/Then
        do {
            _ = try await challengeService.validateChallengeCode(invalidCode)
            XCTFail("Should have thrown an error")
        } catch ChallengeError.invalidCode {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testValidateChallengeCodeExpired() async {
        // Given
        let expiredCode = "expired_code_123"
        mockGameCenterService.mockValidationResult = .failure(GameCenterServiceError.challengeExpired)
        
        // When/Then
        do {
            _ = try await challengeService.validateChallengeCode(expiredCode)
            XCTFail("Should have thrown an error")
        } catch ChallengeError.expired {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Challenge Loading Tests
    
    func testLoadChallengeSuccess() async throws {
        // Given
        let challengeCode = "valid_code_123"
        let encodedCourseData = createSampleChallengeData().encoded
        mockGameCenterService.mockValidationResult = .success(encodedCourseData)
        
        // When
        let challenge = try await challengeService.loadChallenge(code: challengeCode)
        
        // Then
        XCTAssertEqual(challenge.title, "Friend Challenge")
        XCTAssertEqual(challenge.description, "A challenge shared by a friend")
        XCTAssertEqual(challenge.createdBy, "Friend")
        XCTAssertTrue(challenge.isValid)
        XCTAssertTrue(mockGameCenterService.validateChallengeCodeCalled)
    }
    
    func testLoadChallengeInvalidCode() async {
        // Given
        let invalidCode = "invalid_code"
        mockGameCenterService.mockValidationResult = .failure(GameCenterServiceError.invalidChallengeCode)
        
        // When/Then
        do {
            _ = try await challengeService.loadChallenge(code: invalidCode)
            XCTFail("Should have thrown an error")
        } catch ChallengeError.invalidCode {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testLoadChallengeDecodingError() async {
        // Given
        let challengeCode = "valid_code_123"
        mockGameCenterService.mockValidationResult = .success("invalid_encoded_data")
        
        // When/Then
        do {
            _ = try await challengeService.loadChallenge(code: challengeCode)
            XCTFail("Should have thrown an error")
        } catch ChallengeError.decodingError {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Local Storage Tests
    
    func testSaveAndLoadChallenge() throws {
        // Given
        let challenge = createSampleChallenge()
        
        // When
        try challengeService.saveChallenge(challenge)
        let savedChallenges = challengeService.loadSavedChallenges()
        
        // Then
        XCTAssertEqual(savedChallenges.count, 1)
        XCTAssertEqual(savedChallenges.first?.id, challenge.id)
        XCTAssertEqual(savedChallenges.first?.title, challenge.title)
    }
    
    func testSaveMultipleChallenges() throws {
        // Given
        let challenge1 = createSampleChallenge(title: "Challenge 1")
        let challenge2 = createSampleChallenge(title: "Challenge 2")
        
        // When
        try challengeService.saveChallenge(challenge1)
        try challengeService.saveChallenge(challenge2)
        let savedChallenges = challengeService.loadSavedChallenges()
        
        // Then
        XCTAssertEqual(savedChallenges.count, 2)
        XCTAssertTrue(savedChallenges.contains { $0.id == challenge1.id })
        XCTAssertTrue(savedChallenges.contains { $0.id == challenge2.id })
    }
    
    func testDeleteSavedChallenge() throws {
        // Given
        let challenge = createSampleChallenge()
        try challengeService.saveChallenge(challenge)
        
        // When
        try challengeService.deleteSavedChallenge(challengeID: challenge.id)
        let savedChallenges = challengeService.loadSavedChallenges()
        
        // Then
        XCTAssertEqual(savedChallenges.count, 0)
    }
    
    func testDeleteNonExistentChallenge() {
        // Given
        let nonExistentID = "non_existent_id"
        
        // When/Then
        XCTAssertThrowsError(try challengeService.deleteSavedChallenge(challengeID: nonExistentID)) { error in
            XCTAssertTrue(error is ChallengeError)
            if case ChallengeError.notFound = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testLoadSavedChallengesFiltersExpired() throws {
        // Given - Create an expired challenge
        let expiredChallenge = Challenge(
            title: "Expired Challenge",
            description: "This challenge is expired",
            courseData: createSampleChallengeData(),
            expirationDate: Date().addingTimeInterval(-24 * 60 * 60), // 1 day ago
            createdBy: "Test Player"
        )
        
        let validChallenge = createSampleChallenge()
        
        // When
        try challengeService.saveChallenge(expiredChallenge)
        try challengeService.saveChallenge(validChallenge)
        let savedChallenges = challengeService.loadSavedChallenges()
        
        // Then
        XCTAssertEqual(savedChallenges.count, 1)
        XCTAssertEqual(savedChallenges.first?.id, validChallenge.id)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleChallenge(title: String = "Test Challenge") -> Challenge {
        return Challenge(
            title: title,
            description: "A test challenge",
            courseData: createSampleChallengeData(),
            createdBy: "Test Player"
        )
    }
    
    private func createSampleChallengeData() -> ChallengeData {
        return ChallengeData(
            environmentType: "sunny_meadows",
            obstacles: [
                ObstacleConfiguration(type: "tree", position: CGPoint(x: 100, y: 200)),
                ObstacleConfiguration(type: "building", position: CGPoint(x: 300, y: 150))
            ],
            collectibles: [
                CollectibleConfiguration(type: "star", position: CGPoint(x: 200, y: 100), value: 50)
            ],
            weatherConditions: WeatherConfiguration(windSpeed: 0.3, windDirection: 45),
            difficulty: .medium
        )
    }
}

// MARK: - Mock Game Center Service

class MockGameCenterService: GameCenterServiceProtocol {
    var isAuthenticated: Bool = true
    var playerDisplayName: String? = "Test Player"
    
    var generateChallengeCodeCalled = false
    var validateChallengeCodeCalled = false
    var mockChallengeCode = "mock_challenge_code"
    var mockValidationResult: Result<String, Error> = .success("mock_course_data")
    
    func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }
    
    func submitScore(_ score: Int, to leaderboardID: String, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }
    
    func loadLeaderboard(for leaderboardID: String, completion: @escaping ([GameCenterLeaderboardEntry]?, Error?) -> Void) {
        completion([], nil)
    }
    
    func reportAchievement(identifier: String, percentComplete: Double, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }
    
    func loadAchievements(completion: @escaping ([GKAchievement]?, Error?) -> Void) {
        completion([], nil)
    }
    
    func showLeaderboards(from presentingViewController: UIViewController) {
        // Mock implementation
    }
    
    func showAchievements(from presentingViewController: UIViewController) {
        // Mock implementation
    }
    
    func generateChallengeCode(for courseData: String) -> String {
        generateChallengeCodeCalled = true
        return mockChallengeCode
    }
    
    func validateChallengeCode(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        validateChallengeCodeCalled = true
        completion(mockValidationResult)
    }
}