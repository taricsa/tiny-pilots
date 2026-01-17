import XCTest
@testable import Tiny_Pilots

/// Unit tests for business logic classes
class BusinessLogicTests: XCTestCase {
    
    // MARK: - GameRules Tests
    
    func testGameRules_CanTransitionGameState_ValidTransitions() {
        // Test valid transitions
        XCTAssertTrue(GameRules.canTransitionGameState(from: .notStarted, to: .playing, playerLevel: 1))
        XCTAssertTrue(GameRules.canTransitionGameState(from: .playing, to: .paused, playerLevel: 1))
        XCTAssertTrue(GameRules.canTransitionGameState(from: .paused, to: .playing, playerLevel: 1))
        XCTAssertTrue(GameRules.canTransitionGameState(from: .playing, to: .ended, playerLevel: 1))
        XCTAssertTrue(GameRules.canTransitionGameState(from: .paused, to: .ended, playerLevel: 1))
    }
    
    func testGameRules_CanTransitionGameState_InvalidTransitions() {
        // Test invalid transitions
        XCTAssertFalse(GameRules.canTransitionGameState(from: .ended, to: .playing, playerLevel: 1))
        XCTAssertFalse(GameRules.canTransitionGameState(from: .ended, to: .paused, playerLevel: 1))
    }
    
    func testGameRules_IsGameModeUnlocked_ChecksPlayerLevel() {
        // Test mode unlock requirements
        XCTAssertTrue(GameRules.isGameModeUnlocked(.tutorial, playerLevel: 1))
        XCTAssertTrue(GameRules.isGameModeUnlocked(.freePlay, playerLevel: 1))
        XCTAssertFalse(GameRules.isGameModeUnlocked(.challenge, playerLevel: 2))
        XCTAssertTrue(GameRules.isGameModeUnlocked(.challenge, playerLevel: 3))
        XCTAssertFalse(GameRules.isGameModeUnlocked(.dailyRun, playerLevel: 4))
        XCTAssertTrue(GameRules.isGameModeUnlocked(.dailyRun, playerLevel: 5))
        XCTAssertFalse(GameRules.isGameModeUnlocked(.weeklySpecial, playerLevel: 9))
        XCTAssertTrue(GameRules.isGameModeUnlocked(.weeklySpecial, playerLevel: 10))
    }
    
    func testGameRules_CalculateBaseScore_CorrectCalculation() {
        // Test score calculation
        let score = GameRules.calculateBaseScore(distance: 100, time: 60, coins: 5)
        let expectedScore = (100 * 10) + (60 / 10) + (5 * 100) // 1000 + 6 + 500 = 1506
        XCTAssertEqual(score, expectedScore)
    }
    
    func testGameRules_ApplyObstaclePenalty_CorrectPenalties() {
        // Test obstacle penalties
        XCTAssertEqual(GameRules.applyObstaclePenalty(currentScore: 1000, obstacleType: .building), 900)
        XCTAssertEqual(GameRules.applyObstaclePenalty(currentScore: 1000, obstacleType: .tree), 925)
        XCTAssertEqual(GameRules.applyObstaclePenalty(currentScore: 1000, obstacleType: .rock), 950)
        XCTAssertEqual(GameRules.applyObstaclePenalty(currentScore: 1000, obstacleType: .fence), 975)
        
        // Test minimum score of 0
        XCTAssertEqual(GameRules.applyObstaclePenalty(currentScore: 25, obstacleType: .rock), 0)
    }
    
    func testGameRules_GetScoreMultiplier_CorrectMultipliers() {
        // Test score multipliers
        XCTAssertEqual(GameRules.getScoreMultiplier(for: .tutorial), 0.5, accuracy: 0.01)
        XCTAssertEqual(GameRules.getScoreMultiplier(for: .freePlay), 1.0, accuracy: 0.01)
        XCTAssertEqual(GameRules.getScoreMultiplier(for: .challenge), 1.5, accuracy: 0.01)
        XCTAssertEqual(GameRules.getScoreMultiplier(for: .dailyRun), 2.0, accuracy: 0.01)
        XCTAssertEqual(GameRules.getScoreMultiplier(for: .weeklySpecial), 2.5, accuracy: 0.01)
    }
    
    func testGameRules_CanUnlockContent_AirplaneUnlocks() {
        // Test airplane unlock requirements
        XCTAssertTrue(GameRules.canUnlockContent(contentId: "basic", type: .airplane, playerLevel: 1, totalScore: 0, completedChallenges: 0))
        XCTAssertFalse(GameRules.canUnlockContent(contentId: "speedy", type: .airplane, playerLevel: 2, totalScore: 3000, completedChallenges: 0))
        XCTAssertTrue(GameRules.canUnlockContent(contentId: "speedy", type: .airplane, playerLevel: 3, totalScore: 5000, completedChallenges: 0))
        XCTAssertTrue(GameRules.canUnlockContent(contentId: "sturdy", type: .airplane, playerLevel: 5, totalScore: 15000, completedChallenges: 0))
        XCTAssertTrue(GameRules.canUnlockContent(contentId: "glider", type: .airplane, playerLevel: 8, totalScore: 30000, completedChallenges: 0))
    }
    
    func testGameRules_CanUnlockContent_EnvironmentUnlocks() {
        // Test environment unlock requirements
        XCTAssertTrue(GameRules.canUnlockContent(contentId: "standard", type: .environment, playerLevel: 1, totalScore: 0, completedChallenges: 0))
        XCTAssertTrue(GameRules.canUnlockContent(contentId: "alpine", type: .environment, playerLevel: 4, totalScore: 0, completedChallenges: 0))
        XCTAssertFalse(GameRules.canUnlockContent(contentId: "coastal", type: .environment, playerLevel: 6, totalScore: 0, completedChallenges: 2))
        XCTAssertTrue(GameRules.canUnlockContent(contentId: "coastal", type: .environment, playerLevel: 6, totalScore: 0, completedChallenges: 3))
        XCTAssertTrue(GameRules.canUnlockContent(contentId: "urban", type: .environment, playerLevel: 8, totalScore: 0, completedChallenges: 8))
        XCTAssertTrue(GameRules.canUnlockContent(contentId: "desert", type: .environment, playerLevel: 10, totalScore: 0, completedChallenges: 15))
    }
    
    func testGameRules_CalculateDailyRunStreak_CorrectLogic() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        // First daily run
        XCTAssertEqual(GameRules.calculateDailyRunStreak(lastRunDate: nil, currentStreak: 0), 1)
        
        // Already completed today
        XCTAssertEqual(GameRules.calculateDailyRunStreak(lastRunDate: today, currentStreak: 5), 5)
        
        // Consecutive day
        XCTAssertEqual(GameRules.calculateDailyRunStreak(lastRunDate: yesterday, currentStreak: 3), 4)
        
