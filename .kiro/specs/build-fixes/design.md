# Design Document

## Overview

This design document outlines the systematic approach to resolve critical build issues in the Tiny Pilots iOS app. The solution addresses property mutability problems, missing type definitions, duplicate declarations, SwiftUI naming conflicts, and Codable conformance issues through targeted code fixes and architectural improvements.

## Architecture

### Build Issue Resolution Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    Build Issue Categories                    │
├─────────────────────────────────────────────────────────────┤
│  Property Issues │ Missing Types │ Duplicates │ Conflicts   │
├─────────────────────────────────────────────────────────────┤
│                    Resolution Approach                      │
├─────────────────────────────────────────────────────────────┤
│  1. Property Mutability Fixes                              │
│  2. Type Definition Creation                                │
│  3. Duplicate Removal & Consolidation                      │
│  4. Namespace Conflict Resolution                           │
│  5. Protocol Conformance Addition                           │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Property Mutability Fixes

#### SettingsViewModel Property Corrections
```swift
// Current problematic code:
class SettingsViewModel: ObservableObject {
    let audioService: AudioServiceProtocol  // ❌ Cannot be reassigned
    let physicsService: PhysicsServiceProtocol  // ❌ Cannot be reassigned
}

// Fixed implementation:
class SettingsViewModel: ObservableObject {
    var audioService: AudioServiceProtocol  // ✅ Can be reassigned
    var physicsService: PhysicsServiceProtocol  // ✅ Can be reassigned
    
    init(audioService: AudioServiceProtocol, physicsService: PhysicsServiceProtocol) {
        self.audioService = audioService
        self.physicsService = physicsService
    }
}
```

### 2. Missing Type Definitions

#### GameStateManager Implementation
```swift
import Foundation

protocol GameStateManagerProtocol {
    var currentState: GameState { get }
    var isGameActive: Bool { get }
    
    func startGame()
    func pauseGame()
    func endGame()
    func resetGame()
    func saveGameState()
    func loadGameState()
}

class GameStateManager: GameStateManagerProtocol, ObservableObject {
    static let shared = GameStateManager()
    
    @Published private(set) var currentState: GameState = .menu
    @Published private(set) var isGameActive: Bool = false
    
    private let logger = Logger.shared
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadGameState()
    }
    
    func startGame() {
        logger.info("Starting game", category: .game)
        currentState = .playing
        isGameActive = true
        saveGameState()
    }
    
    func pauseGame() {
        guard isGameActive else { return }
        logger.info("Pausing game", category: .game)
        currentState = .paused
        saveGameState()
    }
    
    func endGame() {
        logger.info("Ending game", category: .game)
        currentState = .gameOver
        isGameActive = false
        saveGameState()
    }
    
    func resetGame() {
        logger.info("Resetting game", category: .game)
        currentState = .menu
        isGameActive = false
        saveGameState()
    }
    
    func saveGameState() {
        let stateData = try? JSONEncoder().encode(currentState)
        userDefaults.set(stateData, forKey: "gameState")
        userDefaults.set(isGameActive, forKey: "isGameActive")
    }
    
    func loadGameState() {
        if let stateData = userDefaults.data(forKey: "gameState"),
           let state = try? JSONDecoder().decode(GameState.self, from: stateData) {
            currentState = state
        }
        isGameActive = userDefaults.bool(forKey: "isGameActive")
    }
}
```

#### GameManager Implementation
```swift
import Foundation
import SpriteKit

protocol GameManagerProtocol {
    var score: Int { get }
    var level: Int { get }
    var gameState: GameState { get }
    
    func initializeGame()
    func updateScore(_ points: Int)
    func nextLevel()
    func handleCollision(_ collision: CollisionType)
    func getGameConfiguration() -> GameConfiguration
}

class GameManager: GameManagerProtocol, ObservableObject {
    static let shared = GameManager()
    
    @Published private(set) var score: Int = 0
    @Published private(set) var level: Int = 1
    @Published private(set) var gameState: GameState = .menu
    
    private let gameStateManager = GameStateManager.shared
    private let logger = Logger.shared
    private let analytics = AnalyticsManager.shared
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe game state changes
        gameStateManager.$currentState
            .assign(to: \.gameState, on: self)
            .store(in: &cancellables)
    }
    
    func initializeGame() {
        logger.info("Initializing game", category: .game)
        score = 0
        level = 1
        gameStateManager.startGame()
        analytics.trackEvent(.gameStarted(mode: "normal"))
    }
    
    func updateScore(_ points: Int) {
        score += points
        logger.debug("Score updated: \(score)", category: .game)
        
        // Check for level progression
        if score >= level * 1000 {
            nextLevel()
        }
    }
    
    func nextLevel() {
        level += 1
        logger.info("Advanced to level \(level)", category: .game)
        analytics.trackEvent(.levelCompleted(level: level - 1))
    }
    
    func handleCollision(_ collision: CollisionType) {
        switch collision {
        case .obstacle:
            gameStateManager.endGame()
            analytics.trackEvent(.gameCompleted(mode: "normal", score: score, duration: 0))
        case .collectible:
            updateScore(100)
        case .powerUp:
            // Handle power-up logic
            break
        }
    }
    
    func getGameConfiguration() -> GameConfiguration {
        return GameConfiguration(
            level: level,
            difficulty: calculateDifficulty(),
            environmentType: getEnvironmentForLevel()
        )
    }
    
    private func calculateDifficulty() -> Float {
        return min(1.0 + Float(level) * 0.1, 3.0)
    }
    
    private func getEnvironmentForLevel() -> String {
        let environments = ["meadow", "alpine", "coastal", "urban", "desert"]
        return environments[(level - 1) % environments.count]
    }
    
    private var cancellables = Set<AnyCancellable>()
}

enum CollisionType {
    case obstacle
    case collectible
    case powerUp
}

struct GameConfiguration {
    let level: Int
    let difficulty: Float
    let environmentType: String
}
```

