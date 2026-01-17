import XCTest
import SwiftData
@testable import Tiny_Pilots

/// Unit tests for SwiftData models
class SwiftDataModelTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory container for testing
        do {
            let schema = Schema([
                PlayerData.self,
                GameResult.self,
                Achievement.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            context = ModelContext(container)
        } catch {
            XCTFail("Failed to create test container: \(error)")
        }
    }
    
    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }
    
    // MARK: - PlayerData Tests
    
    func testPlayerData_Initialization_SetsDefaultValues() {
        // When
        let player = PlayerData()
        
        // Then
        XCTAssertEqual(player.level, 1, "Default level should be 1")
        XCTAssertEqual(player.experiencePoints, 0, "Default XP should be 0")
        XCTAssertEqual(player.totalScore, 0, "Default total score should be 0")
        XCTAssertEqual(player.totalDistance, 0, accuracy: 0.01, "Default total distance should be 0")
        XCTAssertEqual(player.dailyRunStreak, 0, "Default daily run streak should be 0")
        XCTAssertEqual(player.unlockedAirplanes, ["basic"], "Should have basic airplane unlocked by default")
        XCTAssertEqual(player.unlockedEnvironments, ["standard"], "Should have standard environment unlocked by default")
        XCTAssertEqual(player.selectedFoldType, "basic", "Default fold type should be basic")
        XCTAssertEqual(player.selectedDesignType, "plain", "Default design type should be plain")
        XCTAssertNotNil(player.id, "ID should be set")
        XCTAssertNotNil(player.createdAt, "Created date should be set")
        XCTAssertNotNil(player.lastPlayedAt, "Last played date should be set")
    }
    
    func testPlayerData_AddExperience_UpdatesXPAndLevel() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        // When
        player.addExperience(150)
        
        // Then
        XCTAssertEqual(player.experiencePoints, 150, "XP should be updated")
        XCTAssertEqual(player.level, 2, "Level should increase to 2 (150 XP = level 2)")
        
        // When - add more XP
        player.addExperience(250) // Total: 400 XP
        
        // Then
        XCTAssertEqual(player.experiencePoints, 400, "XP should be cumulative")
        XCTAssertEqual(player.level, 5, "Level should be 5 (400 XP = level 5)")
    }
    
    func testPlayerData_UnlockContent_AddsToUnlockedArrays() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        // When
        player.unlockContent("speedy", type: .airplane)
        player.unlockContent("alpine", type: .environment)
        
        // Then
        XCTAssertTrue(player.unlockedAirplanes.contains("speedy"), "Speedy airplane should be unlocked")
        XCTAssertTrue(player.unlockedEnvironments.contains("alpine"), "Alpine environment should be unlocked")
    }
    
    func testPlayerData_UnlockContent_DoesNotAddDuplicates() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        // When
        player.unlockContent("basic", type: .airplane) // Already unlocked by default
        
        // Then
        let basicCount = player.unlockedAirplanes.filter { $0 == "basic" }.count
        XCTAssertEqual(basicCount, 1, "Should not have duplicate entries")
    }
    
    func testPlayerData_IsContentUnlocked_ReturnsCorrectStatus() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        // Then
        XCTAssertTrue(player.isContentUnlocked("basic", type: .airplane), "Basic airplane should be unlocked by default")
        XCTAssertFalse(player.isContentUnlocked("speedy", type: .airplane), "Speedy airplane should not be unlocked initially")
        
        // When
        player.unlockContent("speedy", type: .airplane)
        
        // Then
        XCTAssertTrue(player.isContentUnlocked("speedy", type: .airplane), "Speedy airplane should be unlocked after unlocking")
    }
    
    func testPlayerData_UpdateDailyRunStreak_HandlesConsecutiveDays() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        // When - first daily run
        player.updateDailyRunStreak()
        
        // Then
        XCTAssertEqual(player.dailyRunStreak, 1, "First daily run should set streak to 1")
        XCTAssertNotNil(player.lastDailyRunDate, "Last daily run date should be set")
        
        // When - simulate next day
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        player.lastDailyRunDate = yesterday
        player.updateDailyRunStreak()
        
        // Then
        XCTAssertEqual(player.dailyRunStreak, 2, "Consecutive day should increase streak")
    }
    
    func testPlayerData_UpdateDailyRunStreak_ResetsAfterMissedDay() {
        // Given
        let player = PlayerData()
        player.dailyRunStreak = 5
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        player.lastDailyRunDate = threeDaysAgo
        context.insert(player)
        
        // When
        player.updateDailyRunStreak()
        
        // Then
        XCTAssertEqual(player.dailyRunStreak, 1, "Streak should reset to 1 after missing days")
    }
    
    // MARK: - GameResult Tests
    
    func testGameResult_Initialization_SetsValues() {
        // When
        let result = GameResult(
            mode: "freePlay",
            score: 1500,
            distance: 2500.5,
            timeElapsed: 120.0,
            coinsCollected: 15,
            environmentType: "alpine"
        )
        
        // Then
        XCTAssertEqual(result.mode, "freePlay", "Mode should be set")
        XCTAssertEqual(result.score, 1500, "Score should be set")
        XCTAssertEqual(result.distance, 2500.5, accuracy: 0.01, "Distance should be set")
        XCTAssertEqual(result.timeElapsed, 120.0, accuracy: 0.01, "Time elapsed should be set")
        XCTAssertEqual(result.coinsCollected, 15, "Coins collected should be set")
        XCTAssertEqual(result.environmentType, "alpine", "Environment type should be set")
        XCTAssertNotNil(result.id, "ID should be set")
        XCTAssertNotNil(result.completedAt, "Completed date should be set")
    }
    
    func testGameResult_ExperienceEarned_CalculatesCorrectly() {
        // Given
        let result = GameResult(
            mode: "freePlay",
            score: 1000,      // 10 XP (1000/100)
            distance: 500,    // 10 XP (500/50)
            timeElapsed: 180, // 3 XP (180/60)
            coinsCollected: 5, // 10 XP (5*2)
            environmentType: "standard"
        )
        
        // When
        let xp = result.experienceEarned
        
        // Then
        XCTAssertEqual(xp, 33, "Experience should be 33 (10+10+3+10)")
    }
    
    func testGameResult_ExperienceEarned_HasMinimumValue() {
        // Given
        let result = GameResult(
            mode: "freePlay",
            score: 0,
            distance: 0,
            timeElapsed: 0,
            coinsCollected: 0,
            environmentType: "standard"
        )
        
        // When
        let xp = result.experienceEarned
        
        // Then
        XCTAssertEqual(xp, 1, "Experience should have minimum value of 1")
    }
    
    func testGameResult_IsPersonalBest_ReturnsCorrectValue() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        let oldResult = GameResult(mode: "freePlay", score: 1000, distance: 500, timeElapsed: 60, coinsCollected: 5, environmentType: "standard")
        oldResult.player = player
        context.insert(oldResult)
        
        let newResult = GameResult(mode: "freePlay", score: 1500, distance: 600, timeElapsed: 90, coinsCollected: 8, environmentType: "standard")
        
        // When
        let isPersonalBest = newResult.isPersonalBest(for: player)
        
        // Then
        XCTAssertTrue(isPersonalBest, "New result with higher score should be personal best")
    }
    
    func testGameResult_GetRank_CalculatesCorrectly() {
        // Given
        let results = [
            GameResult(mode: "freePlay", score: 2000, distance: 500, timeElapsed: 60, coinsCollected: 5, environmentType: "standard"),
            GameResult(mode: "freePlay", score: 1500, distance: 500, timeElapsed: 60, coinsCollected: 5, environmentType: "standard"),
            GameResult(mode: "freePlay", score: 1000, distance: 500, timeElapsed: 60, coinsCollected: 5, environmentType: "standard")
        ]
        
        let testResult = GameResult(mode: "freePlay", score: 1200, distance: 500, timeElapsed: 60, coinsCollected: 5, environmentType: "standard")
        
        // When
        let rank = testResult.getRank(among: results)
        
        // Then
        XCTAssertEqual(rank, 3, "Result with score 1200 should rank 3rd among the given results")
    }
    
    // MARK: - Achievement Tests
    
    func testAchievement_Initialization_SetsValues() {
        // When
        let achievement = Achievement(
            id: "test_achievement",
            title: "Test Achievement",
            description: "A test achievement",
            targetValue: 100,
            category: "test",
            iconName: "star",
            rewardXP: 50
        )
        
        // Then
        XCTAssertEqual(achievement.id, "test_achievement", "ID should be set")
        XCTAssertEqual(achievement.title, "Test Achievement", "Title should be set")
        XCTAssertEqual(achievement.description, "A test achievement", "Description should be set")
        XCTAssertEqual(achievement.targetValue, 100, accuracy: 0.01, "Target value should be set")
        XCTAssertEqual(achievement.category, "test", "Category should be set")
        XCTAssertEqual(achievement.iconName, "star", "Icon name should be set")
        XCTAssertEqual(achievement.rewardXP, 50, "Reward XP should be set")
        XCTAssertFalse(achievement.isUnlocked, "Should not be unlocked initially")
        XCTAssertEqual(achievement.progress, 0, accuracy: 0.01, "Progress should be 0 initially")
    }
    
    func testAchievement_UpdateProgress_UpdatesValue() {
        // Given
        let achievement = Achievement(id: "test", title: "Test", description: "Test", targetValue: 100)
        context.insert(achievement)
        
        // When
        let wasUnlocked = achievement.updateProgress(50)
        
        // Then
        XCTAssertEqual(achievement.progress, 50, accuracy: 0.01, "Progress should be updated")
        XCTAssertFalse(wasUnlocked, "Should not be unlocked at 50% progress")
        XCTAssertFalse(achievement.isUnlocked, "Achievement should not be unlocked")
    }
    
    func testAchievement_UpdateProgress_UnlocksWhenComplete() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        let achievement = Achievement(id: "test", title: "Test", description: "Test", targetValue: 100)
        achievement.player = player
        context.insert(achievement)
        
        // When
        let wasUnlocked = achievement.updateProgress(100)
        
        // Then
        XCTAssertTrue(wasUnlocked, "Should return true when unlocked")
        XCTAssertTrue(achievement.isUnlocked, "Achievement should be unlocked")
        XCTAssertNotNil(achievement.unlockedAt, "Unlocked date should be set")
        XCTAssertEqual(achievement.progress, 100, accuracy: 0.01, "Progress should be at target value")
    }
    
    func testAchievement_UpdateProgress_DoesNotExceedTarget() {
        // Given
        let achievement = Achievement(id: "test", title: "Test", description: "Test", targetValue: 100)
        context.insert(achievement)
        
        // When
        achievement.updateProgress(150)
        
        // Then
        XCTAssertEqual(achievement.progress, 100, accuracy: 0.01, "Progress should not exceed target value")
    }
    
    func testAchievement_UpdateProgress_IgnoresWhenAlreadyUnlocked() {
        // Given
        let achievement = Achievement(id: "test", title: "Test", description: "Test", targetValue: 100)
        achievement.updateProgress(100) // Unlock it
        context.insert(achievement)
        
        // When
        let wasUnlocked = achievement.updateProgress(50) // Try to update after unlocking
        
        // Then
        XCTAssertFalse(wasUnlocked, "Should return false when already unlocked")
        XCTAssertEqual(achievement.progress, 100, accuracy: 0.01, "Progress should remain at target value")
    }
    
    func testAchievement_ProgressPercentage_CalculatesCorrectly() {
        // Given
        let achievement = Achievement(id: "test", title: "Test", description: "Test", targetValue: 200)
        achievement.updateProgress(50)
        
        // When
        let percentage = achievement.progressPercentage
        
        // Then
        XCTAssertEqual(percentage, 0.25, accuracy: 0.01, "Progress percentage should be 0.25 (25%)")
    }
    
    func testAchievement_ProgressString_FormatsCorrectly() {
        // Given
        let achievement = Achievement(id: "test", title: "Test", description: "Test", targetValue: 200)
        achievement.updateProgress(50)
        
        // When
        let progressString = achievement.progressString
        
        // Then
        XCTAssertEqual(progressString, "25%", "Progress string should be formatted as percentage")
    }
    
    func testAchievement_IsNearCompletion_ReturnsCorrectValue() {
        // Given
        let achievement = Achievement(id: "test", title: "Test", description: "Test", targetValue: 100)
        
        // When & Then
        achievement.updateProgress(70)
        XCTAssertFalse(achievement.isNearCompletion, "Should not be near completion at 70%")
        
        achievement.updateProgress(85)
        XCTAssertTrue(achievement.isNearCompletion, "Should be near completion at 85%")
    }
    
    // MARK: - Business Rule Validation Tests
    
    func testPlayerData_ValidateSelectedAirplane_ReturnsCorrectValue() {
        // Given
        let player = PlayerData()
        player.unlockContent("speedy", type: .airplane)
        context.insert(player)
        
        // Then
        XCTAssertTrue(player.validateSelectedAirplane("basic"), "Basic airplane should be valid (unlocked by default)")
        XCTAssertTrue(player.validateSelectedAirplane("speedy"), "Speedy airplane should be valid (unlocked)")
        XCTAssertFalse(player.validateSelectedAirplane("premium"), "Premium airplane should be invalid (not unlocked)")
    }
    
    func testPlayerData_ValidateSelectedEnvironment_ReturnsCorrectValue() {
        // Given
        let player = PlayerData()
        player.unlockContent("alpine", type: .environment)
        context.insert(player)
        
        // Then
        XCTAssertTrue(player.validateSelectedEnvironment("standard"), "Standard environment should be valid (unlocked by default)")
        XCTAssertTrue(player.validateSelectedEnvironment("alpine"), "Alpine environment should be valid (unlocked)")
        XCTAssertFalse(player.validateSelectedEnvironment("desert"), "Desert environment should be invalid (not unlocked)")
    }
    
    func testPlayerData_ValidateFoldType_ReturnsCorrectValue() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        // Then
        XCTAssertTrue(player.validateFoldType("basic"), "Basic fold type should be valid")
        XCTAssertTrue(player.validateFoldType("dart"), "Dart fold type should be valid")
        XCTAssertTrue(player.validateFoldType("glider"), "Glider fold type should be valid")
        XCTAssertTrue(player.validateFoldType("stunt"), "Stunt fold type should be valid")
        XCTAssertTrue(player.validateFoldType("heavy"), "Heavy fold type should be valid")
        XCTAssertFalse(player.validateFoldType("invalid"), "Invalid fold type should be invalid")
    }
    
    func testPlayerData_ValidateDesignType_ReturnsCorrectValue() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        // Then
        XCTAssertTrue(player.validateDesignType("plain"), "Plain design type should be valid")
        XCTAssertTrue(player.validateDesignType("striped"), "Striped design type should be valid")
        XCTAssertTrue(player.validateDesignType("dotted"), "Dotted design type should be valid")
        XCTAssertTrue(player.validateDesignType("rainbow"), "Rainbow design type should be valid")
        XCTAssertTrue(player.validateDesignType("metallic"), "Metallic design type should be valid")
        XCTAssertFalse(player.validateDesignType("invalid"), "Invalid design type should be invalid")
    }
    
    func testPlayerData_UpdateSelectedAirplane_ValidatesAndUpdates() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        // When - valid update
        let success = player.updateSelectedAirplane(foldType: "dart", designType: "striped")
        
        // Then
        XCTAssertTrue(success, "Update should succeed with valid types")
        XCTAssertEqual(player.selectedFoldType, "dart", "Fold type should be updated")
        XCTAssertEqual(player.selectedDesignType, "striped", "Design type should be updated")
        
        // When - invalid update
        let failure = player.updateSelectedAirplane(foldType: "invalid", designType: "plain")
        
        // Then
        XCTAssertFalse(failure, "Update should fail with invalid fold type")
        XCTAssertEqual(player.selectedFoldType, "dart", "Fold type should remain unchanged")
        XCTAssertEqual(player.selectedDesignType, "striped", "Design type should remain unchanged")
    }
    
    func testPlayerData_AddGameResult_UpdatesStatistics() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        let initialXP = player.experiencePoints
        let initialScore = player.totalScore
        let initialDistance = player.totalDistance
        let initialFlightTime = player.totalFlightTime
        let initialHighScore = player.highScore
        
        let result = GameResult(
            mode: "freePlay",
            score: 1500,
            distance: 2000.5,
            timeElapsed: 120.0,
            coinsCollected: 10,
            environmentType: "alpine"
        )
        
        // When
        player.addGameResult(result)
        
        // Then
        XCTAssertEqual(result.player, player, "Result should be associated with player")
        XCTAssertTrue(player.gameResults.contains(result), "Player should contain the result")
        XCTAssertEqual(player.totalScore, initialScore + 1500, "Total score should be updated")
        XCTAssertEqual(player.totalDistance, initialDistance + 2000.5, accuracy: 0.01, "Total distance should be updated")
        XCTAssertEqual(player.totalFlightTime, initialFlightTime + 120.0, accuracy: 0.01, "Total flight time should be updated")
        XCTAssertEqual(player.highScore, 1500, "High score should be updated")
        XCTAssertGreaterThan(player.experiencePoints, initialXP, "Experience should be increased")
    }
    
    func testPlayerData_ExperienceToNextLevel_CalculatesCorrectly() {
        // Given
        let player = PlayerData()
        player.addExperience(150) // Level 2, 150 XP
        context.insert(player)
        
        // When
        let xpToNext = player.experienceToNextLevel
        
        // Then
        XCTAssertEqual(xpToNext, 50, "Should need 50 XP to reach level 3 (200 XP total)")
    }
    
    func testPlayerData_LevelProgress_CalculatesCorrectly() {
        // Given
        let player = PlayerData()
        player.addExperience(150) // Level 2, 150 XP (50% through level 2)
        context.insert(player)
        
        // When
        let progress = player.levelProgress
        
        // Then
        XCTAssertEqual(progress, 0.5, accuracy: 0.01, "Should be 50% through current level")
    }
    
    func testPlayerData_CanUnlockContent_ReturnsCorrectValue() {
        // Given
        let player = PlayerData()
        player.addExperience(250) // Level 3
        context.insert(player)
        
        // Then
        XCTAssertTrue(player.canUnlockContent("speedy", type: .airplane, requiredLevel: 2), "Should be able to unlock content at lower level requirement")
        XCTAssertTrue(player.canUnlockContent("premium", type: .airplane, requiredLevel: 3), "Should be able to unlock content at current level")
        XCTAssertFalse(player.canUnlockContent("elite", type: .airplane, requiredLevel: 5), "Should not be able to unlock content above current level")
        XCTAssertFalse(player.canUnlockContent("basic", type: .airplane, requiredLevel: 1), "Should not be able to unlock already unlocked content")
    }
    
    func testPlayerData_StatisticsSummary_ReturnsCorrectData() {
        // Given
        let player = PlayerData()
        player.addExperience(250) // Level 3
        
        let result1 = GameResult(mode: "freePlay", score: 1000, distance: 500, timeElapsed: 60, coinsCollected: 5, environmentType: "standard")
        let result2 = GameResult(mode: "challenge", score: 2000, distance: 800, timeElapsed: 120, coinsCollected: 10, environmentType: "alpine")
        
        player.addGameResult(result1)
        player.addGameResult(result2)
        
        let achievement = Achievement(id: "test", title: "Test", description: "Test", targetValue: 100)
        achievement.player = player
        achievement.updateProgress(100) // Unlock it
        
        context.insert(player)
        context.insert(achievement)
        
        // When
        let stats = player.statisticsSummary
        
        // Then
        XCTAssertEqual(stats.level, player.level, "Level should match")
        XCTAssertEqual(stats.gamesPlayed, 2, "Games played should be 2")
        XCTAssertEqual(stats.averageScore, 1500, "Average score should be 1500 ((1000+2000)/2)")
        XCTAssertEqual(stats.averageDistance, 650, accuracy: 0.01, "Average distance should be 650 ((500+800)/2)")
        XCTAssertEqual(stats.achievementsUnlocked, 1, "Should have 1 unlocked achievement")
    }
    
    func testPlayerData_ValidateDataIntegrity_DetectsErrors() {
        // Given
        let player = PlayerData()
        
        // Manually set invalid values to test validation
        player.level = -1
        player.experiencePoints = -100
        player.totalScore = -500
        player.selectedFoldType = "invalid"
        player.unlockedAirplanes = [] // Remove default unlocked content
        
        context.insert(player)
        
        // When
        let errors = player.validateDataIntegrity()
        
        // Then
        XCTAssertFalse(errors.isEmpty, "Should detect validation errors")
        XCTAssertTrue(errors.contains { $0.contains("Invalid level") }, "Should detect invalid level")
        XCTAssertTrue(errors.contains { $0.contains("Negative experience") }, "Should detect negative experience")
        XCTAssertTrue(errors.contains { $0.contains("Negative total score") }, "Should detect negative total score")
        XCTAssertTrue(errors.contains { $0.contains("not valid") }, "Should detect invalid fold type")
        XCTAssertTrue(errors.contains { $0.contains("No unlocked airplanes") }, "Should detect missing unlocked content")
    }
    
    func testPlayerData_ValidationMethods_EnforceBusinessRules() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        // Test setLevel validation
        XCTAssertFalse(player.setLevel(-5), "Should reject negative level")
        XCTAssertFalse(player.setLevel(1000), "Should reject level above cap")
        XCTAssertTrue(player.setLevel(10), "Should accept valid level")
        XCTAssertEqual(player.level, 10, "Level should be updated")
        
        // Test setExperiencePoints validation
        XCTAssertFalse(player.setExperiencePoints(-100), "Should reject negative experience")
        XCTAssertTrue(player.setExperiencePoints(500), "Should accept valid experience")
        XCTAssertEqual(player.experiencePoints, 500, "Experience should be updated")
        
        // Test addToTotalScore validation
        XCTAssertFalse(player.addToTotalScore(-1000), "Should reject negative score addition")
        XCTAssertTrue(player.addToTotalScore(1500), "Should accept positive score addition")
        XCTAssertEqual(player.totalScore, 1500, "Total score should be updated")
        
        // Test addToTotalDistance validation
        XCTAssertFalse(player.addToTotalDistance(-500.0), "Should reject negative distance addition")
        XCTAssertTrue(player.addToTotalDistance(1000.5), "Should accept positive distance addition")
        XCTAssertEqual(player.totalDistance, 1000.5, accuracy: 0.01, "Total distance should be updated")
        
        // Test addToTotalFlightTime validation
        XCTAssertFalse(player.addToTotalFlightTime(-60.0), "Should reject negative time addition")
        XCTAssertTrue(player.addToTotalFlightTime(120.0), "Should accept positive time addition")
        XCTAssertEqual(player.totalFlightTime, 120.0, accuracy: 0.01, "Total flight time should be updated")
        
        // Test setHighScore validation
        XCTAssertFalse(player.setHighScore(-2000), "Should reject negative high score")
        XCTAssertTrue(player.setHighScore(3000), "Should accept valid high score")
        XCTAssertEqual(player.highScore, 3000, "High score should be updated")
        
        // Test that high score only increases
        XCTAssertTrue(player.setHighScore(2500), "Should accept lower score call")
        XCTAssertEqual(player.highScore, 3000, "High score should remain at higher value")
        
        XCTAssertTrue(player.setHighScore(3500), "Should accept higher score")
        XCTAssertEqual(player.highScore, 3500, "High score should be updated to higher value")
    }
    
    func testPlayerData_AddExperience_ValidatesInput() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        let initialXP = player.experiencePoints
        let initialLevel = player.level
        
        // When - try to add negative experience
        player.addExperience(-50)
        
        // Then - should not change
        XCTAssertEqual(player.experiencePoints, initialXP, "Experience should not change with negative input")
        XCTAssertEqual(player.level, initialLevel, "Level should not change with negative input")
        
        // When - add valid experience
        player.addExperience(150)
        
        // Then - should update correctly
        XCTAssertEqual(player.experiencePoints, 150, "Experience should be updated")
        XCTAssertEqual(player.level, 2, "Level should be updated based on experience")
    }
    
    // MARK: - SwiftData Query Tests
    
    func testPlayerData_SwiftDataQueries_WorkCorrectly() {
        // Given
        let player1 = PlayerData()
        player1.addExperience(100) // Level 2
        
        let player2 = PlayerData()
        player2.addExperience(300) // Level 4
        
        context.insert(player1)
        context.insert(player2)
        
        do {
            try context.save()
            
            // When - query for players above level 2
            let descriptor = FetchDescriptor<PlayerData>(
                predicate: #Predicate { $0.level > 2 }
            )
            let highLevelPlayers = try context.fetch(descriptor)
            
            // Then
            XCTAssertEqual(highLevelPlayers.count, 1, "Should find 1 player above level 2")
            XCTAssertEqual(highLevelPlayers.first?.level, 4, "Found player should be level 4")
            
            // When - query for players with specific unlocked content
            let airplaneDescriptor = FetchDescriptor<PlayerData>(
                predicate: #Predicate { player in
                    player.unlockedAirplanes.contains("basic")
                }
            )
            let playersWithBasic = try context.fetch(airplaneDescriptor)
            
            // Then
            XCTAssertEqual(playersWithBasic.count, 2, "Both players should have basic airplane unlocked")
            
        } catch {
            XCTFail("SwiftData query failed: \(error)")
        }
    }
    
    // MARK: - Relationship Tests
    
    func testPlayerData_GameResults_Relationship() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        let result1 = GameResult(mode: "freePlay", score: 1000, distance: 500, timeElapsed: 60, coinsCollected: 5, environmentType: "standard")
        let result2 = GameResult(mode: "challenge", score: 1500, distance: 600, timeElapsed: 90, coinsCollected: 8, environmentType: "alpine")
        
        result1.player = player
        result2.player = player
        
        context.insert(result1)
        context.insert(result2)
        
        // When
        try? context.save()
        
        // Then
        XCTAssertEqual(player.gameResults.count, 2, "Player should have 2 game results")
        XCTAssertTrue(player.gameResults.contains(result1), "Player should contain result1")
        XCTAssertTrue(player.gameResults.contains(result2), "Player should contain result2")
    }
    
    func testPlayerData_Achievements_Relationship() {
        // Given
        let player = PlayerData()
        context.insert(player)
        
        let achievement1 = Achievement(id: "test1", title: "Test 1", description: "Test", targetValue: 100)
        let achievement2 = Achievement(id: "test2", title: "Test 2", description: "Test", targetValue: 200)
        
        achievement1.player = player
        achievement2.player = player
        
        context.insert(achievement1)
        context.insert(achievement2)
        
        // When
        try? context.save()
        
        // Then
        XCTAssertEqual(player.achievements.count, 2, "Player should have 2 achievements")
        XCTAssertTrue(player.achievements.contains(achievement1), "Player should contain achievement1")
        XCTAssertTrue(player.achievements.contains(achievement2), "Player should contain achievement2")
    }
}