        // Streak broken
        XCTAssertEqual(GameRules.calculateDailyRunStreak(lastRunDate: twoDaysAgo, currentStreak: 5), 1)
    }
    
    func testGameRules_GetDailyRunStreakBonus_CorrectBonuses() {
        // Test streak bonuses
        XCTAssertEqual(GameRules.getDailyRunStreakBonus(streak: 1), 1.0, accuracy: 0.01)
        XCTAssertEqual(GameRules.getDailyRunStreakBonus(streak: 2), 1.0, accuracy: 0.01)
        XCTAssertEqual(GameRules.getDailyRunStreakBonus(streak: 5), 1.2, accuracy: 0.01)
        XCTAssertEqual(GameRules.getDailyRunStreakBonus(streak: 10), 1.5, accuracy: 0.01)
        XCTAssertEqual(GameRules.getDailyRunStreakBonus(streak: 20), 2.0, accuracy: 0.01)
        XCTAssertEqual(GameRules.getDailyRunStreakBonus(streak: 35), 2.5, accuracy: 0.01)
    }
    
    func testGameRules_IsChallengeCompleted_CorrectValidation() {
        // Test challenge completion validation
        XCTAssertTrue(GameRules.isChallengeCompleted(challengeId: "distance_500", score: 1000, distance: 600, time: 60, coins: 5))
        XCTAssertFalse(GameRules.isChallengeCompleted(challengeId: "distance_500", score: 1000, distance: 400, time: 60, coins: 5))
        
        XCTAssertTrue(GameRules.isChallengeCompleted(challengeId: "score_5000", score: 6000, distance: 300, time: 60, coins: 5))
        XCTAssertFalse(GameRules.isChallengeCompleted(challengeId: "score_5000", score: 4000, distance: 300, time: 60, coins: 5))
        
        XCTAssertTrue(GameRules.isChallengeCompleted(challengeId: "time_120", score: 1000, distance: 300, time: 130, coins: 5))
        XCTAssertFalse(GameRules.isChallengeCompleted(challengeId: "time_120", score: 1000, distance: 300, time: 100, coins: 5))
        
        XCTAssertTrue(GameRules.isChallengeCompleted(challengeId: "coins_10", score: 1000, distance: 300, time: 60, coins: 12))
        XCTAssertFalse(GameRules.isChallengeCompleted(challengeId: "coins_10", score: 1000, distance: 300, time: 60, coins: 8))
        
        XCTAssertTrue(GameRules.isChallengeCompleted(challengeId: "perfect_flight", score: 3500, distance: 350, time: 60, coins: 6))
        XCTAssertFalse(GameRules.isChallengeCompleted(challengeId: "perfect_flight", score: 2500, distance: 350, time: 60, coins: 6))
    }
    
    // MARK: - PhysicsCalculations Tests
    
    func testPhysicsCalculations_CalculateLiftForce_CorrectCalculation() {
        let velocity = CGVector(dx: 100, dy: 0)
        let liftForce = PhysicsCalculations.calculateLiftForce(
            velocity: velocity,
            airplaneType: .basic,
            foldType: .basic
        )
        
        // Lift should be perpendicular to velocity (upward when moving right)
        XCTAssertEqual(liftForce.dx, 0, accuracy: 0.01)
        XCTAssertGreaterThan(liftForce.dy, 0)
    }
    
    func testPhysicsCalculations_CalculateDragForce_OpposesVelocity() {
        let velocity = CGVector(dx: 100, dy: 50)
        let dragForce = PhysicsCalculations.calculateDragForce(
            velocity: velocity,
            airplaneType: .basic,
            foldType: .basic
        )
        
        // Drag should oppose velocity direction
        XCTAssertLessThan(dragForce.dx, 0)
        XCTAssertLessThan(dragForce.dy, 0)
    }
    
    func testPhysicsCalculations_CalculateThrustForce_RespondsToInput() {
        let thrustForce = PhysicsCalculations.calculateThrustForce(
            tiltX: 0.5,
            tiltY: -0.3,
            airplaneType: .basic,
            foldType: .basic
        )
        
        // Thrust should respond to tilt input
        XCTAssertGreaterThan(thrustForce.dx, 0) // Positive tilt X
        XCTAssertLessThan(thrustForce.dy, 0) // Negative tilt Y
    }
    
    func testPhysicsCalculations_CalculateForwardThrust_DecreasesWithSpeed() {
        let lowSpeedThrust = PhysicsCalculations.calculateForwardThrust(
            airplaneType: .basic,
            currentSpeed: 50
        )
        
        let highSpeedThrust = PhysicsCalculations.calculateForwardThrust(
            airplaneType: .basic,
            currentSpeed: 300
        )
        
        // Thrust should decrease at higher speeds
        XCTAssertGreaterThan(lowSpeedThrust, highSpeedThrust)
    }
    
    func testPhysicsCalculations_CalculateStabilizationTorque_OnlyAtHighSpeed() {
        let velocity = CGVector(dx: 100, dy: 0)
        
        // Low speed - no stabilization
        let lowSpeedTorque = PhysicsCalculations.calculateStabilizationTorque(
            currentRotation: CGFloat.pi / 4,
            velocity: velocity,
            speed: 50,
            airplaneType: .basic
        )
        XCTAssertEqual(lowSpeedTorque, 0, accuracy: 0.01)
        
        // High speed - stabilization applied
        let highSpeedTorque = PhysicsCalculations.calculateStabilizationTorque(
            currentRotation: CGFloat.pi / 4,
            velocity: velocity,
            speed: 200,
            airplaneType: .basic
        )
        XCTAssertNotEqual(highSpeedTorque, 0)
    }
    
    func testPhysicsCalculations_CalculateWindForce_AppliesCorrectly() {
        let windVector = CGVector(dx: 10, dy: 5)
        let windForce = PhysicsCalculations.calculateWindForce(
            windVector: windVector,
            airplaneType: .basic,
            foldType: .basic
        )
        
        // Wind force should be in same direction as wind but reduced
        XCTAssertGreaterThan(windForce.dx, 0)
        XCTAssertGreaterThan(windForce.dy, 0)
        XCTAssertLessThan(windForce.dx, windVector.dx)
        XCTAssertLessThan(windForce.dy, windVector.dy)
    }
    
    func testPhysicsCalculations_CalculateBounceVelocity_ReflectsCorrectly() {
        let velocity = CGVector(dx: 100, dy: -50)
        let normal = CGVector(dx: 0, dy: 1) // Upward normal (ground collision)
        
        let bounceVelocity = PhysicsCalculations.calculateBounceVelocity(
            velocity: velocity,
            collisionNormal: normal,
            restitution: 0.5
        )
        
        // X component should remain similar, Y should reverse and reduce
        XCTAssertEqual(bounceVelocity.dx, velocity.dx * 0.5, accuracy: 1.0)
        XCTAssertGreaterThan(bounceVelocity.dy, 0) // Should bounce upward
    }
    
    func testPhysicsCalculations_NormalizeAngle_CorrectRange() {
        // Test angle normalization
        XCTAssertEqual(PhysicsCalculations.normalizeAngle(0), 0, accuracy: 0.01)
        XCTAssertEqual(PhysicsCalculations.normalizeAngle(CGFloat.pi), CGFloat.pi, accuracy: 0.01)
        XCTAssertEqual(PhysicsCalculations.normalizeAngle(-CGFloat.pi), -CGFloat.pi, accuracy: 0.01)
        
        // Test wrapping
        let wrappedAngle = PhysicsCalculations.normalizeAngle(3 * CGFloat.pi)
        XCTAssertEqual(wrappedAngle, -CGFloat.pi, accuracy: 0.01)
    }
    
    func testPhysicsCalculations_Distance_CalculatesCorrectly() {
        let point1 = CGPoint(x: 0, y: 0)
        let point2 = CGPoint(x: 3, y: 4)
        
        let distance = PhysicsCalculations.distance(from: point1, to: point2)
        XCTAssertEqual(distance, 5.0, accuracy: 0.01) // 3-4-5 triangle
    }
    
    func testPhysicsCalculations_Angle_CalculatesCorrectly() {
        let from = CGPoint(x: 0, y: 0)
        let to = CGPoint(x: 1, y: 1)
        
        let angle = PhysicsCalculations.angle(from: from, to: to)
        XCTAssertEqual(angle, CGFloat.pi / 4, accuracy: 0.01) // 45 degrees
    }
    
    // MARK: - ProgressionLogic Tests
    
    func testProgressionLogic_CalculateExperienceEarned_CorrectCalculation() {
        let xp = ProgressionLogic.calculateExperienceEarned(
            score: 1000,      // 10 XP
            distance: 500,    // 10 XP
            timeElapsed: 120, // 2 XP
            coinsCollected: 5, // 10 XP
            gameMode: .freePlay // 1.0x multiplier
        )
        
        XCTAssertEqual(xp, 32) // 10 + 10 + 2 + 10 = 32
    }
    
    func testProgressionLogic_CalculateExperienceEarned_AppliesGameModeMultiplier() {
        let baseXP = ProgressionLogic.calculateExperienceEarned(
            score: 1000, distance: 500, timeElapsed: 120, coinsCollected: 5, gameMode: .freePlay
        )
        
        let challengeXP = ProgressionLogic.calculateExperienceEarned(
            score: 1000, distance: 500, timeElapsed: 120, coinsCollected: 5, gameMode: .challenge
        )
        
        XCTAssertEqual(challengeXP, Int(Float(baseXP) * 1.5))
    }
    
    func testProgressionLogic_CalculateExperienceEarned_HasMinimumValue() {
        let xp = ProgressionLogic.calculateExperienceEarned(
            score: 0, distance: 0, timeElapsed: 0, coinsCollected: 0, gameMode: .tutorial
        )
        
        XCTAssertEqual(xp, 1) // Minimum XP
    }
    
    func testProgressionLogic_CalculateLevel_CorrectFormula() {
        XCTAssertEqual(ProgressionLogic.calculateLevel(from: 0), 1)
        XCTAssertEqual(ProgressionLogic.calculateLevel(from: 99), 1)
        XCTAssertEqual(ProgressionLogic.calculateLevel(from: 100), 2)
        XCTAssertEqual(ProgressionLogic.calculateLevel(from: 250), 3)
        XCTAssertEqual(ProgressionLogic.calculateLevel(from: 999), 10)
    }
    
    func testProgressionLogic_ExperienceRequiredForLevel_CorrectCalculation() {
        XCTAssertEqual(ProgressionLogic.experienceRequiredForLevel(1), 0)
        XCTAssertEqual(ProgressionLogic.experienceRequiredForLevel(2), 100)
        XCTAssertEqual(ProgressionLogic.experienceRequiredForLevel(5), 400)
        XCTAssertEqual(ProgressionLogic.experienceRequiredForLevel(10), 900)
    }
    
    func testProgressionLogic_ExperienceToNextLevel_CorrectCalculation() {
        XCTAssertEqual(ProgressionLogic.experienceToNextLevel(currentXP: 50), 50) // Need 50 more for level 2
        XCTAssertEqual(ProgressionLogic.experienceToNextLevel(currentXP: 150), 50) // Need 50 more for level 3
        XCTAssertEqual(ProgressionLogic.experienceToNextLevel(currentXP: 200), 0) // Already at level 3
    }
    
    func testProgressionLogic_ProgressToNextLevel_CorrectPercentage() {
        let progress = ProgressionLogic.progressToNextLevel(currentXP: 150)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01) // 50% progress to level 3
        
        let fullProgress = ProgressionLogic.progressToNextLevel(currentXP: 200)
        XCTAssertEqual(fullProgress, 1.0, accuracy: 0.01) // 100% progress (at next level)
    }
    
    func testProgressionLogic_GetUnlockedContentAtLevel_CorrectContent() {
        let level1Content = ProgressionLogic.getUnlockedContentAtLevel(1)
        XCTAssertTrue(level1Content.contains("airplane_basic"))
        XCTAssertTrue(level1Content.contains("fold_basic"))
        XCTAssertTrue(level1Content.contains("design_plain"))
        XCTAssertTrue(level1Content.contains("environment_standard"))
        
        let level5Content = ProgressionLogic.getUnlockedContentAtLevel(5)
        XCTAssertTrue(level5Content.contains("airplane_sturdy"))
        XCTAssertTrue(level5Content.contains("fold_glider"))
    }
    
    func testProgressionLogic_GetNewlyUnlockedContent_ReturnsOnlyNew() {
        let newContent = ProgressionLogic.getNewlyUnlockedContent(fromLevel: 2, toLevel: 3)
        
        // Should contain content unlocked at level 3
        XCTAssertTrue(newContent.contains("airplane_speedy"))
        XCTAssertTrue(newContent.contains("fold_dart"))
        
        // Should not contain content from earlier levels
        XCTAssertFalse(newContent.contains("airplane_basic"))
        XCTAssertFalse(newContent.contains("design_plain"))
    }
    
    func testProgressionLogic_CalculateStreakBonus_CorrectBonuses() {
        XCTAssertEqual(ProgressionLogic.calculateStreakBonus(streakDays: 1), 1.0, accuracy: 0.01)
        XCTAssertEqual(ProgressionLogic.calculateStreakBonus(streakDays: 5), 1.2, accuracy: 0.01)
        XCTAssertEqual(ProgressionLogic.calculateStreakBonus(streakDays: 10), 1.5, accuracy: 0.01)
        XCTAssertEqual(ProgressionLogic.calculateStreakBonus(streakDays: 20), 2.0, accuracy: 0.01)
        XCTAssertEqual(ProgressionLogic.calculateStreakBonus(streakDays: 35), 2.5, accuracy: 0.01)
    }
    
    func testProgressionLogic_CalculateWeeklySpecialBonus_CorrectCalculation() {
        let bonus = ProgressionLogic.calculateWeeklySpecialBonus(completionPercentage: 0.8)
        XCTAssertEqual(bonus, 400) // 80% of 500 base bonus
    }
    
    func testProgressionLogic_CalculateLeaderboardRank_CorrectRanking() {
        let allScores = [1000, 800, 600, 400, 200]
        
        XCTAssertEqual(ProgressionLogic.calculateLeaderboardRank(playerScore: 900, allScores: allScores), 2)
        XCTAssertEqual(ProgressionLogic.calculateLeaderboardRank(playerScore: 500, allScores: allScores), 4)
        XCTAssertEqual(ProgressionLogic.calculateLeaderboardRank(playerScore: 1200, allScores: allScores), 1)
        XCTAssertEqual(ProgressionLogic.calculateLeaderboardRank(playerScore: 100, allScores: allScores), 6)
    }
    
    func testProgressionLogic_CalculatePercentileRank_CorrectPercentile() {
        let allScores = [1000, 800, 600, 400, 200]
        
        let percentile = ProgressionLogic.calculatePercentileRank(playerScore: 700, allScores: allScores)
        XCTAssertEqual(percentile, 60.0, accuracy: 0.01) // Better than 3 out of 5 scores
    }
    
    func testProgressionLogic_GetDifficultyMultiplier_IncreasesWithLevel() {
        let level1Difficulty = ProgressionLogic.getDifficultyMultiplier(playerLevel: 1)
        let level5Difficulty = ProgressionLogic.getDifficultyMultiplier(playerLevel: 5)
        let level20Difficulty = ProgressionLogic.getDifficultyMultiplier(playerLevel: 20)
        
        XCTAssertEqual(level1Difficulty, 1.0, accuracy: 0.01)
        XCTAssertEqual(level5Difficulty, 1.4, accuracy: 0.01)
        XCTAssertEqual(level20Difficulty, 3.0, accuracy: 0.01) // Capped at 3.0
    }
    
    func testProgressionLogic_GetRecommendedChallengeLevel_AdjustsForPerformance() {
        let baseLevel = ProgressionLogic.getRecommendedChallengeLevel(playerLevel: 6, recentPerformance: 3000)
        let highPerformanceLevel = ProgressionLogic.getRecommendedChallengeLevel(playerLevel: 6, recentPerformance: 6000)
        let lowPerformanceLevel = ProgressionLogic.getRecommendedChallengeLevel(playerLevel: 6, recentPerformance: 1500)
        
        XCTAssertEqual(baseLevel, 3) // playerLevel / 2
        XCTAssertEqual(highPerformanceLevel, 4) // +1 for high performance
        XCTAssertEqual(lowPerformanceLevel, 2) // -1 for low performance
    }
}//
 MARK: - Additional Comprehensive Tests

