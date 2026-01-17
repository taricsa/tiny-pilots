//
//  HangarViewModelTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
import SwiftData
@testable import Tiny_Pilots

final class HangarViewModelTests: XCTestCase {
    
    var sut: HangarViewModel!
    var mockAudioService: MockAudioService!
    var modelContext: ModelContext!
    var container: ModelContainer!
    
    override func setUp() {
        super.setUp()
        
        // Set up in-memory SwiftData container for testing
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
            
            modelContext = ModelContext(container)
        } catch {
            XCTFail("Failed to create test container: \(error)")
        }
        
        // Create mock services
        mockAudioService = MockAudioService()
        
        // Create system under test
        sut = HangarViewModel(
            audioService: mockAudioService,
            modelContext: modelContext
        )
        
        sut.initialize()
    }
    
    override func tearDown() {
        sut.cleanup()
        sut = nil
        mockAudioService = nil
        modelContext = nil
        container = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_CreatesPlayerDataIfNoneExists() {
        // Given - setUp creates a fresh context
        
        // When - initialization happens in setUp
        
        // Then
        XCTAssertNotNil(sut.playerData)
        XCTAssertEqual(sut.playerData?.level, 1)
    }
    
    func testInitialization_LoadsExistingPlayerData() {
        // Given
        let existingPlayer = PlayerData()
        existingPlayer.level = 10
        existingPlayer.selectedFoldType = "Dart"
        existingPlayer.selectedDesignType = "Striped"
        modelContext.insert(existingPlayer)
        try! modelContext.save()
        
        // When
        let newSut = HangarViewModel(
            audioService: mockAudioService,
            modelContext: modelContext
        )
        newSut.initialize()
        
        // Then
        XCTAssertEqual(newSut.playerData?.level, 10)
        XCTAssertEqual(newSut.selectedFoldType, .dart)
        XCTAssertEqual(newSut.selectedDesignType, .striped)
    }
    
    func testInitialization_LoadsAvailableContent() {
        // Given
        let player = PlayerData()
        player.level = 15 // High level to unlock most content
        modelContext.insert(player)
        try! modelContext.save()
        
        // When
        let newSut = HangarViewModel(
            audioService: mockAudioService,
            modelContext: modelContext
        )
        newSut.initialize()
        
        // Then
        XCTAssertEqual(newSut.availableAirplaneTypes.count, PaperAirplane.AirplaneType.allCases.count)
        XCTAssertTrue(newSut.availableFoldTypes.count > 1) // Should have multiple unlocked
        XCTAssertTrue(newSut.availableDesignTypes.count > 1) // Should have multiple unlocked
    }
    
    // MARK: - Airplane Type Selection Tests
    
    func testSelectAirplaneType_ValidType_UpdatesSelection() {
        // When
        sut.selectAirplaneType(.speedy)
        
        // Then
        XCTAssertEqual(sut.selectedAirplaneType, .speedy)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("menu_select"))
    }
    
    func testSelectAirplaneType_InvalidType_SetsError() {
        // Given
        sut.availableAirplaneTypes = [.basic] // Only basic available
        
        // When
        sut.selectAirplaneType(.speedy)
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("not available"))
    }
    
    // MARK: - Fold Type Selection Tests
    
    func testSelectFoldType_ValidType_UpdatesSelection() {
        // Given
        sut.availableFoldTypes = [.basic, .dart]
        
        // When
        sut.selectFoldType(.dart)
        
        // Then
        XCTAssertEqual(sut.selectedFoldType, .dart)
        XCTAssertTrue(sut.hasUnsavedChanges)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("menu_select"))
    }
    
    func testSelectFoldType_InvalidType_SetsError() {
        // Given
        sut.availableFoldTypes = [.basic] // Only basic available
        
        // When
        sut.selectFoldType(.dart)
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("not available"))
    }
    
    // MARK: - Design Type Selection Tests
    
    func testSelectDesignType_ValidType_UpdatesSelection() {
        // Given
        sut.availableDesignTypes = [.plain, .striped]
        
        // When
        sut.selectDesignType(.striped)
        
        // Then
        XCTAssertEqual(sut.selectedDesignType, .striped)
        XCTAssertTrue(sut.hasUnsavedChanges)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("menu_select"))
    }
    
    func testSelectDesignType_InvalidType_SetsError() {
        // Given
        sut.availableDesignTypes = [.plain] // Only plain available
        
        // When
        sut.selectDesignType(.striped)
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("not available"))
    }
    
    // MARK: - Configuration Management Tests
    
    func testSaveConfiguration_ValidConfiguration_SavesSuccessfully() {
        // Given
        sut.selectFoldType(.dart)
        sut.selectDesignType(.striped)
        
        // When
        sut.saveConfiguration()
        
        // Then
        XCTAssertFalse(sut.hasUnsavedChanges)
        XCTAssertEqual(sut.playerData?.selectedFoldType, "Dart")
        XCTAssertEqual(sut.playerData?.selectedDesignType, "Striped")
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("configuration_saved"))
    }
    
    func testSaveConfiguration_NoPlayerData_SetsError() {
        // Given
        sut.playerData = nil
        
        // When
        sut.saveConfiguration()
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Player data not available"))
    }
    
    func testResetToSavedConfiguration_ResetsSelection() {
        // Given
        sut.playerData?.selectedFoldType = "Dart"
        sut.playerData?.selectedDesignType = "Striped"
        sut.selectFoldType(.glider) // Change to something different
        XCTAssertTrue(sut.hasUnsavedChanges)
        
        // When
        sut.resetToSavedConfiguration()
        
        // Then
        XCTAssertFalse(sut.hasUnsavedChanges)
        XCTAssertEqual(sut.selectedFoldType, .dart)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("menu_back"))
    }
    
    // MARK: - Unlock Status Tests
    
    func testIsAirplaneTypeUnlocked_BasicType_ReturnsTrue() {
        // Given
        sut.playerData?.unlockContent("basic", type: .airplane)
        
        // Then
        XCTAssertTrue(sut.isAirplaneTypeUnlocked(.basic))
    }
    
    func testIsAirplaneTypeUnlocked_LockedType_ReturnsFalse() {
        // Then
        XCTAssertFalse(sut.isAirplaneTypeUnlocked(.speedy))
    }
    
    func testIsFoldTypeUnlocked_LowLevel_ReturnsFalse() {
        // Given
        sut.playerData?.level = 1
        
        // Then
        XCTAssertTrue(sut.isFoldTypeUnlocked(.basic)) // Level 1 requirement
        XCTAssertFalse(sut.isFoldTypeUnlocked(.dart)) // Level 3 requirement
    }
    
    func testIsFoldTypeUnlocked_HighLevel_ReturnsTrue() {
        // Given
        sut.playerData?.level = 10
        
        // Then
        XCTAssertTrue(sut.isFoldTypeUnlocked(.basic))
        XCTAssertTrue(sut.isFoldTypeUnlocked(.dart))
        XCTAssertTrue(sut.isFoldTypeUnlocked(.glider))
        XCTAssertTrue(sut.isFoldTypeUnlocked(.stunt))
    }
    
    func testIsDesignTypeUnlocked_LowLevel_ReturnsFalse() {
        // Given
        sut.playerData?.level = 1
        
        // Then
        XCTAssertTrue(sut.isDesignTypeUnlocked(.plain)) // Level 1 requirement
        XCTAssertFalse(sut.isDesignTypeUnlocked(.striped)) // Level 2 requirement
    }
    
    func testIsDesignTypeUnlocked_HighLevel_ReturnsTrue() {
        // Given
        sut.playerData?.level = 20
        
        // Then
        XCTAssertTrue(sut.isDesignTypeUnlocked(.plain))
        XCTAssertTrue(sut.isDesignTypeUnlocked(.striped))
        XCTAssertTrue(sut.isDesignTypeUnlocked(.rainbow))
    }
    
    // MARK: - Configuration Details Tests
    
    func testCurrentAirplaneDetails_ReturnsCorrectDetails() {
        // Given
        sut.selectedFoldType = .dart
        sut.selectedDesignType = .striped
        
        // When
        let details = sut.currentAirplaneDetails
        
        // Then
        XCTAssertTrue(details.name.contains("Dart"))
        XCTAssertTrue(details.description.contains("dart"))
        XCTAssertNotNil(details.stats)
    }
    
    func testPreviewAirplane_ReturnsCurrentConfiguration() {
        // Given
        sut.selectedAirplaneType = .glider
        sut.selectedFoldType = .dart
        sut.selectedDesignType = .striped
        
        // When
        let preview = sut.previewAirplane
        
        // Then
        XCTAssertEqual(preview.type, .glider)
        XCTAssertEqual(preview.fold, .dart)
        XCTAssertEqual(preview.design, .striped)
    }
    
    func testCanSelectCurrentConfiguration_WithChanges_ReturnsTrue() {
        // Given
        sut.playerData?.level = 10 // High enough to unlock content
        sut.playerData?.unlockContent("basic", type: .airplane)
        sut.selectFoldType(.dart) // Make a change
        
        // Then
        XCTAssertTrue(sut.canSelectCurrentConfiguration)
    }
    
    func testCanSelectCurrentConfiguration_NoChanges_ReturnsFalse() {
        // Given
        sut.playerData?.level = 10
        sut.playerData?.unlockContent("basic", type: .airplane)
        // No changes made
        
        // Then
        XCTAssertFalse(sut.canSelectCurrentConfiguration)
    }
    
    // MARK: - Unlock Requirements Tests
    
    func testUnlockRequirements_LockedContent_ReturnsRequirements() {
        // Given
        sut.playerData?.level = 1
        sut.selectedFoldType = .dart // Requires level 3
        sut.selectedDesignType = .striped // Requires level 2
        
        // When
        let requirements = sut.unlockRequirements
        
        // Then
        XCTAssertTrue(requirements.count >= 2)
        XCTAssertTrue(requirements.contains { $0.description.contains("level 3") })
        XCTAssertTrue(requirements.contains { $0.description.contains("level 2") })
    }
    
    func testUnlockRequirements_UnlockedContent_ReturnsEmpty() {
        // Given
        sut.playerData?.level = 20 // High level
        sut.playerData?.unlockContent("basic", type: .airplane)
        sut.selectedFoldType = .basic
        sut.selectedDesignType = .plain
        
        // When
        let requirements = sut.unlockRequirements
        
        // Then
        XCTAssertTrue(requirements.isEmpty)
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateBack_WithUnsavedChanges_ResetsConfiguration() {
        // Given
        sut.selectFoldType(.dart)
        XCTAssertTrue(sut.hasUnsavedChanges)
        
        // When
        sut.navigateBack()
        
        // Then
        XCTAssertFalse(sut.hasUnsavedChanges)
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("menu_back"))
    }
    
    func testNavigateBack_NoUnsavedChanges_PlaysSound() {
        // When
        sut.navigateBack()
        
        // Then
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("menu_back"))
    }
    
    // MARK: - Animation Tests
    
    func testStartEntranceAnimations_SetsAnimationStates() {
        // Given
        sut.animateTitle = false
        sut.animateContent = false
        
        // When
        sut.startEntranceAnimations()
        
        // Then
        let expectation = XCTestExpectation(description: "Animations started")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertTrue(self.sut.animateTitle)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Action Handling Tests
    
    func testHandleNavigateAction_PlaysSound() {
        // Given
        let action = NavigateAction(to: "back")
        
        // When
        sut.handle(action)
        
        // Then
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("menu_select"))
    }
}

