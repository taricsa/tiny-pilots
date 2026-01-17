# Design Document

## Overview

This design document outlines the architectural refactoring of Tiny Pilots from the current mixed architecture to a clean MVVM pattern following SOLID principles. The refactoring will improve code maintainability, testability, and extensibility while preserving all existing functionality.

## Architecture

### MVVM Pattern Implementation

The new architecture will follow a strict MVVM pattern with clear separation of concerns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      View       │───▶│   ViewModel     │───▶│     Model       │
│                 │    │                 │    │                 │
│ - SpriteKit     │    │ - Presentation  │    │ - Business      │
│   Scenes        │    │   Logic         │    │   Logic         │
│ - UI Components │    │ - State Mgmt    │    │ - Data Models   │
│ - User Input    │    │ - Coordination  │    │ - Services      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Dependency Flow
- Views depend only on ViewModels
- ViewModels depend on Models and Services through protocols
- Models have no dependencies on UI layers
- All dependencies flow inward (Dependency Inversion Principle)

## Components and Interfaces

### New Folder Structure

```
Tiny Pilots/
├── Models/
│   ├── Entities/
│   │   ├── PaperAirplane.swift
│   │   ├── Environment.swift
│   │   ├── Obstacle.swift
│   │   └── Collectible.swift
│   ├── ValueObjects/
│   │   ├── GameState.swift
│   │   ├── PlayerData.swift
│   │   └── GameStatistics.swift
│   └── BusinessLogic/
│       ├── GameRules.swift
│       ├── PhysicsCalculations.swift
│       └── ProgressionLogic.swift
├── ViewModels/
│   ├── GameViewModel.swift
│   ├── MainMenuViewModel.swift
│   ├── HangarViewModel.swift
│   ├── GameModeSelectionViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── Scenes/
│   │   ├── GameScene.swift
│   │   ├── MainMenuScene.swift
│   │   ├── HangarScene.swift
│   │   └── GameModeSelectionScene.swift
│   ├── Components/
│   │   ├── HUDOverlay.swift
│   │   ├── ProgressionOverlay.swift
│   │   └── GameCenterView.swift
│   └── SwiftUI/
│       ├── MainMenuView.swift
│       ├── SettingsView.swift
│       └── LeaderboardView.swift
├── Services/
│   ├── Protocols/
│   │   ├── GameCenterServiceProtocol.swift
│   │   ├── AudioServiceProtocol.swift
│   │   ├── PhysicsServiceProtocol.swift
│   │   └── GameServiceProtocol.swift
│   └── Implementations/
│       ├── GameCenterService.swift
│       ├── AudioService.swift
│       ├── PhysicsService.swift
│       └── GameService.swift
├── Core/
│   ├── DependencyInjection/
│   │   ├── DIContainer.swift
│   │   └── ServiceRegistration.swift
│   ├── Extensions/
│   │   ├── CGVector+Extensions.swift
│   │   └── SKNode+Extensions.swift
│   └── Utilities/
│       ├── GameConfig.swift
│       ├── PhysicsCategory.swift
│       └── ErrorHandling.swift
└── Resources/
    ├── Assets.xcassets/
    └── Particles/
```

### Key Protocols

#### Service Protocols

```swift
protocol GameCenterServiceProtocol {
    func authenticatePlayer(completion: @escaping (Bool, Error?) -> Void)
    func submitScore(_ score: Int, category: String, completion: @escaping (Error?) -> Void)
    func loadLeaderboard(category: String, completion: @escaping ([LeaderboardEntry]?, Error?) -> Void)
}

protocol AudioServiceProtocol {
    func playSound(_ soundName: String)
    func playBackgroundMusic(_ musicName: String)
    func setMasterVolume(_ volume: Float)
}

protocol PhysicsServiceProtocol {
    func applyForces(to airplane: PaperAirplane, tiltX: CGFloat, tiltY: CGFloat)
    func calculateLift(for airplane: PaperAirplane) -> CGFloat
    func handleCollision(between nodeA: SKNode, and nodeB: SKNode)
}

protocol DataPersistenceServiceProtocol {
    func save<T: Codable>(_ object: T, forKey key: String)
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    func delete(forKey key: String)
}
```

#### Repository Protocols