extension BusinessLogicTests {
    
    // MARK: - GameRules Edge Cases and Error Handling
    
    func testGameRules_CanTransitionGameState_EdgeCases() {
        // Test with extreme player levels
        XCTAssertTrue(GameRules.canTransitionGameState(from: .notStarted, to: .playing, playerLevel: 0))
        XCTAssertTrue(GameRules.canTransitionGameState(from: .notStarted, to: .playing, playerLevel: 1000))
        
        // Test same state transitions
        XCTAssertFalse(GameRules.canTransitionGameState(from: .playing, to: .playing, playerLevel: 1))
        XCTAssertFalse(GameRules.canTransitionGameState(from: .paused, to: .paused, playerLevel: 1))
        XCTAssertFalse(GameRules.canTransitionGameState(from: .ended, to: .ended, playerLevel: 1))
    }
    
    func testGameRules_IsGameModeUnlocked_EdgeCases() {
        // Test with negative player level
        XCTAssertFalse(GameRules.isGameModeUnlocked(.tutorial, playerLevel: -1))
        XCTAssertFalse(GameRules.isGameModeUnlocked(.freePlay, playerLevel: 0))
        
        // Test with extremely high player level
        XCTAssertTrue(GameRules.isGameModeUnlocked(.weeklySpecial, playerLevel: 1000))
        
        // Test boundary conditions
        XCTAssertFalse(GameRules.isGameModeUnlocked(.challenge, playerLevel: 2))
        XCTAssertTrue(GameRules.isGameModeUnlocked(.challenge, playerLevel: 3))
        XCTAssertFalse(GameRules.isGameModeUnlocked(.dailyRun, playerLevel: 4))
        XCTAssertTrue(GameRules.isGameModeUnlocked(.dailyRun, playerLevel: 5))
    }
    