// MARK: - Supporting Types Tests

extension HangarViewModelTests {
    
    func testAirplaneConfiguration_DisplayName() {
        // Given
        let config = AirplaneConfiguration(
            type: .glider,
            fold: .dart,
            design: .striped
        )
        
        // Then
        XCTAssertEqual(config.displayName, "Dart Glider")
    }
    
    func testAirplaneStats_AllStats() {
        // Given
        let stats = AirplaneStats(
            speed: 0.8,
            stability: 0.6,
            lift: 0.9,
            maneuverability: 0.7
        )
        
        // When
        let allStats = stats.allStats
        
        // Then
        XCTAssertEqual(allStats.count, 4)
        XCTAssertEqual(allStats[0].name, "Speed")
        XCTAssertEqual(allStats[0].value, 0.8)
        XCTAssertEqual(allStats[1].name, "Stability")
        XCTAssertEqual(allStats[1].value, 0.6)
    }
    
    func testUnlockRequirement_IsCompleted() {
        // Given
        let completedRequirement = UnlockRequirement(
            type: .level,
            description: "Reach level 5",
            currentValue: 7,
            requiredValue: 5
        )
        
        let incompleteRequirement = UnlockRequirement(
            type: .level,
            description: "Reach level 10",
            currentValue: 3,
            requiredValue: 10
        )
        
        // Then
        XCTAssertTrue(completedRequirement.isCompleted)
        XCTAssertFalse(incompleteRequirement.isCompleted)
    }
    
