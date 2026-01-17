//
//  HangarViewModel.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation
import Observation
import SwiftData

/// ViewModel for managing airplane hangar and customization
@Observable
class HangarViewModel: BaseViewModel {
    
    // MARK: - Properties
    
    /// Current player data
    private(set) var playerData: PlayerData?
    
    /// Available airplane types
    private(set) var availableAirplaneTypes: [PaperAirplane.AirplaneType] = []
    
    /// Available fold types
    private(set) var availableFoldTypes: [PaperAirplane.FoldType] = []
    
    /// Available design types
    private(set) var availableDesignTypes: [PaperAirplane.DesignType] = []
    
    /// Currently selected airplane type
    var selectedAirplaneType: PaperAirplane.AirplaneType = .basic
    
    /// Currently selected fold type
    var selectedFoldType: PaperAirplane.FoldType = .basic
    
    /// Currently selected design type
    var selectedDesignType: PaperAirplane.DesignType = .plain
    
    /// Animation states
    var animateTitle: Bool = false
    var animateContent: Bool = false
    
    /// Whether the customization has unsaved changes
    private(set) var hasUnsavedChanges: Bool = false
    
    /// Preview airplane configuration
    var previewAirplane: AirplaneConfiguration {
        return AirplaneConfiguration(
            type: selectedAirplaneType,
            fold: selectedFoldType,
            design: selectedDesignType
        )
    }
    
    // MARK: - Computed Properties
    
    /// Current airplane configuration details
    var currentAirplaneDetails: AirplaneDetails {
        return AirplaneDetails(
            name: getAirplaneName(),
            description: getAirplaneDescription(),
            stats: getAirplaneStats(),
            isUnlocked: checkCurrentConfigurationUnlocked()
        )
    }
    
    /// Whether the current configuration is unlocked
    var isCurrentConfigurationUnlocked: Bool {
        return checkCurrentConfigurationUnlocked()
    }
    
    /// Whether the current configuration can be selected
    var canSelectCurrentConfiguration: Bool {
        return checkCurrentConfigurationUnlocked() && hasUnsavedChanges
    }
    
    /// Unlock requirements for locked content
    var unlockRequirements: [UnlockRequirement] {
        return getUnlockRequirements()
    }
    
    // MARK: - Dependencies
    
    private let audioService: AudioServiceProtocol
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(
        audioService: AudioServiceProtocol,
        modelContext: ModelContext
    ) {
        self.audioService = audioService
        self.modelContext = modelContext
        
        super.init()
    }
    
    // MARK: - BaseViewModel Overrides
    
    override func performInitialization() {
        loadPlayerData()
        loadAvailableContent()
        loadCurrentSelection()
        startEntranceAnimations()
    }
    
    override func handle(_ action: ViewAction) {
        switch action {
        case let navigateAction as NavigateAction:
            handleNavigation(to: navigateAction.destination)
        default:
            super.handle(action)
        }
    }
    
    // MARK: - Airplane Selection Methods
    