    func testGameRules_CalculateBaseScore_EdgeCases() {
        // Test with zero values
        XCTAssertEqual(GameRules.calculateBaseScore(distance: 0, time: 0, coins: 0), 0)
        
        // Test with negative values (should handle gracefully)
        XCTAssertGreaterThanOrEqual(GameRules.calculateBaseScore(distance: -100, time: -60, coins: -5), 0)
        
        // Test with extreme values
        let extremeScore = GameRules.calculateBaseScore(distance: 10000, time: 3600, coins: 100)
        XCTAssertGreaterThan(extremeScore, 0)
        XCTAssertLessThan(extremeScore, 1000000) // Should have reasonable upper bound
        
        // Test floating point precision
        let preciseScore = GameRules.calculateBaseScore(distance: 123.456, time: 67.89, coins: 7)
        XCTAssertGreaterThan(preciseScore, 0)
    }
    
    func testGameRules_ApplyObstaclePenalty_EdgeCases() {
        // Test with zero score
        XCTAssertEqual(GameRules.applyObstaclePenalty(currentScore: 0, obstacleType: .building), 0)
        
        // Test with negative score (should handle gracefully)
        XCTAssertEqual(GameRules.applyObstaclePenalty(currentScore: -100, obstacleType: .building), 0)
        
        // Test with very high score
        let highScore = 1000000
        let penalizedScore = GameRules.applyObstaclePenalty(currentScore: highScore, obstacleType: .building)
        XCTAssertLessThan(penalizedScore, highScore)
        XCTAssertGreaterThanOrEqual(penalizedScore, 0)
        
        // Test all obstacle types
        let testScore = 1000
        for obstacleType in [ObstacleType.building, .tree, .rock, .fence] {
            let result = GameRules.applyObstaclePenalty(currentScore: testScore, obstacleType: obstacleType)
            XCTAssertLessThan(result, testScore, "Penalty should reduce score for \(obstacleType)")
            XCTAssertGreaterThanOrEqual(result, 0, "Score should not go below zero for \(obstacleType)")
        }
    }
    