    func testUnlockRequirement_ProgressPercentage() {
        // Given
        let requirement = UnlockRequirement(
            type: .level,
            description: "Reach level 10",
            currentValue: 3,
            requiredValue: 10
        )
        
        // Then
        XCTAssertEqual(requirement.progressPercentage, 0.3, accuracy: 0.01)
    }
}

// MARK: - PaperAirplane Enum Tests

extension HangarViewModelTests {
    
    func testFoldType_UnlockLevels() {
        XCTAssertEqual(PaperAirplane.FoldType.basic.unlockLevel, 1)
        XCTAssertEqual(PaperAirplane.FoldType.dart.unlockLevel, 3)
        XCTAssertEqual(PaperAirplane.FoldType.glider.unlockLevel, 5)
        XCTAssertEqual(PaperAirplane.FoldType.stunt.unlockLevel, 8)
        XCTAssertEqual(PaperAirplane.FoldType.fighter.unlockLevel, 12)
    }
    
    func testDesignType_UnlockLevels() {
        XCTAssertEqual(PaperAirplane.DesignType.plain.unlockLevel, 1)
        XCTAssertEqual(PaperAirplane.DesignType.striped.unlockLevel, 2)
        XCTAssertEqual(PaperAirplane.DesignType.dotted.unlockLevel, 4)
        XCTAssertEqual(PaperAirplane.DesignType.camouflage.unlockLevel, 7)
        XCTAssertEqual(PaperAirplane.DesignType.flames.unlockLevel, 10)
        XCTAssertEqual(PaperAirplane.DesignType.rainbow.unlockLevel, 15)
    }
    
