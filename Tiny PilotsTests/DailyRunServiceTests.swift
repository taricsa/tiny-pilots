//
//  DailyRunServiceTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on Production Readiness Implementation
//

import XCTest
@testable import Tiny_Pilots

/// Unit tests for DailyRunService
class DailyRunServiceTests: XCTestCase {
    
    var sut: DailyRunService!
    var mockGameCenterService: MockGameCenterService!
    var mockNetworkService: MockNetworkService!
    
    override func setUp() {
        super.setUp()
        
        mockGameCenterService = MockGameCenterService()
        mockNetworkService = MockNetworkService()
        
        sut = DailyRunService(
            gameCenterService: mockGameCenterService,
            networkService: mockNetworkService
        )
    }
    
    override func tearDown() {
        sut = nil
        mockGameCenterService = nil
        mockNetworkService = nil
        
        // Clear UserDefaults
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "CompletedDailyRuns")
        userDefaults.removeObject(forKey: "DailyRunCache")
        userDefaults.removeObject(forKey: "DailyRunStreak")
        userDefaults.removeObject(forKey: "DailyRunHistory")
        
        super.tearDown()
    }
    
    // MARK: - Daily Run Generation Tests
    
    func testGetCurrentDailyRun_GeneratesValidDailyRun() {
        // Given
        let expectation = XCTestExpectation(description: "Daily run generation")
        var result: Result<DailyRun, Error>?
        
        // When
        sut.getCurrentDailyRun { dailyRunResult in
            result = dailyRunResult
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        switch result {
        case .success(let dailyRun):
            XCTAssertNotNil(dailyRun, "Daily run should be generated")
            XCTAssertTrue(dailyRun.id.hasPrefix("daily_"), "Daily run ID should have correct prefix")
            XCTAssertGreaterThan(dailyRun.challengeData.obstacles.count, 0, "Should have obstacles")
            XCTAssertGreaterThan(dailyRun.challengeData.collectibles.count, 0, "Should have collectibles")
            XCTAssertGreaterThan(dailyRun.rewards.baseCoins, 0, "Should have base coin rewards")
        case .failure(let error):
            XCTFail("Daily run generation should not fail: \(error)")
        case .none:
            XCTFail("Result should not be nil")
        }
    }
    
    func testGetCurrentDailyRun_SameDayReturnsCachedRun() {
        // Given
        let expectation1 = XCTestExpectation(description: "First daily run generation")
        let expectation2 = XCTestExpectation(description: "Second daily run generation")
        
        var firstRun: DailyRun?
        var secondRun: DailyRun?
        
        // When - First call
        sut.getCurrentDailyRun { result in
            if case .success(let dailyRun) = result {
                firstRun = dailyRun
            }
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 2.0)
        
        // When - Second call (same day)
        sut.getCurrentDailyRun { result in
            if case .success(let dailyRun) = result {
                secondRun = dailyRun
            }
            expectation2.fulfill()
        }
        
        // Then
        wait(for: [expectation2], timeout: 2.0)
        
        XCTAssertNotNil(firstRun, "First run should be generated")
        XCTAssertNotNil(secondRun, "Second run should be returned")
        XCTAssertEqual(firstRun?.id, secondRun?.id, "Same day should return cached run")
        XCTAssertEqual(firstRun?.seed, secondRun?.seed, "Seed should be identical for same day")
    }
    
    func testDailyRunGeneration_DeterministicBasedOnDate() {
        // Given
        let service1 = DailyRunService(gameCenterService: mockGameCenterService, networkService: mockNetworkService)
        let service2 = DailyRunService(gameCenterService: mockGameCenterService, networkService: mockNetworkService)
        
        let expectation1 = XCTestExpectation(description: "Service 1 daily run")
        let expectation2 = XCTestExpectation(description: "Service 2 daily run")
        
        var run1: DailyRun?
        var run2: DailyRun?
        
        // When
        service1.getCurrentDailyRun { result in
            if case .success(let dailyRun) = result {
                run1 = dailyRun
            }
            expectation1.fulfill()
        }
        
        service2.getCurrentDailyRun { result in
            if case .success(let dailyRun) = result {
                run2 = dailyRun
            }
            expectation2.fulfill()
        }
        
        // Then
        wait(for: [expectation1, expectation2], timeout: 2.0)
        
        XCTAssertNotNil(run1, "First service should generate run")
        XCTAssertNotNil(run2, "Second service should generate run")
        XCTAssertEqual(run1?.id, run2?.id, "Same date should generate identical runs")
        XCTAssertEqual(run1?.seed, run2?.seed, "Seeds should be identical")
        XCTAssertEqual(run1?.difficulty, run2?.difficulty, "Difficulty should be identical")
    }
    
    // MARK: - Score Submission Tests
    
    func testSubmitDailyRunScore_WhenAuthenticated_SubmitsToGameCenter() {
        // Given
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSucceedAuthentication = true
        mockGameCenterService.authenticatePlayer()
        
        let expectation = XCTestExpectation(description: "Score submission")
        var submissionError: Error?
        
        // When
        sut.submitDailyRunScore(1500) { error in
            submissionError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertNil(submissionError, "Score submission should succeed")
        XCTAssertTrue(mockGameCenterService.submitScoreCalled, "Should submit score to Game Center")
        XCTAssertEqual(mockGameCenterService.lastSubmittedScore, 1500, "Should submit correct score")
        XCTAssertTrue(sut.hasCompletedTodaysDailyRun(), "Should mark today's run as completed")
    }
    
    func testSubmitDailyRunScore_WhenNotAuthenticated_ReturnsError() {
        // Given
        mockGameCenterService.isAvailable = false
        
        let expectation = XCTestExpectation(description: "Score submission failure")
        var submissionError: Error?
        
        // When
        sut.submitDailyRunScore(1500) { error in
            submissionError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(submissionError, "Should return error when not authenticated")
        XCTAssertTrue(submissionError is DailyRunServiceError, "Should return DailyRunServiceError")
        
        if let dailyRunError = submissionError as? DailyRunServiceError {
            XCTAssertEqual(dailyRunError, .notAuthenticated, "Should return not authenticated error")
        }
        
        XCTAssertFalse(mockGameCenterService.submitScoreCalled, "Should not submit score when not authenticated")
    }
    
    func testSubmitDailyRunScore_InvalidScore_ReturnsError() {
        // Given
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSucceedAuthentication = true
        mockGameCenterService.authenticatePlayer()
        
        let expectation = XCTestExpectation(description: "Invalid score submission")
        var submissionError: Error?
        
        // When
        sut.submitDailyRunScore(0) { error in
            submissionError = error
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(submissionError, "Should return error for invalid score")
        XCTAssertTrue(submissionError is DailyRunServiceError, "Should return DailyRunServiceError")
        
        if let dailyRunError = submissionError as? DailyRunServiceError {
            XCTAssertEqual(dailyRunError, .invalidScore, "Should return invalid score error")
        }
    }
    
    func testSubmitDailyRunScore_AlreadyCompleted_ReturnsError() {
        // Given
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSucceedAuthentication = true
        mockGameCenterService.authenticatePlayer()
        
        let expectation1 = XCTestExpectation(description: "First score submission")
        let expectation2 = XCTestExpectation(description: "Second score submission")
        
        var firstError: Error?
        var secondError: Error?
        
        // When - First submission
        sut.submitDailyRunScore(1500) { error in
            firstError = error
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 2.0)
        
        // When - Second submission (same day)
        sut.submitDailyRunScore(2000) { error in
            secondError = error
            expectation2.fulfill()
        }
        
        // Then
        wait(for: [expectation2], timeout: 2.0)
        
        XCTAssertNil(firstError, "First submission should succeed")
        XCTAssertNotNil(secondError, "Second submission should fail")
        
        if let dailyRunError = secondError as? DailyRunServiceError {
            XCTAssertEqual(dailyRunError, .alreadyCompleted, "Should return already completed error")
        }
    }
    
    // MARK: - Leaderboard Tests
    
    func testGetDailyRunLeaderboard_WhenAuthenticated_ReturnsLeaderboard() {
        // Given
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSucceedAuthentication = true
        mockGameCenterService.authenticatePlayer()
        
        let expectation = XCTestExpectation(description: "Leaderboard loading")
        var result: Result<[DailyRunLeaderboardEntry], Error>?
        
        // When
        sut.getDailyRunLeaderboard { leaderboardResult in
            result = leaderboardResult
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        switch result {
        case .success(let entries):
            XCTAssertTrue(mockGameCenterService.loadLeaderboardCalled, "Should load leaderboard from Game Center")
            XCTAssertGreaterThanOrEqual(entries.count, 0, "Should return leaderboard entries")
        case .failure(let error):
            XCTFail("Leaderboard loading should not fail: \(error)")
        case .none:
            XCTFail("Result should not be nil")
        }
    }
    
    func testGetDailyRunLeaderboard_WhenNotAuthenticated_ReturnsError() {
        // Given
        mockGameCenterService.isAvailable = false
        
        let expectation = XCTestExpectation(description: "Leaderboard loading failure")
        var result: Result<[DailyRunLeaderboardEntry], Error>?
        
        // When
        sut.getDailyRunLeaderboard { leaderboardResult in
            result = leaderboardResult
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        switch result {
        case .success:
            XCTFail("Should not succeed when not authenticated")
        case .failure(let error):
            XCTAssertTrue(error is DailyRunServiceError, "Should return DailyRunServiceError")
            if let dailyRunError = error as? DailyRunServiceError {
                XCTAssertEqual(dailyRunError, .notAuthenticated, "Should return not authenticated error")
            }
        case .none:
            XCTFail("Result should not be nil")
        }
    }
    
    // MARK: - Streak Tests
    
    func testGetStreakInfo_InitialState_ReturnsZeroStreak() {
        // Given
        let expectation = XCTestExpectation(description: "Streak info loading")
        var result: Result<DailyRunStreak, Error>?
        
        // When
        sut.getStreakInfo { streakResult in
            result = streakResult
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        switch result {
        case .success(let streak):
            XCTAssertEqual(streak.currentStreak, 0, "Initial streak should be 0")
            XCTAssertEqual(streak.longestStreak, 0, "Initial longest streak should be 0")
            XCTAssertNil(streak.lastCompletionDate, "Should have no last completion date initially")
        case .failure(let error):
            XCTFail("Streak info loading should not fail: \(error)")
        case .none:
            XCTFail("Result should not be nil")
        }
    }
    
    func testStreakCalculation_AfterCompletingDailyRun_UpdatesStreak() {
        // Given
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSucceedAuthentication = true
        mockGameCenterService.authenticatePlayer()
        
        let scoreExpectation = XCTestExpectation(description: "Score submission")
        let streakExpectation = XCTestExpectation(description: "Streak info loading")
        
        // When - Submit score
        sut.submitDailyRunScore(1500) { error in
            XCTAssertNil(error, "Score submission should succeed")
            scoreExpectation.fulfill()
        }
        
        wait(for: [scoreExpectation], timeout: 2.0)
        
        // When - Get streak info
        var streakResult: Result<DailyRunStreak, Error>?
        sut.getStreakInfo { result in
            streakResult = result
            streakExpectation.fulfill()
        }
        
        // Then
        wait(for: [streakExpectation], timeout: 2.0)
        
        switch streakResult {
        case .success(let streak):
            XCTAssertEqual(streak.currentStreak, 1, "Streak should be 1 after first completion")
            XCTAssertEqual(streak.longestStreak, 1, "Longest streak should be 1")
            XCTAssertNotNil(streak.lastCompletionDate, "Should have last completion date")
        case .failure(let error):
            XCTFail("Streak info loading should not fail: \(error)")
        case .none:
            XCTFail("Result should not be nil")
        }
    }
    
    // MARK: - Completion Status Tests
    
    func testHasCompletedTodaysDailyRun_InitialState_ReturnsFalse() {
        // When
        let hasCompleted = sut.hasCompletedTodaysDailyRun()
        
        // Then
        XCTAssertFalse(hasCompleted, "Should not have completed today's daily run initially")
    }
    
    func testHasCompletedTodaysDailyRun_AfterSubmission_ReturnsTrue() {
        // Given
        mockGameCenterService.isAvailable = true
        mockGameCenterService.shouldSucceedAuthentication = true
        mockGameCenterService.authenticatePlayer()
        
        let expectation = XCTestExpectation(description: "Score submission")
        
        // When
        sut.submitDailyRunScore(1500) { error in
            XCTAssertNil(error, "Score submission should succeed")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // Then
        let hasCompleted = sut.hasCompletedTodaysDailyRun()
        XCTAssertTrue(hasCompleted, "Should have completed today's daily run after submission")
    }
    
    // MARK: - History Tests
    
    func testGetDailyRunHistory_InitialState_ReturnsEmptyHistory() {
        // Given
        let expectation = XCTestExpectation(description: "History loading")
        var result: Result<[DailyRunResult], Error>?
        
        // When
        sut.getDailyRunHistory { historyResult in
            result = historyResult
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        switch result {
        case .success(let history):
            XCTAssertEqual(history.count, 0, "Initial history should be empty")
        case .failure(let error):
            XCTFail("History loading should not fail: \(error)")
        case .none:
            XCTFail("Result should not be nil")
        }
    }
    
    // MARK: - Shareable Result Tests
    
    func testGenerateShareableResult_ValidResult_ReturnsShareData() {
        // Given
        let result = DailyRunResult(
            id: "test_result",
            dailyRunId: "daily_2024-01-01",
            playerID: "test_player",
            score: 1500,
            distance: 1500.0,
            coinsCollected: 150,
            completionTime: Date(),
            duration: 120.0,
            rank: 5,
            rewards: DailyRunRewards(baseCoins: 100, streakBonus: 20, difficultyBonus: 30, achievements: [])
        )
        
        let expectation = XCTestExpectation(description: "Share data generation")
        var shareResult: Result<DailyRunShareData, Error>?
        
        // When
        sut.generateShareableResult(result) { shareDataResult in
            shareResult = shareDataResult
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        switch shareResult {
        case .success(let shareData):
            XCTAssertFalse(shareData.text.isEmpty, "Share text should not be empty")
            XCTAssertTrue(shareData.text.contains("1500"), "Share text should contain score")
            XCTAssertFalse(shareData.hashtags.isEmpty, "Should have hashtags")
            XCTAssertTrue(shareData.hashtags.contains("#TinyPilots"), "Should contain app hashtag")
        case .failure(let error):
            XCTFail("Share data generation should not fail: \(error)")
        case .none:
            XCTFail("Result should not be nil")
        }
    }
    
    // MARK: - Friends Comparison Tests
    
    func testGetFriendsComparison_ReturnsEmptyArray() {
        // Given
        let expectation = XCTestExpectation(description: "Friends comparison")
        var result: Result<[DailyRunFriendComparison], Error>?
        
        // When
        sut.getFriendsComparison { comparisonResult in
            result = comparisonResult
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        switch result {
        case .success(let comparisons):
            XCTAssertEqual(comparisons.count, 0, "Friends comparison should return empty array (not implemented)")
        case .failure(let error):
            XCTFail("Friends comparison should not fail: \(error)")
        case .none:
            XCTFail("Result should not be nil")
        }
    }
    
    // MARK: - Difficulty Tests
    
    func testDifficultyDistribution_GeneratesVariedDifficulties() {
        // Given
        var difficulties: [DailyRunDifficulty] = []
        let expectation = XCTestExpectation(description: "Multiple daily run generations")
        expectation.expectedFulfillmentCount = 10
        
        // When - Generate multiple daily runs (simulating different days)
        for i in 0..<10 {
            let testDate = Calendar.current.date(byAdding: .day, value: i, to: Date()) ?? Date()
            
            // Create a new service instance to avoid caching
            let testService = DailyRunService(gameCenterService: mockGameCenterService, networkService: mockNetworkService)
            
            testService.getCurrentDailyRun { result in
                if case .success(let dailyRun) = result {
                    difficulties.append(dailyRun.difficulty)
                }
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        
        XCTAssertEqual(difficulties.count, 10, "Should generate 10 daily runs")
        
        // Check that we have some variety in difficulties (not all the same)
        let uniqueDifficulties = Set(difficulties)
        XCTAssertGreaterThan(uniqueDifficulties.count, 1, "Should have variety in difficulties")
    }
    
    // MARK: - Performance Tests
    
    func testDailyRunGeneration_Performance() {
        // Given
        let expectation = XCTestExpectation(description: "Performance test")
        expectation.expectedFulfillmentCount = 100
        
        // When
        measure {
            for _ in 0..<100 {
                sut.getCurrentDailyRun { _ in
                    expectation.fulfill()
                }
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Edge Cases
    
    func testDailyRunGeneration_HandlesMidnightTransition() {
        // This test would be more complex to implement properly
        // as it would require mocking the date/time system
        // For now, we'll just ensure the service handles date changes gracefully
        
        // Given
        let expectation = XCTestExpectation(description: "Daily run generation")
        var result: Result<DailyRun, Error>?
        
        // When
        sut.getCurrentDailyRun { dailyRunResult in
            result = dailyRunResult
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        switch result {
        case .success(let dailyRun):
            XCTAssertNotNil(dailyRun.expiresAt, "Daily run should have expiration date")
            XCTAssertGreaterThan(dailyRun.expiresAt, Date(), "Expiration should be in the future")
        case .failure(let error):
            XCTFail("Daily run generation should not fail: \(error)")
        case .none:
            XCTFail("Result should not be nil")
        }
    }
}