```swift
protocol PlayerDataRepositoryProtocol {
    func getPlayerData() -> PlayerData
    func savePlayerData(_ data: PlayerData)
    func updateExperience(_ xp: Int)
    func unlockContent(_ contentId: String, type: ContentType)
}

protocol GameConfigRepositoryProtocol {
    func getPhysicsConfig() -> PhysicsConfig
    func getUIConfig() -> UIConfig
    func getEnvironmentConfig(for type: Environment.EnvironmentType) -> EnvironmentConfig
}
```

### ViewModel Design

#### Base ViewModel with Observation Framework

```swift
import Observation

protocol ViewModelProtocol {
    func handle(_ action: ViewAction)
}

@Observable
class BaseViewModel: ViewModelProtocol {
    func handle(_ action: ViewAction) {
        // Override in subclasses
    }
}
```

#### Game ViewModel with Observation

```swift
import Observation
import SwiftData

@Observable
class GameViewModel: BaseViewModel {
    var gameState: GameState = GameState.initial
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let gameService: GameServiceProtocol
    private let physicsService: PhysicsServiceProtocol
    private let audioService: AudioServiceProtocol
    private let modelContext: ModelContext
    
    init(
        gameService: GameServiceProtocol,
        physicsService: PhysicsServiceProtocol,
        audioService: AudioServiceProtocol,
        modelContext: ModelContext
    ) {
        self.gameService = gameService
        self.physicsService = physicsService
        self.audioService = audioService
        self.modelContext = modelContext
    }
    
    func startGame(mode: GameMode) {
        gameState = GameState(
            mode: mode,
            status: .playing,
            score: 0,
            distance: 0,
            timeElapsed: 0,
            coinsCollected: 0
        )
    }
    
    func pauseGame() {
        gameState = GameState(
            mode: gameState.mode,
            status: .paused,
            score: gameState.score,
            distance: gameState.distance,
            timeElapsed: gameState.timeElapsed,
            coinsCollected: gameState.coinsCollected
        )
    }
    
    func handleTiltInput(x: CGFloat, y: CGFloat) {
        // Coordinate with physics service
    }
}
```

## Data Models

### Refactored Models

#### Game State (Value Object)
```swift
struct GameState {
    let mode: GameMode
    let status: GameStatus
    let score: Int
    let distance: Float
    let timeElapsed: TimeInterval
    let coinsCollected: Int
    
    static let initial = GameState(
        mode: .freePlay,
        status: .notStarted,
        score: 0,
        distance: 0,
        timeElapsed: 0,
        coinsCollected: 0
    )
}
```

#### Player Data (SwiftData Model)
```swift
import SwiftData
import Foundation

@Model
class PlayerData {
    @Attribute(.unique) var id: UUID
    var level: Int
    var experiencePoints: Int
    var totalScore: Int
    var totalDistance: Float
    var unlockedContent: [String]
    var selectedAirplaneType: String
    var selectedFoldType: String
    var selectedDesignType: String
    var createdAt: Date
    var lastPlayedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade) var gameResults: [GameResult]
    @Relationship(deleteRule: .cascade) var achievements: [Achievement]
    
    init(
        id: UUID = UUID(),
        level: Int = 1,
        experiencePoints: Int = 0,
        totalScore: Int = 0,
        totalDistance: Float = 0,
        unlockedContent: [String] = ["basic"],
        selectedAirplaneType: String = "basic",
        selectedFoldType: String = "basic",
        selectedDesignType: String = "plain"
    ) {
        self.id = id
        self.level = level
        self.experiencePoints = experiencePoints
        self.totalScore = totalScore
        self.totalDistance = totalDistance
        self.unlockedContent = unlockedContent
        self.selectedAirplaneType = selectedAirplaneType
        self.selectedFoldType = selectedFoldType
        self.selectedDesignType = selectedDesignType
        self.createdAt = Date()
        self.lastPlayedAt = Date()
        self.gameResults = []
        self.achievements = []
    }
}

@Model
class GameResult {
    var id: UUID
    var mode: String
    var score: Int
    var distance: Float
    var timeElapsed: TimeInterval
    var coinsCollected: Int
    var environmentType: String
    var completedAt: Date
    
    // Relationship
    var player: PlayerData?
    
    init(
        mode: String,
        score: Int,
        distance: Float,
        timeElapsed: TimeInterval,
        coinsCollected: Int,
        environmentType: String
    ) {
        self.id = UUID()
        self.mode = mode
        self.score = score
        self.distance = distance
        self.timeElapsed = timeElapsed
        self.coinsCollected = coinsCollected
        self.environmentType = environmentType
        self.completedAt = Date()
    }
}

@Model
class Achievement {
    @Attribute(.unique) var id: String
    var title: String
    var description: String
    var isUnlocked: Bool
    var unlockedAt: Date?
    var progress: Double
    var targetValue: Double
    
    // Relationship
    var player: PlayerData?
    
    init(
        id: String,
        title: String,
        description: String,
        targetValue: Double
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isUnlocked = false
        self.progress = 0.0
        self.targetValue = targetValue
    }
}
```