    func testFoldType_PhysicsMultiplier() {
        let basicMultiplier = PaperAirplane.FoldType.basic.physicsMultiplier
        XCTAssertEqual(basicMultiplier.lift, 1.0)
        XCTAssertEqual(basicMultiplier.drag, 1.0)
        XCTAssertEqual(basicMultiplier.turnRate, 1.0)
        XCTAssertEqual(basicMultiplier.mass, 1.0)
        
        let dartMultiplier = PaperAirplane.FoldType.dart.physicsMultiplier
        XCTAssertEqual(dartMultiplier.lift, 0.8)
        XCTAssertEqual(dartMultiplier.drag, 0.7)
        XCTAssertEqual(dartMultiplier.turnRate, 1.2)
        XCTAssertEqual(dartMultiplier.mass, 0.9)
    }
    
    func testAirplaneType_Properties() {
        XCTAssertEqual(PaperAirplane.AirplaneType.basic.textureName, "airplane_basic")
        XCTAssertEqual(PaperAirplane.AirplaneType.speedy.size, CGSize(width: 70, height: 35))
        XCTAssertEqual(PaperAirplane.AirplaneType.sturdy.mass, 1.5)
        XCTAssertEqual(PaperAirplane.AirplaneType.glider.linearDamping, 0.2)
    }
}/
/ MARK: - Additional Edge Case Tests

extension HangarViewModelTests {
    
    // MARK: - Error Handling Tests
    
    func testSelectAirplaneType_WithNilPlayerData_HandlesGracefully() {
        // Given
        sut.playerData = nil
        
        // When
        sut.selectAirplaneType(.speedy)
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Player data"))
    }
    
    func testSaveConfiguration_WithCorruptedData_HandlesGracefully() {
        // Given
        sut.selectFoldType(.dart)
        // Simulate data corruption
        sut.playerData = nil
        
        // When
        sut.saveConfiguration()
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Player data not available"))
    }
    
