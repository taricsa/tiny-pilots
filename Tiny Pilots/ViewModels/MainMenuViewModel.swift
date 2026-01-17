//
//  MainMenuViewModel.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation
import Observation
import SwiftData



/// ViewModel for managing main menu state and navigation
@Observable
class MainMenuViewModel: BaseViewModel {
    
    // MARK: - Properties
    
    /// Current player data
    private(set) var playerData: PlayerData?
    
    /// Available game modes
    private(set) var availableGameModes: [GameMode] = []
    
    /// Available environments for the player
    private(set) var availableEnvironments: [String] = []
    
    /// Whether settings screen is shown
    var showingSettings: Bool = false
    
    /// Whether achievements screen is shown
    var showingAchievements: Bool = false
    
    /// Whether leaderboards screen is shown
    var showingLeaderboards: Bool = false
    
    /// Whether challenge input screen is shown
    var showingChallengeInput: Bool = false
    
    /// Whether unlocks screen is shown
    var showingUnlocks: Bool = false
    
    /// Whether game mode selection is shown
    var showingGameModeSelection: Bool = false
    
    /// Current navigation destination
    var navigationDestination: NavigationDestination?
    
    /// Animation states
    var animateTitle: Bool = false
    var animateButtons: Bool = false
    
    // MARK: - Computed Properties
    
    /// Player level for display
    var playerLevel: Int {
        return playerData?.level ?? 1
    }
    
    /// Player experience points
    var playerExperience: Int {
        return playerData?.experiencePoints ?? 0
    }
    
    /// Experience needed for next level
    var experienceToNextLevel: Int {
        return playerData?.experienceToNextLevel ?? 100
    }
    
    /// Current level progress (0.0 to 1.0)
    var levelProgress: Double {
        return playerData?.levelProgress ?? 0.0
    }
    
    /// Player statistics summary
    var playerStatistics: PlayerStatistics? {
        return playerData?.statisticsSummary
    }
    
    /// Whether Game Center features are available
    var isGameCenterAvailable: Bool {
        return gameCenterService.isAuthenticated
    }
    
    /// Player display name from Game Center
    var playerDisplayName: String? {
        return gameCenterService.playerDisplayName
    }
    
    // MARK: - Dependencies
    
    private let gameCenterService: GameCenterServiceProtocol
    private var audioService: AudioServiceProtocol
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(
        gameCenterService: GameCenterServiceProtocol,
        audioService: AudioServiceProtocol,
        modelContext: ModelContext
    ) {
        self.gameCenterService = gameCenterService
        self.audioService = audioService
        self.modelContext = modelContext
        
        super.init()
    }
    
    // MARK: - BaseViewModel Overrides
    
    override func performInitialization() {
        loadPlayerData()
        loadAvailableContent()
        authenticateGameCenter()
        startEntranceAnimations()
    }
    