### Service Layer

#### Game Service
```swift
protocol GameServiceProtocol {
    func startGame(mode: GameMode) -> GameSession
    func pauseGame(session: GameSession)
    func endGame(session: GameSession) -> GameResult
    func updateScore(session: GameSession, points: Int)
}

class GameService: GameServiceProtocol {
    private let playerRepository: PlayerDataRepositoryProtocol
    private let achievementService: AchievementServiceProtocol
    
    init(
        playerRepository: PlayerDataRepositoryProtocol,
        achievementService: AchievementServiceProtocol
    ) {
        self.playerRepository = playerRepository
        self.achievementService = achievementService
    }
    
    // Implementation follows SRP - only handles game session logic
}
```

## Error Handling

### Centralized Error Management

```swift
enum GameError: Error, LocalizedError {
    case gameNotStarted
    case invalidGameState
    case physicsEngineError(String)
    case gameCenterError(String)
    case dataCorruption
    
    var errorDescription: String? {
        switch self {
        case .gameNotStarted:
            return "Game has not been started"
        case .invalidGameState:
            return "Invalid game state transition"
        case .physicsEngineError(let message):
            return "Physics error: \(message)"
        case .gameCenterError(let message):
            return "Game Center error: \(message)"
        case .dataCorruption:
            return "Game data is corrupted"
        }
    }
}
```

## Testing Strategy

### Unit Testing Approach

1. **ViewModels**: Test all business logic and state transitions
2. **Services**: Test service contracts and error handling
3. **Models**: Test business rules and data validation
4. **Repositories**: Test data persistence and retrieval

### Test Structure

```swift
class GameViewModelTests: XCTestCase {
    var sut: GameViewModel!
    var mockGameService: MockGameService!
    var mockPhysicsService: MockPhysicsService!
    var mockAudioService: MockAudioService!
    
    override func setUp() {
        super.setUp()
        mockGameService = MockGameService()
        mockPhysicsService = MockPhysicsService()
        mockAudioService = MockAudioService()
        
        sut = GameViewModel(
            gameService: mockGameService,
            physicsService: mockPhysicsService,
            audioService: mockAudioService
        )
    }
    
    func testStartGame_UpdatesStateCorrectly() {
        // Given
        let initialState = sut.state
        
        // When
        sut.startGame(mode: .freePlay)
        
        // Then
        XCTAssertNotEqual(sut.state.status, initialState.status)
        XCTAssertEqual(sut.state.mode, .freePlay)
    }
}
```

### Dependency Injection Container

```swift
class DIContainer {
    private var services: [String: Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        services[key] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let factory = services[key] as? () -> T else {
            fatalError("Service \(key) not registered")
        }
        return factory()
    }
}
```

## Migration Strategy

### Phase 1: Extract Services
1. Create service protocols
2. Extract existing manager functionality into services
3. Implement dependency injection container

### Phase 2: Create ViewModels
1. Create base ViewModel classes
2. Extract presentation logic from scenes
3. Implement state management

### Phase 3: Refactor Models
1. Separate data models from business logic
2. Create value objects for game state
3. Implement repository pattern

### Phase 4: Update Views
1. Refactor scenes to use ViewModels
2. Remove direct model dependencies
3. Implement proper data binding

### Phase 5: Testing & Validation
1. Add comprehensive unit tests
2. Validate all functionality works
3. Performance testing and optimization