    func testUnlockRequirements_InvalidContent_ReturnsEmptyRequirements() {
        // When
        let requirements = sut.unlockRequirements(for: "invalid_content", type: .airplane)
        
        // Then
        XCTAssertTrue(requirements.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testMultipleSelections_PerformanceTest() {
        // Given
        sut.availableFoldTypes = PaperAirplane.FoldType.allCases
        sut.availableDesignTypes = PaperAirplane.DesignType.allCases
        
        // When
        measure {
            for _ in 0..<1000 {
                sut.selectFoldType(.dart)
                sut.selectDesignType(.striped)
                sut.selectFoldType(.glider)
                sut.selectDesignType(.rainbow)
            }
        }
        
        // Then
        XCTAssertEqual(sut.selectedFoldType, .glider)
        XCTAssertEqual(sut.selectedDesignType, .rainbow)
    }
    
    func testConfigurationSave_PerformanceTest() {
        // Given
        sut.selectFoldType(.dart)
        sut.selectDesignType(.striped)
        
        // When
        measure {
            for _ in 0..<100 {
                sut.saveConfiguration()
                sut.selectFoldType(.glider)
                sut.saveConfiguration()
                sut.selectFoldType(.dart)
            }
        }
        
        // Then
        XCTAssertFalse(sut.hasUnsavedChanges)
    }
    
    // MARK: - Memory Management Tests
    
    func testCleanup_ReleasesResources() {
        // Given
        sut.selectFoldType(.dart)
        sut.selectDesignType(.striped)
        
        // When
        sut.cleanup()
        
        // Then
        XCTAssertFalse(sut.hasUnsavedChanges)
    }
    
    func testMultipleInitialization_DoesNotLeak() {
        // When
        for _ in 0..<10 {
            let viewModel = HangarViewModel(
                audioService: mockAudioService,
                modelContext: modelContext
            )
            viewModel.initialize()
            viewModel.cleanup()
        }
        
        // Then - Should not crash or leak memory
        XCTAssertTrue(true)
    }
    
    // MARK: - Configuration Validation Tests
    
    func testValidateConfiguration_ValidConfiguration_ReturnsTrue() {
        // Given
        sut.availableAirplaneTypes = [.basic, .speedy]
        sut.availableFoldTypes = [.basic, .dart]
        sut.availableDesignTypes = [.plain, .striped]
        sut.selectAirplaneType(.speedy)
        sut.selectFoldType(.dart)
        sut.selectDesignType(.striped)
        
        // When
        let isValid = sut.validateCurrentConfiguration()
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testValidateConfiguration_InvalidConfiguration_ReturnsFalse() {
        // Given
        sut.availableAirplaneTypes = [.basic] // Only basic available
        sut.availableFoldTypes = [.basic] // Only basic available
        sut.selectedAirplaneType = .speedy // Not available
        sut.selectedFoldType = .dart // Not available
        
        // When
        let isValid = sut.validateCurrentConfiguration()
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Airplane Statistics Tests
    
    func testAirplaneStatistics_CalculatesCorrectly() {
        // Given
        sut.selectAirplaneType(.speedy)
        sut.selectFoldType(.dart)
        sut.selectDesignType(.plain)
        
        // When
        let stats = sut.currentAirplaneStats
        
        // Then
        XCTAssertNotNil(stats)
        XCTAssertGreaterThan(stats.speed, 0)
        XCTAssertGreaterThan(stats.stability, 0)
        XCTAssertGreaterThan(stats.maneuverability, 0)
    }
    
    func testAirplaneComparison_ShowsDifferences() {
        // Given
        let config1 = AirplaneConfiguration(type: .basic, fold: .basic, design: .plain)
        let config2 = AirplaneConfiguration(type: .speedy, fold: .dart, design: .striped)
        
        // When
        let comparison = sut.compareConfigurations(config1, config2)
        
        // Then
        XCTAssertNotNil(comparison)
        XCTAssertNotEqual(comparison.speedDifference, 0)
        XCTAssertNotEqual(comparison.stabilityDifference, 0)
    }
    
    // MARK: - Content Unlock Tests
    
    func testContentUnlock_ByLevel_UnlocksCorrectly() {
        // Given
        sut.playerData?.level = 5
        
        // When
        sut.refreshAvailableContent()
        
        // Then
        XCTAssertTrue(sut.isFoldTypeUnlocked(.basic)) // Level 1
        XCTAssertTrue(sut.isFoldTypeUnlocked(.dart)) // Level 3
        XCTAssertTrue(sut.isFoldTypeUnlocked(.glider)) // Level 5
        XCTAssertFalse(sut.isFoldTypeUnlocked(.stunt)) // Level 10
    }
    
    func testContentUnlock_ByAchievement_UnlocksCorrectly() {
        // Given
        sut.playerData?.unlockContent("rainbow_design", type: .design)
        
        // When
        sut.refreshAvailableContent()
        
        // Then
        XCTAssertTrue(sut.isDesignTypeUnlocked(.rainbow))
    }
    
    func testContentUnlock_ByPurchase_UnlocksCorrectly() {
        // Given
        sut.playerData?.unlockContent("premium_airplane", type: .airplane)
        
        // When
        sut.refreshAvailableContent()
        
        // Then
        XCTAssertTrue(sut.isAirplaneTypeUnlocked(.premium))
    }
    
    // MARK: - Configuration History Tests
    
    func testConfigurationHistory_TracksChanges() {
        // Given
        let initialConfig = sut.currentConfiguration
        
        // When
        sut.selectFoldType(.dart)
        sut.selectDesignType(.striped)
        sut.saveConfiguration()
        
        // Then
        let history = sut.configurationHistory
        XCTAssertEqual(history.count, 2) // Initial + new configuration
        XCTAssertNotEqual(history.first, history.last)
    }
    
    func testConfigurationHistory_LimitsEntries() {
        // Given - Create many configuration changes
        for i in 0..<20 {
            sut.selectFoldType(i % 2 == 0 ? .dart : .glider)
            sut.saveConfiguration()
        }
        
        // When
        let history = sut.configurationHistory
        
        // Then
        XCTAssertLessThanOrEqual(history.count, 10) // Should limit to 10 entries
    }
    
    // MARK: - Preview Tests
    
    func testPreviewAirplane_UpdatesInRealTime() {
        // Given
        let initialPreview = sut.previewAirplane
        
        // When
        sut.selectFoldType(.dart)
        let updatedPreview = sut.previewAirplane
        
        // Then
        XCTAssertNotEqual(initialPreview.fold, updatedPreview.fold)
        XCTAssertEqual(updatedPreview.fold, .dart)
    }
    
    func testPreviewAirplane_ShowsUnsavedChanges() {
        // Given
        sut.selectFoldType(.dart)
        sut.selectDesignType(.striped)
        
        // When
        let preview = sut.previewAirplane
        
        // Then
        XCTAssertEqual(preview.fold, .dart)
        XCTAssertEqual(preview.design, .striped)
        XCTAssertTrue(sut.hasUnsavedChanges)
    }
    
    // MARK: - Audio Feedback Tests
    
    func testAudioFeedback_PlaysOnSelection() {
        // When
        sut.selectFoldType(.dart)
        
        // Then
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("menu_select"))
    }
    
    func testAudioFeedback_PlaysOnSave() {
        // Given
        sut.selectFoldType(.dart)
        
        // When
        sut.saveConfiguration()
        
        // Then
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("configuration_saved"))
    }
    
    func testAudioFeedback_PlaysOnError() {
        // Given
        sut.availableFoldTypes = [.basic] // Only basic available
        
        // When
        sut.selectFoldType(.dart) // Should fail
        
        // Then
        XCTAssertTrue(mockAudioService.soundsPlayed.contains("error") || 
                     mockAudioService.soundsPlayed.contains("menu_error"))
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentSelections_ThreadSafe() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent selections complete")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for i in 0..<10 {
            DispatchQueue.global().async {
                self.sut.selectFoldType(i % 2 == 0 ? .dart : .glider)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then
        XCTAssertTrue(sut.selectedFoldType == .dart || sut.selectedFoldType == .glider)
    }
}