#### DeviceInfo Implementation
```swift
import UIKit

struct DeviceInfo {
    let modelName: String
    let systemVersion: String
    let screenSize: CGSize
    let screenScale: CGFloat
    let processorCount: Int
    let memorySize: UInt64
    let supportsProMotion: Bool
    let supportsMetalPerformanceShaders: Bool
    
    static var current: DeviceInfo {
        return DeviceInfo(
            modelName: UIDevice.current.modelName,
            systemVersion: UIDevice.current.systemVersion,
            screenSize: UIScreen.main.bounds.size,
            screenScale: UIScreen.main.scale,
            processorCount: ProcessInfo.processInfo.processorCount,
            memorySize: ProcessInfo.processInfo.physicalMemory,
            supportsProMotion: UIScreen.main.maximumFramesPerSecond > 60,
            supportsMetalPerformanceShaders: MTLCreateSystemDefaultDevice() != nil
        )
    }
    
    var isLowEndDevice: Bool {
        // Consider devices with less than 3GB RAM as low-end
        return memorySize < 3_000_000_000
    }
    
    var recommendedQualityLevel: QualityLevel {
        if isLowEndDevice {
            return .low
        } else if supportsProMotion {
            return .high
        } else {
            return .medium
        }
    }
}

enum QualityLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var particleCount: Int {
        switch self {
        case .low: return 50
        case .medium: return 100
        case .high: return 200
        }
    }
    
    var targetFrameRate: Int {
        switch self {
        case .low: return 30
        case .medium: return 60
        case .high: return 120
        }
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        
        // Map device identifiers to readable names
        switch identifier {
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        default: return identifier
        }
    }
}
```

### 3. Duplicate Declaration Resolution

#### MockNetworkService Consolidation
```swift
// Remove duplicate from WeeklySpecialService.swift and keep only in NetworkServiceProtocol.swift
// Or create a dedicated Mocks folder structure

// In Tiny PilotsTests/Mocks/MockNetworkService.swift
import Foundation

class MockNetworkService: NetworkServiceProtocol {
    var shouldReturnError = false
    var mockError: Error = NetworkError.connectionFailed
    var mockDelay: TimeInterval = 0
    
    func loadChallenge(code: String) async throws -> Challenge {
        if shouldReturnError {
            throw mockError
        }
        
        if mockDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        }
        
        return Challenge(
            id: "mock-\(code)",
            title: "Mock Challenge",
            description: "A test challenge",
            courseData: ChallengeData(
                environmentType: "meadow",
                obstacles: [],
                collectibles: [],
                weatherConditions: WeatherConfiguration.clear,
                targetScore: 1000
            ),
            expirationDate: Date().addingTimeInterval(86400),
            createdBy: "test-user"
        )
    }
    
    func loadWeeklySpecial() async throws -> WeeklySpecial {
        if shouldReturnError {
            throw mockError
        }
        
        return WeeklySpecial(
            id: "mock-weekly",
            title: "Mock Weekly Special",
            description: "A test weekly special",
            startDate: Date(),
            endDate: Date().addingTimeInterval(604800),
            challengeData: ChallengeData(
                environmentType: "alpine",
                obstacles: [],
                collectibles: [],
                weatherConditions: WeatherConfiguration.windy,
                targetScore: 2000
            )
        )
    }
}
```

#### GameViewModel handleTiltInput Deduplication
```swift
// In GameViewModel.swift - keep only one implementation
extension GameViewModel {
    func handleTiltInput(_ tiltData: TiltData) {
        guard gameState == .playing else { return }
        
        let adjustedTilt = TiltData(
            x: tiltData.x * tiltSensitivity,
            y: tiltData.y * tiltSensitivity,
            z: tiltData.z
        )
        
        physicsService.applyTilt(adjustedTilt)
        
        // Log tilt input for debugging
        logger.debug("Tilt input: x=\(adjustedTilt.x), y=\(adjustedTilt.y)", category: .game)
    }
}
```