    func testGameRules_GetScoreMultiplier_Consistency() {
        // Test that multipliers are in logical order
        let tutorialMultiplier = GameRules.getScoreMultiplier(for: .tutorial)
        let freePlayMultiplier = GameRules.getScoreMultiplier(for: .freePlay)
        let challengeMultiplier = GameRules.getScoreMultiplier(for: .challenge)
        let dailyRunMultiplier = GameRules.getScoreMultiplier(for: .dailyRun)
        let weeklySpecialMultiplier = GameRules.getScoreMultiplier(for: .weeklySpecial)
        
        XCTAssertLessThan(tutorialMultiplier, freePlayMultiplier)
        XCTAssertLessThan(freePlayMultiplier, challengeMultiplier)
        XCTAssertLessThan(challengeMultiplier, dailyRunMultiplier)
        XCTAssertLessThan(dailyRunMultiplier, weeklySpecialMultiplier)
        
        // Test that all multipliers are positive
        XCTAssertGreaterThan(tutorialMultiplier, 0)
        XCTAssertGreaterThan(freePlayMultiplier, 0)
        XCTAssertGreaterThan(challengeMultiplier, 0)
        XCTAssertGreaterThan(dailyRunMultiplier, 0)
        XCTAssertGreaterThan(weeklySpecialMultiplier, 0)
    }
    
    func testGameRules_CanUnlockContent_InvalidInputs() {
        // Test with empty content ID
        XCTAssertFalse(GameRules.canUnlockContent(contentId: "", type: .airplane, playerLevel: 10, totalScore: 10000, completedChallenges: 10))
        
        // Test with negative values
        XCTAssertFalse(GameRules.canUnlockContent(contentId: "basic", type: .airplane, playerLevel: -1, totalScore: -1000, completedChallenges: -5))
        
        // Test with unknown content ID
        XCTAssertFalse(GameRules.canUnlockContent(contentId: "unknown_airplane", type: .airplane, playerLevel: 100, totalScore: 100000, completedChallenges: 100))
    }
    
    func testGameRules_CalculateDailyRunStreak_EdgeCases() {
        let calendar = Calendar.current
        let today = Date()
        
        // Test with future date (should handle gracefully)
        let futureDate = calendar.date(byAdding: .day, value: 1, to: today)!
        XCTAssertEqual(GameRules.calculateDailyRunStreak(lastRunDate: futureDate, currentStreak: 5), 1)
        
        // Test with very old date
        let veryOldDate = calendar.date(byAdding: .year, value: -1, to: today)!
        XCTAssertEqual(GameRules.calculateDailyRunStreak(lastRunDate: veryOldDate, currentStreak: 100), 1)
        
        // Test with negative current streak (should handle gracefully)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        XCTAssertGreaterThanOrEqual(GameRules.calculateDailyRunStreak(lastRunDate: yesterday, currentStreak: -5), 1)
    }
    
    func testGameRules_GetDailyRunStreakBonus_EdgeCases() {
        // Test with zero and negative streaks
        XCTAssertEqual(GameRules.getDailyRunStreakBonus(streak: 0), 1.0, accuracy: 0.01)
        XCTAssertEqual(GameRules.getDailyRunStreakBonus(streak: -5), 1.0, accuracy: 0.01)
        
        // Test with extremely high streak
        let extremeBonus = GameRules.getDailyRunStreakBonus(streak: 1000)
        XCTAssertGreaterThan(extremeBonus, 1.0)
        XCTAssertLessThan(extremeBonus, 10.0) // Should have reasonable upper bound
    }
    
    func testGameRules_IsChallengeCompleted_EdgeCases() {
        // Test with unknown challenge ID
        XCTAssertFalse(GameRules.isChallengeCompleted(challengeId: "unknown_challenge", score: 1000, distance: 500, time: 60, coins: 5))
        
        // Test with empty challenge ID
        XCTAssertFalse(GameRules.isChallengeCompleted(challengeId: "", score: 1000, distance: 500, time: 60, coins: 5))
        
        // Test with negative values
        XCTAssertFalse(GameRules.isChallengeCompleted(challengeId: "distance_500", score: -1000, distance: -500, time: -60, coins: -5))
        
        // Test boundary conditions
        XCTAssertTrue(GameRules.isChallengeCompleted(challengeId: "distance_500", score: 1000, distance: 500, time: 60, coins: 5))
        XCTAssertFalse(GameRules.isChallengeCompleted(challengeId: "distance_500", score: 1000, distance: 499, time: 60, coins: 5))
    }
    
    // MARK: - PhysicsCalculations Edge Cases and Error Handling
    
    func testPhysicsCalculations_CalculateLiftForce_EdgeCases() {
        // Test with zero velocity
        let zeroVelocity = CGVector(dx: 0, dy: 0)
        let zeroLift = PhysicsCalculations.calculateLiftForce(velocity: zeroVelocity, airplaneType: .basic, foldType: .basic)
        XCTAssertEqual(zeroLift.dx, 0, accuracy: 0.01)
        XCTAssertEqual(zeroLift.dy, 0, accuracy: 0.01)
        
        // Test with extreme velocity
        let extremeVelocity = CGVector(dx: 10000, dy: 10000)
        let extremeLift = PhysicsCalculations.calculateLiftForce(velocity: extremeVelocity, airplaneType: .basic, foldType: .basic)
        XCTAssertLessThan(abs(extremeLift.dx), 1000) // Should be clamped
        XCTAssertLessThan(abs(extremeLift.dy), 1000) // Should be clamped
        
        // Test with different airplane types
        let velocity = CGVector(dx: 100, dy: 0)
        let basicLift = PhysicsCalculations.calculateLiftForce(velocity: velocity, airplaneType: .basic, foldType: .basic)
        let speedyLift = PhysicsCalculations.calculateLiftForce(velocity: velocity, airplaneType: .speedy, foldType: .basic)
        let gliderLift = PhysicsCalculations.calculateLiftForce(velocity: velocity, airplaneType: .glider, foldType: .basic)
        
        // Different airplane types should produce different lift characteristics
        XCTAssertNotEqual(basicLift.dy, speedyLift.dy, accuracy: 0.01)
        XCTAssertNotEqual(basicLift.dy, gliderLift.dy, accuracy: 0.01)
    }
    
