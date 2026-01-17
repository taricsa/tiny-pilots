import XCTest
@testable import Tiny_Pilots

class WeeklySpecialServiceTests: XCTestCase {
    
    var weeklySpecialService: WeeklySpecialService!
    var mockGameCenterService: MockGameCenterService!
    var mockNetworkService: MockNetworkService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockGameCenterService = MockGameCenterService()
        mockNetworkService = MockNetworkService()
        weeklySpecialService = WeeklySpecialService(
            gameCenterService: mockGameCenterService,
            networkService: mockNetworkService
        )
    }
    
    override func tearDownWithError() throws {
        weeklySpecialService = nil
        mockGameCenterService = nil
        mockNetworkService = nil
        
        // Clear UserDefaults
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "CachedWeeklySpecials")
        userDefaults.removeObject(forKey: "WeeklySpecialParticipation")
        userDefaults.removeObject(forKey: "WeeklySpecialBestScores")
        
        try super.tearDownWithError()
    }
    
    // MARK: - Loading Weekly Specials Tests
    
    func testLoadWeeklySpecials_Success() async throws {
        // Given
        let expectedSpecials = [WeeklySpecial.sample()]
        
        // When
        let result = try await weeklySpecialService.loadWeeklySpecials(forceRefresh: false)
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, expectedSpecials.first?.title)
        XCTAssertTrue(result.first?.isActive ?? false)
    }
    
    func testLoadWeeklySpecials_CacheHit() async throws {
        // Given - Load specials first time to populate cache
        _ = try await weeklySpecialService.loadWeeklySpecials(forceRefresh: false)
        
        // When - Load again without force refresh
        let result = try await weeklySpecialService.loadWeeklySpecials(forceRefresh: false)
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Sky High Challenge")
    }
    
    func testLoadWeeklySpecials_ForceRefresh() async throws {
        // Given - Load specials first time to populate cache
        _ = try await weeklySpecialService.loadWeeklySpecials(forceRefresh: false)
        
        // When - Force refresh
        let result = try await weeklySpecialService.loadWeeklySpecials(forceRefresh: true)
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Sky High Challenge")
    }
    
    func testLoadWeeklySpecials_FilterActiveOnly() async throws {
        // Given - This test assumes the sample data is active
        
        // When
        let result = try await weeklySpecialService.loadWeeklySpecials(forceRefresh: false)
        
        // Then
        XCTAssertTrue(result.allSatisfy { $0.isActive })
    }
    
    // MARK: - Get Weekly Special Tests
    
    func testGetWeeklySpecial_Success() async throws {
        // Given
        let sampleSpecial = WeeklySpecial.sample()
        
        // When
        let result = try await weeklySpecialService.getWeeklySpecial(id: sampleSpecial.id)
        
        // Then
        XCTAssertEqual(result.id, sampleSpecial.id)
        XCTAssertEqual(result.title, sampleSpecial.title)
    }
    
    func testGetWeeklySpecial_NotFound() async {
        // Given
        let nonExistentId = "non-existent-id"
        
        // When & Then
        do {
            _ = try await weeklySpecialService.getWeeklySpecial(id: nonExistentId)
            XCTFail("Expected WeeklySpecialError.notFound")
        } catch WeeklySpecialError.notFound {
            // Expected
        } catch {
            XCTFail("Expected WeeklySpecialError.notFound, got \(error)")
        }
    }
    
    // MARK: - Score Submission Tests
    
    func testSubmitScore_Success() async throws {
        // Given
        let sampleSpecial = WeeklySpecial.sample()
        let score = 1500
        let gameData = ["distance": 1500, "time": 120.5]
        
        // When
        try await weeklySpecialService.submitScore(
            score: score,
            weeklySpecialId: sampleSpecial.id,
            gameData: gameData
        )
        
        // Then
        XCTAssertTrue(weeklySpecialService.hasParticipated(in: sampleSpecial.id))
        XCTAssertEqual(weeklySpecialService.getPlayerBestScore(for: sampleSpecial.id), score)
    }
    
    func testSubmitScore_InvalidScore() async {
        // Given
        let sampleSpecial = WeeklySpecial.sample()
        let invalidScore = 0
        let gameData = ["distance": 0]
        
        // When & Then
        do {
            try await weeklySpecialService.submitScore(
                score: invalidScore,
                weeklySpecialId: sampleSpecial.id,
                gameData: gameData
            )
            XCTFail("Expected WeeklySpecialError.validationError")
        } catch WeeklySpecialError.validationError {
            // Expected
        } catch {
            XCTFail("Expected WeeklySpecialError.validationError, got \(error)")
        }
    }
    
    func testSubmitScore_UpdatesBestScore() async throws {
        // Given
        let sampleSpecial = WeeklySpecial.sample()
        let initialScore = 1000
        let betterScore = 1500
        let gameData = ["distance": 1500]
        
        // When - Submit initial score
        try await weeklySpecialService.submitScore(
            score: initialScore,
            weeklySpecialId: sampleSpecial.id,
            gameData: gameData
        )
        
        // Then - Check initial score
        XCTAssertEqual(weeklySpecialService.getPlayerBestScore(for: sampleSpecial.id), initialScore)
        
        // When - Submit better score
        try await weeklySpecialService.submitScore(
            score: betterScore,
            weeklySpecialId: sampleSpecial.id,
            gameData: gameData
        )
        
        // Then - Check updated score
        XCTAssertEqual(weeklySpecialService.getPlayerBestScore(for: sampleSpecial.id), betterScore)
    }
    
    func testSubmitScore_DoesNotUpdateWithWorseScore() async throws {
        // Given
        let sampleSpecial = WeeklySpecial.sample()
        let betterScore = 1500
        let worseScore = 1000
        let gameData = ["distance": 1000]
        
        // When - Submit better score first
        try await weeklySpecialService.submitScore(
            score: betterScore,
            weeklySpecialId: sampleSpecial.id,
            gameData: gameData
        )
        
        // Then - Check initial score
        XCTAssertEqual(weeklySpecialService.getPlayerBestScore(for: sampleSpecial.id), betterScore)
        
        // When - Submit worse score
        try await weeklySpecialService.submitScore(
            score: worseScore,
            weeklySpecialId: sampleSpecial.id,
            gameData: gameData
        )
        
        // Then - Check score remains the same
        XCTAssertEqual(weeklySpecialService.getPlayerBestScore(for: sampleSpecial.id), betterScore)
    }
    
    // MARK: - Leaderboard Tests
    
    func testLoadLeaderboard_Success() async throws {
        // Given
        let sampleSpecial = WeeklySpecial.sample()
        
        // When
        let result = try await weeklySpecialService.loadLeaderboard(weeklySpecialId: sampleSpecial.id)
        
        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.first?.displayName, "SkyMaster")
        XCTAssertEqual(result.first?.score, 1850)
        XCTAssertEqual(result.first?.rank, 1)
    }
    
    // MARK: - Share Code Tests
    
    func testGenerateShareCode_Success() {
        // Given
        let sampleSpecial = WeeklySpecial.sample()
        
        // When
        let shareCode = weeklySpecialService.generateShareCode(for: sampleSpecial)
        
        // Then
        XCTAssertTrue(shareCode.hasPrefix("WS_"))
        XCTAssertTrue(shareCode.contains(sampleSpecial.id))
        
        let components = shareCode.split(separator: "_")
        XCTAssertEqual(components.count, 5) // WS_id_timestamp_random_checksum
    }
    
    func testLoadFromShareCode_Success() async throws {
        // Given
        let sampleSpecial = WeeklySpecial.sample()
        let shareCode = weeklySpecialService.generateShareCode(for: sampleSpecial)
        
        // When
        let result = try await weeklySpecialService.loadFromShareCode(shareCode)
        
        // Then
        XCTAssertEqual(result.id, sampleSpecial.id)
        XCTAssertEqual(result.title, sampleSpecial.title)
    }
    
    func testLoadFromShareCode_InvalidFormat() async {
        // Given
        let invalidShareCode = "INVALID_CODE"
        
        // When & Then
        do {
            _ = try await weeklySpecialService.loadFromShareCode(invalidShareCode)
            XCTFail("Expected WeeklySpecialError.invalidShareCode")
        } catch WeeklySpecialError.invalidShareCode {
            // Expected
        } catch {
            XCTFail("Expected WeeklySpecialError.invalidShareCode, got \(error)")
        }
    }
    
    func testLoadFromShareCode_InvalidChecksum() async {
        // Given
        let sampleSpecial = WeeklySpecial.sample()
        let validShareCode = weeklySpecialService.generateShareCode(for: sampleSpecial)
        
        // Corrupt the checksum
        let components = validShareCode.split(separator: "_")
        let corruptedShareCode = "\(components[0])_\(components[1])_\(components[2])_\(components[3])_9999"
        
        // When & Then
        do {
            _ = try await weeklySpecialService.loadFromShareCode(corruptedShareCode)
            XCTFail("Expected WeeklySpecialError.invalidShareCode")
        } catch WeeklySpecialError.invalidShareCode {
            // Expected
        } catch {
            XCTFail("Expected WeeklySpecialError.invalidShareCode, got \(error)")
        }
    }
    
    // MARK: - Participation Tests
    
    func testHasParticipated_InitiallyFalse() {
        // Given
        let sampleSpecial = WeeklySpecial.sample()
        
        // When
        let hasParticipated = weeklySpecialService.hasParticipated(in: sampleSpecial.id)
        
        // Then
        XCTAssertFalse(hasParticipated)
    }
    
    func testGetPlayerBestScore_InitiallyNil() {
        // Given
        let sampleSpecial = WeeklySpecial.sample()
        
        // When
        let bestScore = weeklySpecialService.getPlayerBestScore(for: sampleSpecial.id)
        
        // Then
        XCTAssertNil(bestScore)
    }
    
    // MARK: - Caching Tests
    
    func testCacheWeeklySpecials_Success() {
        // Given
        let specials = [WeeklySpecial.sample()]
        
        // When
        weeklySpecialService.cacheWeeklySpecials(specials)
        
        // Then
        let cachedSpecials = weeklySpecialService.loadCachedWeeklySpecials()
        XCTAssertEqual(cachedSpecials.count, 1)
        XCTAssertEqual(cachedSpecials.first?.id, specials.first?.id)
    }
    
    func testLoadCachedWeeklySpecials_EmptyInitially() {
        // When
        let cachedSpecials = weeklySpecialService.loadCachedWeeklySpecials()
        
        // Then
        XCTAssertTrue(cachedSpecials.isEmpty)
    }
    
    func testLoadCachedWeeklySpecials_FiltersExpired() {
        // Given - Create an expired weekly special
        let expiredSpecial = WeeklySpecial(
            title: "Expired Special",
            description: "This special has expired",
            startDate: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 14 days ago
            endDate: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 7 days ago
            courseData: WeeklySpecialCourseData(),
            rewards: WeeklySpecialRewards()
        )
        
        let activeSpecial = WeeklySpecial.sample()
        let specials = [expiredSpecial, activeSpecial]
        
        // When
        weeklySpecialService.cacheWeeklySpecials(specials)
        let cachedSpecials = weeklySpecialService.loadCachedWeeklySpecials()
        
        // Then
        XCTAssertEqual(cachedSpecials.count, 1)
        XCTAssertEqual(cachedSpecials.first?.id, activeSpecial.id)
        XCTAssertFalse(cachedSpecials.contains { $0.id == expiredSpecial.id })
    }
    
    // MARK: - WeeklySpecial Model Tests
    
    func testWeeklySpecial_IsActive() {
        // Given
        let activeSpecial = WeeklySpecial(
            title: "Active Special",
            description: "Currently active",
            startDate: Date().addingTimeInterval(-24 * 60 * 60), // Started yesterday
            endDate: Date().addingTimeInterval(6 * 24 * 60 * 60), // Ends in 6 days
            courseData: WeeklySpecialCourseData(),
            rewards: WeeklySpecialRewards()
        )
        
        // Then
        XCTAssertTrue(activeSpecial.isActive)
        XCTAssertFalse(activeSpecial.isExpired)
    }
    
    func testWeeklySpecial_IsExpired() {
        // Given
        let expiredSpecial = WeeklySpecial(
            title: "Expired Special",
            description: "This has expired",
            startDate: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 14 days ago
            endDate: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 7 days ago
            courseData: WeeklySpecialCourseData(),
            rewards: WeeklySpecialRewards()
        )
        
        // Then
        XCTAssertFalse(expiredSpecial.isActive)
        XCTAssertTrue(expiredSpecial.isExpired)
    }
    
    func testWeeklySpecial_NotStarted() {
        // Given
        let futureSpecial = WeeklySpecial(
            title: "Future Special",
            description: "Starts in the future",
            startDate: Date().addingTimeInterval(24 * 60 * 60), // Starts tomorrow
            endDate: Date().addingTimeInterval(8 * 24 * 60 * 60), // Ends in 8 days
            courseData: WeeklySpecialCourseData(),
            rewards: WeeklySpecialRewards()
        )
        
        // Then
        XCTAssertFalse(futureSpecial.isActive)
        XCTAssertFalse(futureSpecial.isExpired)
        XCTAssertGreaterThan(futureSpecial.timeUntilStart, 0)
    }
    
    func testWeeklySpecial_ToChallenge() {
        // Given
        let weeklySpecial = WeeklySpecial.sample()
        
        // When
        let challenge = weeklySpecial.toChallenge()
        
        // Then
        XCTAssertEqual(challenge.id, weeklySpecial.id)
        XCTAssertEqual(challenge.title, weeklySpecial.title)
        XCTAssertEqual(challenge.description, weeklySpecial.description)
        XCTAssertEqual(challenge.expirationDate, weeklySpecial.endDate)
        XCTAssertEqual(challenge.targetScore, weeklySpecial.targetDistance)
        XCTAssertEqual(challenge.createdBy, "Tiny Pilots Team")
    }
    
    // MARK: - Performance Tests
    
    func testLoadWeeklySpecials_Performance() {
        measure {
            let expectation = XCTestExpectation(description: "Load weekly specials")
            
            Task {
                do {
                    _ = try await weeklySpecialService.loadWeeklySpecials(forceRefresh: false)
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testCaching_Performance() {
        // Given
        let specials = Array(repeating: WeeklySpecial.sample(), count: 100)
        
        // When & Then
        measure {
            weeklySpecialService.cacheWeeklySpecials(specials)
            _ = weeklySpecialService.loadCachedWeeklySpecials()
        }
    }
}