### 4. SwiftUI Environment Conflict Resolution

#### Game Environment Renaming
```swift
// Rename the game's Environment class to GameEnvironment
import Foundation

struct GameEnvironment: Codable {
    let type: EnvironmentType
    let weatherConditions: WeatherConfiguration
    let windStrength: Float
    let obstacles: [ObstacleConfiguration]
    let collectibles: [CollectibleConfiguration]
    let backgroundLayers: [BackgroundLayer]
    
    static let meadow = GameEnvironment(
        type: .meadow,
        weatherConditions: .clear,
        windStrength: 0.3,
        obstacles: [],
        collectibles: [],
        backgroundLayers: []
    )
    
    static let alpine = GameEnvironment(
        type: .alpine,
        weatherConditions: .windy,
        windStrength: 0.7,
        obstacles: [],
        collectibles: [],
        backgroundLayers: []
    )
}

enum EnvironmentType: String, CaseIterable, Codable {
    case meadow = "Sunny Meadows"
    case alpine = "Alpine Heights"
    case coastal = "Coastal Breeze"
    case urban = "Urban Skyline"
    case desert = "Desert Canyon"
}

// Update all references throughout the codebase
// From: Environment.meadow
// To: GameEnvironment.meadow
```

### 5. Codable Conformance Additions

#### Required Codable Implementations
```swift
// Add Codable conformance to structs and enums that need serialization

extension GameState: Codable {}

extension TiltData: Codable {}

extension WeatherConfiguration: Codable {}

extension ObstacleConfiguration: Codable {}

extension CollectibleConfiguration: Codable {}

extension BackgroundLayer: Codable {}

extension Challenge: Codable {}

extension ChallengeData: Codable {}

extension WeeklySpecial: Codable {}

// For enums with associated values, implement custom Codable
extension AnalyticsEvent: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .gameStarted(let mode):
            try container.encode("gameStarted", forKey: .type)
            try container.encode(["mode": mode], forKey: .data)
        case .gameCompleted(let mode, let score, let duration):
            try container.encode("gameCompleted", forKey: .type)
            try container.encode([
                "mode": mode,
                "score": score,
                "duration": duration
            ], forKey: .data)
        // ... other cases
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let data = try container.decode([String: Any].self, forKey: .data)
        
        switch type {
        case "gameStarted":
            let mode = data["mode"] as? String ?? ""
            self = .gameStarted(mode: mode)
        case "gameCompleted":
            let mode = data["mode"] as? String ?? ""
            let score = data["score"] as? Int ?? 0
            let duration = data["duration"] as? TimeInterval ?? 0
            self = .gameCompleted(mode: mode, score: score, duration: duration)
        // ... other cases
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown event type")
            )
        }
    }
}
```

## Error Handling

### Build Error Prevention
- Implement comprehensive type checking before compilation
- Add automated tests to catch property mutability issues
- Create build scripts to validate type definitions exist
- Add linting rules to prevent duplicate declarations

### Conflict Resolution Strategy
- Use fully qualified type names when ambiguity exists
- Implement namespace prefixes for game-specific types
- Create type aliases for commonly conflicting names
- Add compiler directives to resolve import conflicts

## Testing Strategy

### Build Validation Testing
1. **Compilation Tests**
   - Automated build verification after each fix
   - Property access validation tests
   - Type resolution verification

2. **Integration Testing**
   - Test all fixed components work together
   - Validate no regressions introduced
   - Ensure proper dependency injection

3. **Regression Prevention**
   - Add build validation to CI/CD pipeline
   - Create automated checks for common issues
   - Implement code review guidelines

## Migration Strategy

### Phase 1: Property Fixes (Day 1)
1. Fix SettingsViewModel property declarations
2. Validate all property access patterns
3. Test ViewModel functionality

### Phase 2: Type Definitions (Day 1-2)
1. Create GameStateManager implementation
2. Implement GameManager class
3. Add DeviceInfo struct
4. Update all references

### Phase 3: Duplicate Removal (Day 2)
1. Consolidate MockNetworkService
2. Remove duplicate handleTiltInput
3. Validate no symbol conflicts

### Phase 4: Conflict Resolution (Day 2-3)
1. Rename Environment to GameEnvironment
2. Update all references throughout codebase
3. Test SwiftUI integration

### Phase 5: Codable Conformance (Day 3)
1. Add Codable to required types
2. Implement custom Codable for complex enums
3. Test serialization/deserialization

### Phase 6: Validation (Day 3)
1. Full project compilation test
2. Run all unit tests
3. Validate no build errors remain