    func testPhysicsCalculations_CalculateDragForce_EdgeCases() {
        // Test with zero velocity
        let zeroVelocity = CGVector(dx: 0, dy: 0)
        let zeroDrag = PhysicsCalculations.calculateDragForce(velocity: zeroVelocity, airplaneType: .basic, foldType: .basic)
        XCTAssertEqual(zeroDrag.dx, 0, accuracy: 0.01)
        XCTAssertEqual(zeroDrag.dy, 0, accuracy: 0.01)
        
        // Test drag magnitude increases with velocity
        let lowVelocity = CGVector(dx: 50, dy: 0)
        let highVelocity = CGVector(dx: 200, dy: 0)
        
        let lowDrag = PhysicsCalculations.calculateDragForce(velocity: lowVelocity, airplaneType: .basic, foldType: .basic)
        let highDrag = PhysicsCalculations.calculateDragForce(velocity: highVelocity, airplaneType: .basic, foldType: .basic)
        
        let lowDragMagnitude = sqrt(lowDrag.dx * lowDrag.dx + lowDrag.dy * lowDrag.dy)
        let highDragMagnitude = sqrt(highDrag.dx * highDrag.dx + highDrag.dy * highDrag.dy)
        
        XCTAssertGreaterThan(highDragMagnitude, lowDragMagnitude)
    }
    
    func testPhysicsCalculations_CalculateThrustForce_EdgeCases() {
        // Test with zero tilt
        let zeroThrust = PhysicsCalculations.calculateThrustForce(tiltX: 0, tiltY: 0, airplaneType: .basic, foldType: .basic)
        XCTAssertEqual(zeroThrust.dx, 0, accuracy: 0.01)
        XCTAssertEqual(zeroThrust.dy, 0, accuracy: 0.01)
        
        // Test with extreme tilt values
        let extremeThrust = PhysicsCalculations.calculateThrustForce(tiltX: 100, tiltY: -100, airplaneType: .basic, foldType: .basic)
        XCTAssertLessThan(abs(extremeThrust.dx), 1000) // Should be clamped
        XCTAssertLessThan(abs(extremeThrust.dy), 1000) // Should be clamped
        
        // Test thrust direction consistency
        let rightThrust = PhysicsCalculations.calculateThrustForce(tiltX: 1, tiltY: 0, airplaneType: .basic, foldType: .basic)
        let leftThrust = PhysicsCalculations.calculateThrustForce(tiltX: -1, tiltY: 0, airplaneType: .basic, foldType: .basic)
        
        XCTAssertGreaterThan(rightThrust.dx, 0)
        XCTAssertLessThan(leftThrust.dx, 0)
    }
    
    func testPhysicsCalculations_CalculateForwardThrust_EdgeCases() {
        // Test with zero speed
        let zeroSpeedThrust = PhysicsCalculations.calculateForwardThrust(airplaneType: .basic, currentSpeed: 0)
        XCTAssertGreaterThan(zeroSpeedThrust, 0)
        
        // Test with negative speed (should handle gracefully)
        let negativeSpeedThrust = PhysicsCalculations.calculateForwardThrust(airplaneType: .basic, currentSpeed: -100)
        XCTAssertGreaterThanOrEqual(negativeSpeedThrust, 0)
        
        // Test with extremely high speed
        let highSpeedThrust = PhysicsCalculations.calculateForwardThrust(airplaneType: .basic, currentSpeed: 10000)
        XCTAssertGreaterThanOrEqual(highSpeedThrust, 0)
        XCTAssertLessThan(highSpeedThrust, 1000) // Should have reasonable upper bound
    }
    
    func testPhysicsCalculations_CalculateWindForce_EdgeCases() {
        // Test with zero wind
        let zeroWind = CGVector(dx: 0, dy: 0)
        let zeroWindForce = PhysicsCalculations.calculateWindForce(windVector: zeroWind, airplaneType: .basic, foldType: .basic)
        XCTAssertEqual(zeroWindForce.dx, 0, accuracy: 0.01)
        XCTAssertEqual(zeroWindForce.dy, 0, accuracy: 0.01)
        
        // Test with extreme wind
        let extremeWind = CGVector(dx: 10000, dy: 10000)
        let extremeWindForce = PhysicsCalculations.calculateWindForce(windVector: extremeWind, airplaneType: .basic, foldType: .basic)
        XCTAssertLessThan(abs(extremeWindForce.dx), 1000) // Should be clamped
        XCTAssertLessThan(abs(extremeWindForce.dy), 1000) // Should be clamped
        
        // Test wind force is proportional to wind strength
        let lightWind = CGVector(dx: 10, dy: 0)
        let strongWind = CGVector(dx: 50, dy: 0)
        
        let lightWindForce = PhysicsCalculations.calculateWindForce(windVector: lightWind, airplaneType: .basic, foldType: .basic)
        let strongWindForce = PhysicsCalculations.calculateWindForce(windVector: strongWind, airplaneType: .basic, foldType: .basic)
        
        XCTAssertGreaterThan(abs(strongWindForce.dx), abs(lightWindForce.dx))
    }
    
    func testPhysicsCalculations_CalculateBounceVelocity_EdgeCases() {
        // Test with zero velocity
        let zeroVelocity = CGVector(dx: 0, dy: 0)
        let normal = CGVector(dx: 0, dy: 1)
        let zeroBounce = PhysicsCalculations.calculateBounceVelocity(velocity: zeroVelocity, collisionNormal: normal, restitution: 0.5)
        XCTAssertEqual(zeroBounce.dx, 0, accuracy: 0.01)
        XCTAssertEqual(zeroBounce.dy, 0, accuracy: 0.01)
        
        // Test with zero restitution (no bounce)
        let velocity = CGVector(dx: 100, dy: -50)
        let noBounce = PhysicsCalculations.calculateBounceVelocity(velocity: velocity, collisionNormal: normal, restitution: 0)
        XCTAssertEqual(noBounce.dx, velocity.dx, accuracy: 1.0) // Parallel component unchanged
        XCTAssertEqual(noBounce.dy, 0, accuracy: 0.01) // Perpendicular component zeroed
        
        // Test with perfect restitution
        let perfectBounce = PhysicsCalculations.calculateBounceVelocity(velocity: velocity, collisionNormal: normal, restitution: 1.0)
        XCTAssertEqual(perfectBounce.dx, velocity.dx, accuracy: 1.0) // Parallel component unchanged
        XCTAssertEqual(perfectBounce.dy, -velocity.dy, accuracy: 1.0) // Perpendicular component reversed
        
        // Test with invalid restitution values
        let invalidBounce = PhysicsCalculations.calculateBounceVelocity(velocity: velocity, collisionNormal: normal, restitution: -0.5)
        XCTAssertNotEqual(invalidBounce.dx, CGFloat.nan)
        XCTAssertNotEqual(invalidBounce.dy, CGFloat.nan)
    }
    