    override func handle(_ action: ViewAction) {
        switch action {
        case let navigateAction as NavigateAction:
            handleNavigation(to: navigateAction.destination)
        case let settingAction as UpdateSettingAction:
            handleSettingUpdate(key: settingAction.key, value: settingAction.value)
        default:
            super.handle(action)
        }
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to a specific screen
    /// - Parameter destination: The destination to navigate to
    func navigateTo(_ destination: NavigationDestination) {
        // Play navigation sound
        audioService.playSound("menu_select", volume: nil, pitch: 1.0, completion: nil)
        
        switch destination {
        case .gameMode:
            showingGameModeSelection = true
        case .hangar:
            navigationDestination = .hangar
        case .settings:
            showingSettings = true
        case .achievements:
            showAchievements()
        case .leaderboards:
            showLeaderboards()
        case .challengeInput:
            showingChallengeInput = true
        case .unlocks:
            showingUnlocks = true
        case .game:
            navigationDestination = .game
        }
    }
    
    /// Start a game with the specified mode
    /// - Parameter mode: The game mode to start
    func startGame(mode: GameMode) {
        guard availableGameModes.contains(mode) else {
            setErrorMessage("Game mode not available: \(mode.displayName)")
            return
        }
        
        // Play start game sound
        audioService.playSound("game_start", volume: nil, pitch: 1.0, completion: nil)
        
        // Navigate to game
        navigationDestination = .game(mode: mode)
    }
    
    /// Show achievements screen
    func showAchievements() {
        if isGameCenterAvailable {
            showingAchievements = true
        } else {
            setErrorMessage("Game Center is not available. Please sign in through Settings.")
        }
    }
    
    /// Show leaderboards screen
    func showLeaderboards() {
        if isGameCenterAvailable {
            showingLeaderboards = true
        } else {
            setErrorMessage("Game Center is not available. Please sign in through Settings.")
        }
    }
    
    /// Dismiss all modal screens
    func dismissAllModals() {
        showingSettings = false
        showingAchievements = false
        showingLeaderboards = false
        showingChallengeInput = false
        showingUnlocks = false
        showingGameModeSelection = false
    }
    
    // MARK: - Player Data Methods
    
    /// Refresh player data from SwiftData
    func refreshPlayerData() {
        loadPlayerData()
        loadAvailableContent()
    }
    
    /// Get unlockable content for next level
    func getNextLevelUnlocks() -> [UnlockableContent] {
        let nextLevel = playerLevel + 1
        return UnlockableContent.getUnlocksForLevel(nextLevel)
    }
    
    /// Check if player has new unlocks to show
    func hasNewUnlocks() -> Bool {
        guard let player = playerData else { return false }
        
        // Check if player recently leveled up
        let lastPlayedDate = player.lastPlayedAt
        let timeSinceLastPlayed = Date().timeIntervalSince(lastPlayedDate)
        
        // If less than 5 minutes since last played and player has unlocks, show them
        return timeSinceLastPlayed < 300 && !getNextLevelUnlocks().isEmpty
    }
    
    // MARK: - Settings Methods
    
    /// Update a setting value
    /// - Parameters:
    ///   - key: Setting key
    ///   - value: New value
    func updateSetting(key: String, value: Any) {
        // Handle different setting types
        switch key {
        case "soundVolume":
            if let volume = value as? Float {
                audioService.soundVolume = volume
            }
        case "musicVolume":
            if let volume = value as? Float {
                audioService.musicVolume = volume
            }
        case "soundEnabled":
            if let enabled = value as? Bool {
                audioService.soundEnabled = enabled
            }
        case "musicEnabled":
            if let enabled = value as? Bool {
                audioService.musicEnabled = enabled
            }
        default:
            break
        }
        
        // Save settings to UserDefaults or SwiftData as needed
        saveSettings()
    }
    
    /// Get current setting value
    /// - Parameter key: Setting key
    /// - Returns: Current setting value
    func getSetting(key: String) -> Any? {
        switch key {
        case "soundVolume":
            return audioService.soundVolume
        case "musicVolume":
            return audioService.musicVolume
        case "soundEnabled":
            return audioService.soundEnabled
        case "musicEnabled":
            return audioService.musicEnabled
        default:
            return nil
        }
    }
    
    // MARK: - Animation Methods
    
    /// Start entrance animations
    func startEntranceAnimations() {
        // Reset animation states
        animateTitle = false
        animateButtons = false
        
        // Animate title first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.animateTitle = true
            
            // Then animate buttons
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.animateButtons = true
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleNavigation(to destination: String) {
        guard let navDestination = NavigationDestination(rawValue: destination) else {
            setErrorMessage("Unknown navigation destination: \(destination)")
            return
        }
        
        navigateTo(navDestination)
    }
    
    private func handleSettingUpdate(key: String, value: Any) {
        updateSetting(key: key, value: value)
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
        
        // Load available game modes based on player progress
        availableGameModes = GameMode.getAvailableModes(for: player)
        
        // Load available environments
        availableEnvironments = player.unlockedEnvironments
    }
    
    private func authenticateGameCenter() {
        gameCenterService.authenticate { success, error in
            if error != nil {
                // Don't show Game Center authentication errors to user
                print("Game Center authentication failed: \(error!)")
            }
        }
    }
    
    private func saveSettings() {
        // Save settings to UserDefaults
        let settings = [
            "soundVolume": audioService.soundVolume,
            "musicVolume": audioService.musicVolume,
            "soundEnabled": audioService.soundEnabled,
            "musicEnabled": audioService.musicEnabled
        ] as [String : Any]
        
        UserDefaults.standard.set(settings, forKey: "gameSettings")
    }
}

// MARK: - Supporting Types

/// Navigation destinations
enum NavigationDestination: String, CaseIterable {
    case gameMode = "gameMode"
    case hangar = "hangar"
    case settings = "settings"
    case achievements = "achievements"
    case leaderboards = "leaderboards"
    case challengeInput = "challengeInput"
    case unlocks = "unlocks"
    case game = "game"
    
    var displayName: String {
        switch self {
        case .gameMode:
            return "Game Mode Selection"
        case .hangar:
            return "Airplane Hangar"
        case .settings:
            return "Settings"
        case .achievements:
            return "Achievements"
        case .leaderboards:
            return "Leaderboards"
        case .challengeInput:
            return "Friend Challenge"
        case .unlocks:
            return "Unlocks"
        case .game:
            return "Game"
        }
    }
}

// Using GameMode from GameManager.swift to avoid duplication

// MARK: - GameMode Extension

extension GameMode {
    var requiredLevel: Int {
        switch self {
        case .tutorial:
            return 1
        case .freePlay:
            return 1
        case .challenge:
            return 3
        case .dailyRun:
            return 5
        case .weeklySpecial:
            return 10
        }
    }
    
    /// Get available game modes for a player
    static func getAvailableModes(for player: PlayerData) -> [GameMode] {
        return GameMode.allCases.filter { mode in
            player.level >= mode.requiredLevel
        }
    }
}

/// Unlockable content structure
struct UnlockableContent {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let type: ContentType
    let requiredLevel: Int
    
    /// Get unlocks available at a specific level
    static func getUnlocksForLevel(_ level: Int) -> [UnlockableContent] {
        let allUnlocks = [
            UnlockableContent(
                id: "dart_plane",
                name: "Dart Plane",
                description: "A sleek, fast airplane design",
                iconName: "paperplane",
                type: .airplane,
                requiredLevel: 2
            ),
            UnlockableContent(
                id: "forest_environment",
                name: "Forest Valley",
                description: "Fly through a lush forest environment",
                iconName: "tree.fill",
                type: .environment,
                requiredLevel: 3
            ),
            UnlockableContent(
                id: "glider_plane",
                name: "Glider Plane",
                description: "Excellent for long-distance flights",
                iconName: "paperplane",
                type: .airplane,
                requiredLevel: 4
            ),
            UnlockableContent(
                id: "desert_environment",
                name: "Desert Canyon",
                description: "Navigate through desert canyons",
                iconName: "sun.max.fill",
                type: .environment,
                requiredLevel: 5
            ),
            UnlockableContent(
                id: "stunt_plane",
                name: "Stunt Plane",
                description: "Perfect for aerial maneuvers",
                iconName: "paperplane",
                type: .airplane,
                requiredLevel: 7
            ),
            UnlockableContent(
                id: "ocean_environment",
                name: "Ocean Breeze",
                description: "Soar over ocean waves",
                iconName: "water.waves",
                type: .environment,
                requiredLevel: 8
            ),
            UnlockableContent(
                id: "heavy_plane",
                name: "Heavy Plane",
                description: "Stable flight in windy conditions",
                iconName: "paperplane",
                type: .airplane,
                requiredLevel: 10
            ),
            UnlockableContent(
                id: "city_environment",
                name: "Urban Skyline",
                description: "Fly between city skyscrapers",
                iconName: "building.2.fill",
                type: .environment,
                requiredLevel: 12
            )
        ]
        
        return allUnlocks.filter { $0.requiredLevel == level }
    }
}

// MARK: - Navigation Destination Extension

extension NavigationDestination {
    /// Create navigation destination for game with mode
    static func game(mode: GameMode) -> NavigationDestination {
        return .game
    }
}