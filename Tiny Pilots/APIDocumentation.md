# Tiny Pilots - API Interface Documentation

This document outlines the key interfaces between major components of the Tiny Pilots game.

## 1. GameManager

The `GameManager` is the central component that manages game state and player data.

### Public Properties

| Property | Type | Description | Access |
|----------|------|-------------|--------|
| `shared` | `GameManager` | Singleton instance | `static let` |
| `currentState` | `GameState` | Current game state (notStarted, playing, paused, gameOver) | `private(set)` |
| `currentMode` | `GameMode` | Current game mode (freePlay, challenge, dailyRun, tutorial) | `private(set)` |
| `score` | `Int` | Current game score | `private(set)` |
| `distanceTraveled` | `Float` | Distance traveled in meters | `private(set)` |
| `gameTime` | `TimeInterval` | Game time in seconds | `private(set)` |
| `playerData` | `PlayerData` | Player progression data | `var` |

### Public Methods

```swift
func setGameMode(_ mode: GameMode)
```
Sets the current game mode.

```swift
func startGame()
```
Initializes and starts a new game.

```swift
func pauseGame()
```
Pauses the current game.

```swift
func resumeGame()
```
Resumes a paused game.

```swift
func endGame()
```
Ends the current game and updates player data.

```swift
func update(_ currentTime: TimeInterval)
```
Updates game state based on the current time.

```swift
func addDistance(_ distance: Float)
```
Adds to the distance traveled.

```swift
func addCoin()
```
Increments the coin counter and indirectly updates score.

```swift
func adjustScoreForObstacle()
```
Reduces score when colliding with obstacles.

### Notifications

| Notification Name | User Info | Description |
|-------------------|-----------|-------------|
| `gameDidStart` | None | Fired when a game starts |
| `gameDidPause` | None | Fired when a game is paused |
| `gameDidResume` | None | Fired when a game is resumed |
| `gameDidEnd` | `[earnedXP: Int]` | Fired when a game ends |
| `playerDidLevelUp` | `[level: Int]` | Fired when player levels up |
| `contentDidUnlock` | `[type: String, id: Any]` | Fired when content is unlocked |
| `newHighScoreAchieved` | `[score: Int]` | Fired when a new high score is achieved |
| `environmentDidChange` | `[environment: String]` | Fired when environment changes |
| `challengeCompleted` | `[challengeID: String]` | Fired when a challenge is completed |

## 2. GameCenterManager

The `GameCenterManager` handles all Game Center integration.

### Public Properties

| Property | Type | Description | Access |
|----------|------|-------------|--------|
| `shared` | `GameCenterManager` | Singleton instance | `static let` |
| `isGameCenterAvailable` | `Bool` | Whether Game Center is available | `private(set)` |
| `presentingViewController` | `UIViewController?` | View controller to present Game Center UI from | `weak var` |

### Public Methods

```swift
func authenticatePlayer(completion: ((Bool, Error?) -> Void)? = nil)
```
Authenticates the player with Game Center.

```swift
func submitScore(_ score: Int, to leaderboardID: String, completion: ((Error?) -> Void)? = nil)
```
Submits a score to a specific leaderboard.

```swift
func submitDailyRunScore(_ score: Int)
```
Submits a score to the daily run leaderboard.

```swift
func submitTotalDistance(_ distance: Int)
```
Submits a distance to the total distance leaderboard.

```swift
func submitBestScore(_ score: Int)
```
Submits a score to the best score leaderboard.

```swift
func showLeaderboards()
```
Shows the Game Center leaderboards UI.

```swift
func reportAchievement(identifier: String, percentComplete: Double, completion: ((Error?) -> Void)? = nil)
```
Reports progress for an achievement.

```swift
func showAchievements()
```
Shows the Game Center achievements UI.

```swift
func generateChallengeCode(for course: String) -> String
```
Generates a challenge code for a custom course.

```swift
func processChallengeCode(_ code: String) -> (String?, GameCenterError?)
```
Processes a challenge code and returns the course ID or an error.

```swift
func validateChallengeCode(_ code: String, completion: @escaping (Result<String, Error>) -> Void)
```
Validates a challenge code asynchronously.

```swift
func challengeFriend(withCode code: String)
```
Challenges a friend with a specific code.

```swift
func trackAchievementProgress()
```
Updates achievement progress based on player data.

```swift
func resetAllAchievements()
```
Resets all achievements (for testing).

```swift
func showError(_ error: Error, in viewController: UIViewController? = nil)
```
Shows an error alert.

```swift
func showChallengeUI()
```
Shows the challenge UI.

## 3. GameEnvironment

The `GameEnvironment` class manages the game environment and its elements.

### Public Properties

| Property | Type | Description | Access |
|----------|------|-------------|--------|
| `type` | `EnvironmentType` | The type of environment | `private let` |

### Public Methods

```swift
init(type: EnvironmentType, size: CGSize)
```
Initializes an environment with a specific type and size.

```swift
func addObstacle(at position: CGPoint) -> SKNode
```
Adds an obstacle at a specific position.

```swift
func addCollectible(at position: CGPoint) -> SKNode
```
Adds a collectible at a specific position.

## 4. PaperAirplane

The `PaperAirplane` class represents the player-controlled airplane.

### Public Properties

| Property | Type | Description | Access |
|----------|------|-------------|--------|
| `type` | `AirplaneType` | The type of airplane | `private let` |

### Public Methods

```swift
init(type: AirplaneType)
```
Initializes an airplane with a specific type.

```swift
func applyForces(tiltX: CGFloat, tiltY: CGFloat)
```
Applies forces to the airplane based on device tilt.

```swift
func updateVisualState()
```
Updates the visual state of the airplane based on its physics.

## 5. FlightScene

The `FlightScene` class is the main game scene.

### Public Methods

```swift
init(size: CGSize, mode: GameManager.GameMode)
```
Initializes a flight scene with a specific size and game mode.

```swift
init(size: CGSize, challengeCode: String)
```
Initializes a flight scene with a challenge code.

## Error Handling

### GameCenterError

```swift
enum GameCenterError: Error {
    case notAuthenticated
    case leaderboardNotFound
    case achievementNotFound
    case submissionFailed
    case invalidChallengeCode
    case challengeExpired
    case networkError
}
```

## Data Structures

### PlayerData

```swift
struct PlayerData {
    var level: Int
    var experiencePoints: Int
    var totalScore: Int
    var totalDistance: Float
    var totalFlightTime: TimeInterval
    var dailyRunStreak: Int
    var lastDailyRunDate: Date?
    var unlockedAirplanes: Set<String>
    var unlockedEnvironments: Set<String>
    var completedChallenges: Int
    var selectedFoldType: PaperAirplane.FoldType
    var selectedDesignType: PaperAirplane.DesignType
}
```

### PhysicsCategory

```swift
struct PhysicsCategory {
    static let none: UInt32
    static let all: UInt32
    static let airplane: UInt32
    static let obstacle: UInt32
    static let collectible: UInt32
    static let ground: UInt32
    static let boundary: UInt32
}
``` 