    func testPhysicsCalculations_UtilityFunctions_EdgeCases() {
        // Test normalizeAngle with extreme values
        let extremeAngle = PhysicsCalculations.normalizeAngle(100 * CGFloat.pi)
        XCTAssertGreaterThanOrEqual(extremeAngle, -CGFloat.pi)
        XCTAssertLessThanOrEqual(extremeAngle, CGFloat.pi)
        
        // Test distance with same points
        let samePointDistance = PhysicsCalculations.distance(from: CGPoint(x: 5, y: 5), to: CGPoint(x: 5, y: 5))
        XCTAssertEqual(samePointDistance, 0, accuracy: 0.01)
        
        // Test angle with same points
        let samePointAngle = PhysicsCalculations.angle(from: CGPoint(x: 5, y: 5), to: CGPoint(x: 5, y: 5))
        XCTAssertEqual(samePointAngle, 0, accuracy: 0.01)
        
        // Test distance with extreme coordinates
        let extremeDistance = PhysicsCalculations.distance(from: CGPoint(x: -10000, y: -10000), to: CGPoint(x: 10000, y: 10000))
        XCTAssertGreaterThan(extremeDistance, 0)
        XCTAssertLessThan(extremeDistance, 100000) // Should be reasonable
    }
    
    // MARK: - ProgressionLogic Edge Cases and Error Handling
    
    func testProgressionLogic_CalculateExperienceEarned_EdgeCases() {
        // Test with all zero values
        let zeroXP = ProgressionLogic.calculateExperienceEarned(score: 0, distance: 0, timeElapsed: 0, coinsCollected: 0, gameMode: .freePlay)
        XCTAssertEqual(zeroXP, 1) // Minimum XP
        
        // Test with negative values (should handle gracefully)
        let negativeXP = ProgressionLogic.calculateExperienceEarned(score: -1000, distance: -500, timeElapsed: -120, coinsCollected: -5, gameMode: .freePlay)
        XCTAssertGreaterThanOrEqual(negativeXP, 1) // Should not go below minimum
        
        // Test with extreme values
        let extremeXP = ProgressionLogic.calculateExperienceEarned(score: 1000000, distance: 100000, timeElapsed: 36000, coinsCollected: 1000, gameMode: .weeklySpecial)
        XCTAssertGreaterThan(extremeXP, 0)
        XCTAssertLessThan(extremeXP, 1000000) // Should have reasonable upper bound
    }
    
    func testProgressionLogic_CalculateLevel_EdgeCases() {
        // Test with negative XP
        XCTAssertEqual(ProgressionLogic.calculateLevel(from: -100), 1)
        
        // Test with extremely high XP
        let highLevel = ProgressionLogic.calculateLevel(from: 1000000)
        XCTAssertGreaterThan(highLevel, 1)
        XCTAssertLessThan(highLevel, 10000) // Should have reasonable upper bound
        
        // Test level progression consistency
        for xp in stride(from: 0, through: 10000, by: 100) {
            let level = ProgressionLogic.calculateLevel(from: xp)
            XCTAssertGreaterThanOrEqual(level, 1, "Level should be at least 1 for XP: \(xp)")
        }
    }
    
    func testProgressionLogic_ExperienceRequiredForLevel_EdgeCases() {
        // Test with level 0 and negative levels
        XCTAssertEqual(ProgressionLogic.experienceRequiredForLevel(0), 0)
        XCTAssertEqual(ProgressionLogic.experienceRequiredForLevel(-5), 0)
        
        // Test with extremely high level
        let highLevelXP = ProgressionLogic.experienceRequiredForLevel(1000)
        XCTAssertGreaterThan(highLevelXP, 0)
        XCTAssertLessThan(highLevelXP, 10000000) // Should have reasonable upper bound
        
        // Test level progression is monotonic
        for level in 1...100 {
            let currentXP = ProgressionLogic.experienceRequiredForLevel(level)
            let nextXP = ProgressionLogic.experienceRequiredForLevel(level + 1)
            XCTAssertLessThan(currentXP, nextXP, "XP requirement should increase with level")
        }
    }
    
    func testProgressionLogic_ExperienceToNextLevel_EdgeCases() {
        // Test with XP exactly at level boundary
        let level2XP = ProgressionLogic.experienceRequiredForLevel(2)
        XCTAssertEqual(ProgressionLogic.experienceToNextLevel(currentXP: level2XP), 0)
        
        // Test with XP beyond maximum reasonable level
        let extremeXP = 1000000
        let toNext = ProgressionLogic.experienceToNextLevel(currentXP: extremeXP)
        XCTAssertGreaterThanOrEqual(toNext, 0)
        
        // Test with negative XP
        let negativeToNext = ProgressionLogic.experienceToNextLevel(currentXP: -100)
        XCTAssertGreaterThan(negativeToNext, 0)
    }
    
    func testProgressionLogic_ProgressToNextLevel_EdgeCases() {
        // Test with negative XP
        let negativeProgress = ProgressionLogic.progressToNextLevel(currentXP: -100)
        XCTAssertGreaterThanOrEqual(negativeProgress, 0.0)
        XCTAssertLessThanOrEqual(negativeProgress, 1.0)
        
        // Test with extremely high XP
        let extremeProgress = ProgressionLogic.progressToNextLevel(currentXP: 1000000)
        XCTAssertGreaterThanOrEqual(extremeProgress, 0.0)
        XCTAssertLessThanOrEqual(extremeProgress, 1.0)
        
        // Test progress is always between 0 and 1
        for xp in stride(from: 0, through: 10000, by: 50) {
            let progress = ProgressionLogic.progressToNextLevel(currentXP: xp)
            XCTAssertGreaterThanOrEqual(progress, 0.0, "Progress should be >= 0 for XP: \(xp)")
            XCTAssertLessThanOrEqual(progress, 1.0, "Progress should be <= 1 for XP: \(xp)")
        }
    }
    
    func testProgressionLogic_GetUnlockedContentAtLevel_EdgeCases() {
        // Test with level 0 and negative levels
        let level0Content = ProgressionLogic.getUnlockedContentAtLevel(0)
        XCTAssertTrue(level0Content.isEmpty)
        
        let negativeLevelContent = ProgressionLogic.getUnlockedContentAtLevel(-5)
        XCTAssertTrue(negativeLevelContent.isEmpty)
        
        // Test with extremely high level
        let highLevelContent = ProgressionLogic.getUnlockedContentAtLevel(1000)
        XCTAssertFalse(highLevelContent.isEmpty) // Should contain all unlockable content
        
        // Test content accumulation (higher levels should have more content)
        let level1Content = ProgressionLogic.getUnlockedContentAtLevel(1)
        let level10Content = ProgressionLogic.getUnlockedContentAtLevel(10)
        XCTAssertGreaterThan(level10Content.count, level1Content.count)
    }
    