    /// Select an airplane type
    /// - Parameter type: The airplane type to select
    func selectAirplaneType(_ type: PaperAirplane.AirplaneType) {
        guard availableAirplaneTypes.contains(type) else {
            setErrorMessage("Airplane type not available: \(type.rawValue)")
            return
        }
        
        selectedAirplaneType = type
        updateUnsavedChanges()
        
        // Play selection sound
        audioService.playSound("menu_select", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Select a fold type
    /// - Parameter fold: The fold type to select
    func selectFoldType(_ fold: PaperAirplane.FoldType) {
        guard availableFoldTypes.contains(fold) else {
            setErrorMessage("Fold type not available: \(fold.rawValue)")
            return
        }
        
        selectedFoldType = fold
        updateUnsavedChanges()
        
        // Play selection sound
        audioService.playSound("menu_select", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Select a design type
    /// - Parameter design: The design type to select
    func selectDesignType(_ design: PaperAirplane.DesignType) {
        guard availableDesignTypes.contains(design) else {
            setErrorMessage("Design type not available: \(design.rawValue)")
            return
        }
        
        selectedDesignType = design
        updateUnsavedChanges()
        
        // Play selection sound
        audioService.playSound("menu_select", volume: nil, pitch: 1.0, completion: nil)
    }
    
    // MARK: - Configuration Management
    
    /// Save the current airplane configuration
    func saveConfiguration() {
        guard let player = playerData else {
            setErrorMessage("Player data not available")
            return
        }
        
        guard checkCurrentConfigurationUnlocked() else {
            setErrorMessage("Current configuration is not unlocked")
            return
        }
        
        // Update player data with new selection
        let success = player.updateSelectedAirplane(
            foldType: selectedFoldType.rawValue,
            designType: selectedDesignType.rawValue
        )
        
        guard success else {
            setErrorMessage("Failed to save airplane configuration")
            return
        }
        
        // Save to SwiftData
        do {
            try modelContext.save()
            hasUnsavedChanges = false
            
            // Play success sound
            audioService.playSound("configuration_saved", volume: nil, pitch: 1.0, completion: nil)
            
        } catch {
            setError(error)
        }
    }
    
    /// Reset to the saved configuration
    func resetToSavedConfiguration() {
        loadCurrentSelection()
        hasUnsavedChanges = false
        
        // Play reset sound
        audioService.playSound("menu_back", volume: nil, pitch: 1.0, completion: nil)
    }
    
    /// Check if a specific airplane type is unlocked
    /// - Parameter type: The airplane type to check
    /// - Returns: Whether the type is unlocked
    func isAirplaneTypeUnlocked(_ type: PaperAirplane.AirplaneType) -> Bool {
        guard let player = playerData else { return false }
        return player.isContentUnlocked(type.rawValue, type: .airplane)
    }
    
    /// Check if a specific fold type is unlocked
    /// - Parameter fold: The fold type to check
    /// - Returns: Whether the fold is unlocked
    func isFoldTypeUnlocked(_ fold: PaperAirplane.FoldType) -> Bool {
        guard let player = playerData else { return false }
        return player.level >= fold.unlockLevel
    }
    
    /// Check if a specific design type is unlocked
    /// - Parameter design: The design type to check
    /// - Returns: Whether the design is unlocked
    func isDesignTypeUnlocked(_ design: PaperAirplane.DesignType) -> Bool {
        guard let player = playerData else { return false }
        return player.level >= design.unlockLevel
    }
    
    // MARK: - Animation Methods
    
    /// Start entrance animations
    func startEntranceAnimations() {
        // Reset animation states
        animateTitle = false
        animateContent = false
        
        // Animate title first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.animateTitle = true
            
            // Then animate content
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.animateContent = true
            }
        }
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate back to main menu
    func navigateBack() {
        if hasUnsavedChanges {
            // Could show a confirmation dialog here
            // For now, just reset and go back
            resetToSavedConfiguration()
        }
        
        // Navigation is handled by the parent view
        audioService.playSound("menu_back", volume: nil, pitch: 1.0, completion: nil)
    }
    
    // MARK: - Private Methods
    
    private func handleNavigation(to destination: String) {
        // Handle navigation actions if needed
        audioService.playSound("menu_select", volume: nil, pitch: 1.0, completion: nil)
    }
    
    private func loadPlayerData() {
        let fetchDescriptor = FetchDescriptor<PlayerData>()
        
        do {
            let players = try modelContext.fetch(fetchDescriptor)
            playerData = players.first
            
            if playerData == nil {
                // Create new player data if none exists
                let newPlayer = PlayerData()
                modelContext.insert(newPlayer)
                try modelContext.save()
                playerData = newPlayer
            }
        } catch {
            setError(error)
        }
    }
    
    private func loadAvailableContent() {
        guard let player = playerData else { return }
        
        // Load available airplane types (all types are available, but some may be locked)
        availableAirplaneTypes = PaperAirplane.AirplaneType.allCases
        
        // Load available fold types based on player level
        availableFoldTypes = PaperAirplane.FoldType.allCases.filter { fold in
            player.level >= fold.unlockLevel
        }
        
        // Load available design types based on player level
        availableDesignTypes = PaperAirplane.DesignType.allCases.filter { design in
            player.level >= design.unlockLevel
        }
    }
    
    private func loadCurrentSelection() {
        guard let player = playerData else { return }
        
        // Load current selection from player data
        if let foldType = PaperAirplane.FoldType(rawValue: player.selectedFoldType) {
            selectedFoldType = foldType
        }
        
        if let designType = PaperAirplane.DesignType(rawValue: player.selectedDesignType) {
            selectedDesignType = designType
        }
        
        // For airplane type, we'll use basic for now since it's not stored in PlayerData
        selectedAirplaneType = .basic
    }
    
    private func updateUnsavedChanges() {
        guard let player = playerData else { return }
        
        let currentFold = player.selectedFoldType
        let currentDesign = player.selectedDesignType
        
        hasUnsavedChanges = (selectedFoldType.rawValue != currentFold) ||
                           (selectedDesignType.rawValue != currentDesign)
    }
    
    private func checkCurrentConfigurationUnlocked() -> Bool {
        return isAirplaneTypeUnlocked(selectedAirplaneType) &&
               isFoldTypeUnlocked(selectedFoldType) &&
               isDesignTypeUnlocked(selectedDesignType)
    }
    
    private func getAirplaneName() -> String {
        let typeName = selectedAirplaneType.rawValue.capitalized
        let foldName = selectedFoldType.rawValue
        return "\(foldName) \(typeName)"
    }
    
    private func getAirplaneDescription() -> String {
        let multiplier = selectedFoldType.physicsMultiplier
        
        var description = "A \(selectedFoldType.rawValue.lowercased()) paper airplane"
        
        if multiplier.lift > 1.1 {
            description += " with excellent lift"
        } else if multiplier.lift < 0.9 {
            description += " with reduced lift"
        }
        
        if multiplier.turnRate > 1.1 {
            description += " and high maneuverability"
        } else if multiplier.turnRate < 0.9 {
            description += " and stable flight"
        }
        
        return description + "."
    }
    
    private func getAirplaneStats() -> AirplaneStats {
        let typeMultiplier = selectedAirplaneType
        let foldMultiplier = selectedFoldType.physicsMultiplier
        
        return AirplaneStats(
            speed: calculateStatValue(base: 0.8, typeMultiplier: typeMultiplier == .speedy ? 1.3 : 1.0, foldMultiplier: 2.0 - foldMultiplier.drag),
            stability: calculateStatValue(base: 0.7, typeMultiplier: typeMultiplier == .sturdy ? 1.4 : 1.0, foldMultiplier: 2.0 - foldMultiplier.turnRate),
            lift: calculateStatValue(base: 0.6, typeMultiplier: typeMultiplier == .glider ? 1.3 : 1.0, foldMultiplier: foldMultiplier.lift),
            maneuverability: calculateStatValue(base: 0.7, typeMultiplier: 1.0, foldMultiplier: foldMultiplier.turnRate)
        )
    }
    
    private func calculateStatValue(base: Double, typeMultiplier: CGFloat, foldMultiplier: CGFloat) -> Double {
        let value = base * Double(typeMultiplier) * Double(foldMultiplier)
        return min(1.0, max(0.0, value)) // Clamp between 0 and 1
    }
    
    private func getUnlockRequirements() -> [UnlockRequirement] {
        var requirements: [UnlockRequirement] = []
        
        // Check fold type requirements
        if !isFoldTypeUnlocked(selectedFoldType) {
            requirements.append(UnlockRequirement(
                type: .level,
                description: "Reach level \(selectedFoldType.unlockLevel) to unlock \(selectedFoldType.rawValue) fold",
                currentValue: playerData?.level ?? 1,
                requiredValue: selectedFoldType.unlockLevel
            ))
        }
        
        // Check design type requirements
        if !isDesignTypeUnlocked(selectedDesignType) {
            requirements.append(UnlockRequirement(
                type: .level,
                description: "Reach level \(selectedDesignType.unlockLevel) to unlock \(selectedDesignType.rawValue) design",
                currentValue: playerData?.level ?? 1,
                requiredValue: selectedDesignType.unlockLevel
            ))
        }
        
        // Check airplane type requirements (if any)
        if !isAirplaneTypeUnlocked(selectedAirplaneType) {
            requirements.append(UnlockRequirement(
                type: .unlock,
                description: "Unlock \(selectedAirplaneType.rawValue.capitalized) airplane type",
                currentValue: 0,
                requiredValue: 1
            ))
        }
        
        return requirements
    }
}

// MARK: - Supporting Types

/// Airplane configuration structure
struct AirplaneConfiguration {
    let type: PaperAirplane.AirplaneType
    let fold: PaperAirplane.FoldType
    let design: PaperAirplane.DesignType
    
    var displayName: String {
        return "\(fold.rawValue) \(type.rawValue.capitalized)"
    }
}

/// Airplane details for display
struct AirplaneDetails {
    let name: String
    let description: String
    let stats: AirplaneStats
    let isUnlocked: Bool
}

/// Airplane statistics
struct AirplaneStats {
    let speed: Double
    let stability: Double
    let lift: Double
    let maneuverability: Double
    
    /// Get all stats as an array for easy iteration
    var allStats: [(name: String, value: Double)] {
        return [
            ("Speed", speed),
            ("Stability", stability),
            ("Lift", lift),
            ("Maneuverability", maneuverability)
        ]
    }
}

/// Unlock requirement structure
struct UnlockRequirement {
    enum RequirementType {
        case level
        case unlock
        case achievement
    }
    
    let type: RequirementType
    let description: String
    let currentValue: Int
    let requiredValue: Int
    
    var isCompleted: Bool {
        return currentValue >= requiredValue
    }
    
    var progressPercentage: Double {
        guard requiredValue > 0 else { return 1.0 }
        return min(1.0, Double(currentValue) / Double(requiredValue))
    }
}