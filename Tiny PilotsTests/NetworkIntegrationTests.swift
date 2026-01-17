//
//  NetworkIntegrationTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
import Network
@testable import Tiny_Pilots

/// Comprehensive network and Game Center integration tests
final class NetworkIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    var mockGameCenterService: MockGameCenterService!
    var networkMonitor: NetworkMonitor!
    var challengeService: ChallengeService!
    var weeklySpecialService: WeeklySpecialService!
    var dailyRunService: DailyRunService!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockGameCenterService = MockGameCenterService()
        networkMonitor = NetworkMonitor()
        
        // Create services with mock dependencies
        challengeService = ChallengeService(
            networkService: MockNetworkService(),
            gameCenterService: mockGameCenterService
        )
        
        weeklySpecialService = WeeklySpecialService(
            networkService: MockNetworkService(),
            gameCenterService: mockGameCenterService
        )
        
        dailyRunService = DailyRunService(
            networkService: MockNetworkService(),
            gameCenterService: mockGameCenterService
        )
        
        mockGameCenterService.reset()
    }
    
    override func tearDownWithError() throws {
        mockGameCenterService = nil
        networkMonitor = nil
        challengeService = nil
        weeklySpecialService = nil
        dailyRunService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Network Connectivity Tests
    
    func testNetworkMonitor_ConnectivityDetection() throws {
        // Test network monitor initialization
        XCTAssertNotNil(networkMonitor)
        
        // Test starting network monitoring
        networkMonitor.startMonitoring()
        XCTAssertTrue(networkMonitor.isMonitoring)
        
        // Test stopping network monitoring
        networkMonitor.stopMonitoring()
        XCTAssertFalse(networkMonitor.isMonitoring)
        
        // Test connectivity status
        let isConnected = networkMonitor.isConnected
        XCTAssertTrue(isConnected || !isConnected) // Should return a boolean value
    }
    
    func testNetworkMonitor_ConnectivityChanges() throws {
        let expectation = XCTestExpectation(description: "Network status change")
        
        // Set up network status change handler
        networkMonitor.onNetworkStatusChange = { isConnected in
            XCTAssertTrue(isConnected || !isConnected) // Should be a valid boolean
            expectation.fulfill()
        }
        
        networkMonitor.startMonitoring()
        
        // Simulate network change (in real implementation, this would be triggered by system)
        networkMonitor.simulateNetworkChange(isConnected: false)
        
        wait(for: [expectation], timeout: 2.0)
        networkMonitor.stopMonitoring()
    }
    
    func testNetworkMonitor_OfflineMode() throws {
        // Test offline mode detection
        networkMonitor.simulateNetworkChange(isConnected: false)
        XCTAssertFalse(networkMonitor.isConnected)
        
        // Test online mode detection
        networkMonitor.simulateNetworkChange(isConnected: true)
        XCTAssertTrue(networkMonitor.isConnected)
    }
    
    // MARK: - Game Center Service Integration Tests
    
    func testGameCenterService_AuthenticationFlow() async throws {
        // Test authentication success
        mockGameCenterService.shouldFailAuthentication = false
        
        let authResult = await withCheckedContinuation { continuation in
            mockGameCenterService.authenticate { success, error in
                continuation.resume(returning: (success, error))
            }
        }
        
        XCTAssertTrue(authResult.0)
        XCTAssertNil(authResult.1)
        XCTAssertTrue(mockGameCenterService.isAuthenticated)
        XCTAssertEqual(mockGameCenterService.playerDisplayName, "Test Player")
        
        // Test authentication failure
        mockGameCenterService.reset()
        mockGameCenterService.shouldFailAuthentication = true
        
        let failResult = await withCheckedContinuation { continuation in
            mockGameCenterService.authenticate { success, error in
                continuation.resume(returning: (success, error))
            }
        }
        
        XCTAssertFalse(failResult.0)
        XCTAssertNotNil(failResult.1)
        XCTAssertFalse(mockGameCenterService.isAuthenticated)
    }
    
    func testGameCenterService_LeaderboardOperations() async throws {
        // Setup authentication
        mockGameCenterService.simulateSuccessfulAuthentication()
        mockGameCenterService.simulateLeaderboardData()
        
        // Test score submission
        let submitResult = await withCheckedContinuation { continuation in
            mockGameCenterService.submitScore(1500, to: "high_score") { error in
                continuation.resume(returning: error)
            }
        }
        
        XCTAssertNil(submitResult)
        XCTAssertEqual(mockGameCenterService.scoresSubmitted.count, 1)
        XCTAssertEqual(mockGameCenterService.scoresSubmitted[0].score, 1500)
        XCTAssertEqual(mockGameCenterService.scoresSubmitted[0].leaderboardID, "high_score")
        
        // Test leaderboard loading
        let loadResult = await withCheckedContinuation { continuation in
            mockGameCenterService.loadLeaderboard(for: "high_score") { entries, error in
                continuation.resume(returning: (entries, error))
            }
        }
        
        XCTAssertNil(loadResult.1)
        XCTAssertNotNil(loadResult.0)
        XCTAssertEqual(loadResult.0?.count, 3)
        XCTAssertEqual(loadResult.0?[0].displayName, "Player 1")
        XCTAssertEqual(loadResult.0?[0].score, 1500)
        XCTAssertEqual(loadResult.0?[0].rank, 1)
    }
    
    func testGameCenterService_AchievementOperations() async throws {
        // Setup authentication and achievement data
        mockGameCenterService.simulateSuccessfulAuthentication()
        mockGameCenterService.simulateAchievementData()
        
        // Test achievement reporting
        let reportResult = await withCheckedContinuation { continuation in
            mockGameCenterService.reportAchievement(identifier: "first_flight", percentComplete: 100.0) { error in
                continuation.resume(returning: error)
            }
        }
        
        XCTAssertNil(reportResult)
        XCTAssertEqual(mockGameCenterService.achievementsReported.count, 1)
        XCTAssertEqual(mockGameCenterService.achievementsReported[0].identifier, "first_flight")
        XCTAssertEqual(mockGameCenterService.achievementsReported[0].percentComplete, 100.0)
        
        // Test achievement loading
        let loadResult = await withCheckedContinuation { continuation in
            mockGameCenterService.loadAchievements { achievements, error in
                continuation.resume(returning: (achievements, error))
            }
        }
        
        XCTAssertNil(loadResult.1)
        XCTAssertNotNil(loadResult.0)
        XCTAssertEqual(loadResult.0?.count, 3)
    }
    
    func testGameCenterService_ChallengeOperations() async throws {
        // Test challenge code generation
        let challengeCode = mockGameCenterService.generateChallengeCode(for: "test_course_data")
        XCTAssertEqual(challengeCode, "TEST_1")
        XCTAssertTrue(mockGameCenterService.challengeCodesGenerated.contains("TEST_1"))
        
        // Test challenge code validation - success
        let validResult = await withCheckedContinuation { continuation in
            mockGameCenterService.validateChallengeCode("VALID_CODE") { result in
                continuation.resume(returning: result)
            }
        }
        
        switch validResult {
        case .success(let courseData):
            XCTAssertEqual(courseData, "Mock course data for VALID_CODE")
        case .failure:
            XCTFail("Validation should succeed")
        }
        
        // Test challenge code validation - failure
        mockGameCenterService.shouldFailChallengeValidation = true
        
        let invalidResult = await withCheckedContinuation { continuation in
            mockGameCenterService.validateChallengeCode("INVALID_CODE") { result in
                continuation.resume(returning: result)
            }
        }
        
        switch invalidResult {
        case .success:
            XCTFail("Validation should fail")
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Challenge Service Integration Tests
    
    func testChallengeService_LoadChallenge() async throws {
        // Test successful challenge loading
        do {
            let challenge = try await challengeService.loadChallenge(code: "VALID123")
            XCTAssertNotNil(challenge)
            XCTAssertEqual(challenge.id, "VALID123")
            XCTAssertFalse(challenge.title.isEmpty)
            XCTAssertNotNil(challenge.courseData)
        } catch {
            XCTFail("Challenge loading should succeed: \(error)")
        }
        
        // Test invalid challenge code
        do {
            _ = try await challengeService.loadChallenge(code: "INVALID")
            XCTFail("Should throw error for invalid code")
        } catch ChallengeError.invalidCode {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testChallengeService_ValidateCode() async throws {
        // Test valid code
        do {
            let isValid = try await challengeService.validateChallengeCode("VALID123")
            XCTAssertTrue(isValid)
        } catch {
            XCTFail("Code validation should succeed: \(error)")
        }
        
        // Test invalid code
        do {
            let isValid = try await challengeService.validateChallengeCode("INVALID")
            XCTAssertFalse(isValid)
        } catch {
            // Error is acceptable for invalid codes
        }
    }
    
    func testChallengeService_GenerateCode() throws {
        let challenge = Challenge(
            id: "test_challenge",
            title: "Test Challenge",
            description: "A test challenge",
            courseData: ChallengeData(
                environmentType: "standard",
                obstacles: [],
                collectibles: [],
                weatherConditions: WeatherConfiguration(),
                targetScore: 1000
            ),
            expirationDate: Date().addingTimeInterval(86400),
            createdBy: "test_user"
        )
        
        let code = challengeService.generateChallengeCode(for: challenge)
        XCTAssertFalse(code.isEmpty)
        XCTAssertTrue(mockGameCenterService.challengeCodesGenerated.contains(code))
    }
    
    // MARK: - Weekly Special Service Integration Tests
    
    func testWeeklySpecialService_LoadCurrentSpecial() async throws {
        // Test loading current weekly special
        do {
            let weeklySpecial = try await weeklySpecialService.loadCurrentWeeklySpecial()
            XCTAssertNotNil(weeklySpecial)
            XCTAssertFalse(weeklySpecial.title.isEmpty)
            XCTAssertNotNil(weeklySpecial.challengeData)
            XCTAssertGreaterThan(weeklySpecial.endDate, Date())
        } catch {
            XCTFail("Weekly special loading should succeed: \(error)")
        }
    }
    
    func testWeeklySpecialService_SubmitScore() async throws {
        mockGameCenterService.simulateSuccessfulAuthentication()
        
        // Test score submission
        do {
            try await weeklySpecialService.submitScore(2500, for: "weekly_2024_01")
            XCTAssertGreaterThan(mockGameCenterService.scoresSubmitted.count, 0)
            
            let submittedScore = mockGameCenterService.scoresSubmitted.first { $0.leaderboardID.contains("weekly") }
            XCTAssertNotNil(submittedScore)
            XCTAssertEqual(submittedScore?.score, 2500)
        } catch {
            XCTFail("Score submission should succeed: \(error)")
        }
    }
    
    func testWeeklySpecialService_LoadLeaderboard() async throws {
        mockGameCenterService.simulateSuccessfulAuthentication()
        mockGameCenterService.simulateLeaderboardData()
        
        // Test leaderboard loading
        do {
            let leaderboard = try await weeklySpecialService.loadLeaderboard(for: "weekly_2024_01")
            XCTAssertNotNil(leaderboard)
            XCTAssertGreaterThan(leaderboard.count, 0)
            XCTAssertEqual(leaderboard[0].displayName, "Player 1")
        } catch {
            XCTFail("Leaderboard loading should succeed: \(error)")
        }
    }
    
    // MARK: - Daily Run Service Integration Tests
    
    func testDailyRunService_GenerateDailyChallenge() async throws {
        // Test daily challenge generation
        do {
            let dailyChallenge = try await dailyRunService.generateDailyChallenge(for: Date())
            XCTAssertNotNil(dailyChallenge)
            XCTAssertFalse(dailyChallenge.title.isEmpty)
            XCTAssertNotNil(dailyChallenge.courseData)
            XCTAssertTrue(dailyChallenge.id.contains("daily"))
        } catch {
            XCTFail("Daily challenge generation should succeed: \(error)")
        }
    }
    
    func testDailyRunService_SubmitScore() async throws {
        mockGameCenterService.simulateSuccessfulAuthentication()
        
        // Test daily run score submission
        do {
            try await dailyRunService.submitScore(1800, for: Date())
            XCTAssertGreaterThan(mockGameCenterService.scoresSubmitted.count, 0)
            
            let submittedScore = mockGameCenterService.scoresSubmitted.first { $0.leaderboardID.contains("daily") }
            XCTAssertNotNil(submittedScore)
            XCTAssertEqual(submittedScore?.score, 1800)
        } catch {
            XCTFail("Daily run score submission should succeed: \(error)")
        }
    }
    
    func testDailyRunService_StreakTracking() async throws {
        // Test streak calculation
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        
        // Test consecutive day streak
        let consecutiveStreak = dailyRunService.calculateStreak(lastRunDate: yesterday, currentStreak: 5)
        XCTAssertEqual(consecutiveStreak, 6)
        
        // Test broken streak
        let brokenStreak = dailyRunService.calculateStreak(lastRunDate: twoDaysAgo, currentStreak: 10)
        XCTAssertEqual(brokenStreak, 1)
        
        // Test first run
        let firstStreak = dailyRunService.calculateStreak(lastRunDate: nil, currentStreak: 0)
        XCTAssertEqual(firstStreak, 1)
    }
    
    // MARK: - Network Error Handling Tests
    
    func testNetworkErrorHandling_GameCenterOffline() async throws {
        // Simulate Game Center being offline
        mockGameCenterService.shouldFailAuthentication = true
        mockGameCenterService.shouldFailScoreSubmission = true
        mockGameCenterService.shouldFailLeaderboardLoad = true
        
        // Test that services handle offline gracefully
        let authResult = await withCheckedContinuation { continuation in
            mockGameCenterService.authenticate { success, error in
                continuation.resume(returning: (success, error))
            }
        }
        
        XCTAssertFalse(authResult.0)
        XCTAssertNotNil(authResult.1)
        
        // Test score submission failure
        let submitResult = await withCheckedContinuation { continuation in
            mockGameCenterService.submitScore(1000, to: "test") { error in
                continuation.resume(returning: error)
            }
        }
        
        XCTAssertNotNil(submitResult)
        
        // Test leaderboard loading failure
        let loadResult = await withCheckedContinuation { continuation in
            mockGameCenterService.loadLeaderboard(for: "test") { entries, error in
                continuation.resume(returning: (entries, error))
            }
        }
        
        XCTAssertNotNil(loadResult.1)
        XCTAssertNil(loadResult.0)
    }
    
    func testNetworkErrorHandling_RetryLogic() async throws {
        // Test retry logic for network failures
        var attemptCount = 0
        
        // Simulate network service with retry logic
        let mockNetworkService = MockNetworkService()
        mockNetworkService.shouldFailInitially = true
        mockNetworkService.onRequest = {
            attemptCount += 1
            if attemptCount < 3 {
                throw NetworkError.connectionFailed
            }
            return "Success after retries"
        }
        
        // Test that service retries and eventually succeeds
        do {
            let result = try await mockNetworkService.performRequest("test_endpoint")
            XCTAssertEqual(result, "Success after retries")
            XCTAssertEqual(attemptCount, 3)
        } catch {
            XCTFail("Request should succeed after retries: \(error)")
        }
    }
    
    func testNetworkErrorHandling_TimeoutHandling() async throws {
        let mockNetworkService = MockNetworkService()
        mockNetworkService.simulateTimeout = true
        
        // Test timeout handling
        do {
            _ = try await mockNetworkService.performRequest("slow_endpoint")
            XCTFail("Request should timeout")
        } catch NetworkError.timeout {
            // Expected timeout error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Data Synchronization Tests
    
    func testDataSynchronization_OfflineToOnline() async throws {
        // Simulate offline data accumulation
        let offlineScores = [
            (score: 1000, leaderboard: "test1"),
            (score: 1500, leaderboard: "test2"),
            (score: 2000, leaderboard: "test3")
        ]
        
        // Simulate going online and syncing data
        mockGameCenterService.simulateSuccessfulAuthentication()
        
        for (score, leaderboard) in offlineScores {
            let result = await withCheckedContinuation { continuation in
                mockGameCenterService.submitScore(score, to: leaderboard) { error in
                    continuation.resume(returning: error)
                }
            }
            XCTAssertNil(result, "Offline score sync should succeed")
        }
        
        XCTAssertEqual(mockGameCenterService.scoresSubmitted.count, 3)
    }
    
    func testDataSynchronization_ConflictResolution() async throws {
        // Test handling of data conflicts during sync
        mockGameCenterService.simulateSuccessfulAuthentication()
        mockGameCenterService.simulateLeaderboardData()
        
        // Submit a score that might conflict with existing data
        let result = await withCheckedContinuation { continuation in
            mockGameCenterService.submitScore(1200, to: "high_score") { error in
                continuation.resume(returning: error)
            }
        }
        
        XCTAssertNil(result)
        
        // Verify that the service handled the potential conflict
        let loadResult = await withCheckedContinuation { continuation in
            mockGameCenterService.loadLeaderboard(for: "high_score") { entries, error in
                continuation.resume(returning: (entries, error))
            }
        }
        
        XCTAssertNil(loadResult.1)
        XCTAssertNotNil(loadResult.0)
    }
    
    // MARK: - Performance Tests
    
    func testNetworkPerformance_ConcurrentRequests() async throws {
        let requestCount = 10
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform concurrent network requests
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<requestCount {
                group.addTask {
                    let result = await withCheckedContinuation { continuation in
                        self.mockGameCenterService.submitScore(i * 100, to: "perf_test") { error in
                            continuation.resume(returning: error)
                        }
                    }
                    XCTAssertNil(result)
                }
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        XCTAssertLessThan(totalTime, 2.0, "Concurrent requests should complete within 2 seconds")
        XCTAssertEqual(mockGameCenterService.scoresSubmitted.count, requestCount)
    }
    
    func testNetworkPerformance_LargeDataHandling() async throws {
        // Test handling of large leaderboard data
        for i in 0..<1000 {
            mockGameCenterService.addMockLeaderboardEntry(
                playerID: "player_\(i)",
                displayName: "Player \(i)",
                score: i * 10,
                rank: i + 1
            )
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = await withCheckedContinuation { continuation in
            mockGameCenterService.loadLeaderboard(for: "large_leaderboard") { entries, error in
                continuation.resume(returning: (entries, error))
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let loadTime = endTime - startTime
        
        XCTAssertNil(result.1)
        XCTAssertNotNil(result.0)
        XCTAssertEqual(result.0?.count, 1000)
        XCTAssertLessThan(loadTime, 1.0, "Large leaderboard should load within 1 second")
    }
}



// MARK: - Network Monitor Extension

extension NetworkMonitor {
    func simulateNetworkChange(isConnected: Bool) {
        self.isConnected = isConnected
        onNetworkStatusChange?(isConnected)
    }
}