    func testProgressionLogic_GetNewlyUnlockedContent_EdgeCases() {
        // Test with same from and to levels
        let sameLevel = ProgressionLogic.getNewlyUnlockedContent(fromLevel: 5, toLevel: 5)
        XCTAssertTrue(sameLevel.isEmpty)
        
        // Test with reverse levels (to < from)
        let reverseLevel = ProgressionLogic.getNewlyUnlockedContent(fromLevel: 10, toLevel: 5)
        XCTAssertTrue(reverseLevel.isEmpty)
        
        // Test with negative levels
        let negativeLevel = ProgressionLogic.getNewlyUnlockedContent(fromLevel: -5, toLevel: 3)
        XCTAssertFalse(negativeLevel.isEmpty) // Should contain content from level 1-3
        
        // Test with extremely high levels
        let extremeLevel = ProgressionLogic.getNewlyUnlockedContent(fromLevel: 100, toLevel: 1000)
        XCTAssertTrue(extremeLevel.isEmpty) // No new content at such high levels
    }
    
    func testProgressionLogic_CalculateStreakBonus_EdgeCases() {
        // Test with zero and negative streaks
        XCTAssertEqual(ProgressionLogic.calculateStreakBonus(streakDays: 0), 1.0, accuracy: 0.01)
        XCTAssertEqual(ProgressionLogic.calculateStreakBonus(streakDays: -10), 1.0, accuracy: 0.01)
        
        // Test bonus progression is monotonic
        for streak in 1...100 {
            let currentBonus = ProgressionLogic.calculateStreakBonus(streakDays: streak)
            let nextBonus = ProgressionLogic.calculateStreakBonus(streakDays: streak + 1)
            XCTAssertGreaterThanOrEqual(nextBonus, currentBonus, "Streak bonus should not decrease")
        }
        
        // Test extreme streak values
        let extremeBonus = ProgressionLogic.calculateStreakBonus(streakDays: 10000)
        XCTAssertGreaterThan(extremeBonus, 1.0)
        XCTAssertLessThan(extremeBonus, 100.0) // Should have reasonable upper bound
    }
    
    func testProgressionLogic_CalculateLeaderboardRank_EdgeCases() {
        // Test with empty scores array
        XCTAssertEqual(ProgressionLogic.calculateLeaderboardRank(playerScore: 1000, allScores: []), 1)
        
        // Test with single score
        XCTAssertEqual(ProgressionLogic.calculateLeaderboardRank(playerScore: 1000, allScores: [500]), 1)
        XCTAssertEqual(ProgressionLogic.calculateLeaderboardRank(playerScore: 300, allScores: [500]), 2)
        
        // Test with duplicate scores
        let duplicateScores = [1000, 1000, 800, 800, 600]
        XCTAssertEqual(ProgressionLogic.calculateLeaderboardRank(playerScore: 1000, allScores: duplicateScores), 1)
        XCTAssertEqual(ProgressionLogic.calculateLeaderboardRank(playerScore: 800, allScores: duplicateScores), 3)
        
        // Test with negative scores
        let negativeScores = [100, 0, -100, -200]
        XCTAssertEqual(ProgressionLogic.calculateLeaderboardRank(playerScore: 50, allScores: negativeScores), 2)
    }
    
    func testProgressionLogic_CalculatePercentileRank_EdgeCases() {
        // Test with empty scores array
        XCTAssertEqual(ProgressionLogic.calculatePercentileRank(playerScore: 1000, allScores: []), 100.0, accuracy: 0.01)
        
        // Test with single score
        XCTAssertEqual(ProgressionLogic.calculatePercentileRank(playerScore: 1000, allScores: [500]), 100.0, accuracy: 0.01)
        XCTAssertEqual(ProgressionLogic.calculatePercentileRank(playerScore: 300, allScores: [500]), 0.0, accuracy: 0.01)
        
        // Test with all same scores
        let sameScores = [500, 500, 500, 500, 500]
        XCTAssertEqual(ProgressionLogic.calculatePercentileRank(playerScore: 500, allScores: sameScores), 50.0, accuracy: 0.01)
        
        // Test percentile is always between 0 and 100
        let testScores = [1000, 800, 600, 400, 200]
        for score in [0, 300, 500, 700, 900, 1200] {
            let percentile = ProgressionLogic.calculatePercentileRank(playerScore: score, allScores: testScores)
            XCTAssertGreaterThanOrEqual(percentile, 0.0, "Percentile should be >= 0 for score: \(score)")
            XCTAssertLessThanOrEqual(percentile, 100.0, "Percentile should be <= 100 for score: \(score)")
        }
    }
    
    func testProgressionLogic_GetDifficultyMultiplier_EdgeCases() {
        // Test with level 0 and negative levels
        XCTAssertEqual(ProgressionLogic.getDifficultyMultiplier(playerLevel: 0), 1.0, accuracy: 0.01)
        XCTAssertEqual(ProgressionLogic.getDifficultyMultiplier(playerLevel: -5), 1.0, accuracy: 0.01)
        
        // Test difficulty progression is monotonic up to cap
        for level in 1...50 {
            let currentDifficulty = ProgressionLogic.getDifficultyMultiplier(playerLevel: level)
            let nextDifficulty = ProgressionLogic.getDifficultyMultiplier(playerLevel: level + 1)
            XCTAssertGreaterThanOrEqual(nextDifficulty, currentDifficulty, "Difficulty should not decrease with level")
        }
        
        // Test difficulty cap
        let highLevelDifficulty = ProgressionLogic.getDifficultyMultiplier(playerLevel: 1000)
        XCTAssertLessThanOrEqual(highLevelDifficulty, 5.0) // Should have reasonable upper bound
    }
    
    func testProgressionLogic_GetRecommendedChallengeLevel_EdgeCases() {
        // Test with level 0 and negative levels
        XCTAssertGreaterThanOrEqual(ProgressionLogic.getRecommendedChallengeLevel(playerLevel: 0, recentPerformance: 1000), 1)
        XCTAssertGreaterThanOrEqual(ProgressionLogic.getRecommendedChallengeLevel(playerLevel: -5, recentPerformance: 1000), 1)
        
        // Test with negative performance
        let negativePerformance = ProgressionLogic.getRecommendedChallengeLevel(playerLevel: 10, recentPerformance: -1000)
        XCTAssertGreaterThanOrEqual(negativePerformance, 1)
        
        // Test with extremely high performance
        let extremePerformance = ProgressionLogic.getRecommendedChallengeLevel(playerLevel: 10, recentPerformance: 1000000)
        XCTAssertGreaterThan(extremePerformance, 5) // Should increase challenge level
        XCTAssertLessThan(extremePerformance, 100) // Should have reasonable upper bound
        
        // Test recommended level is always positive
        for level in 1...20 {
            for performance in [0, 1000, 5000, 10000] {
                let recommended = ProgressionLogic.getRecommendedChallengeLevel(playerLevel: level, recentPerformance: performance)
                XCTAssertGreaterThanOrEqual(recommended, 1, "Recommended level should be at least 1")
            }
        }
    }
}