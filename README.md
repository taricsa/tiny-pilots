# Tiny Pilots

A premium iOS game that offers players an engaging and relaxing experience of flying paper airplanes through various environments. Built with SpriteKit for high-quality 2D rendering and realistic physics.

## Features

- Realistic paper airplane physics
- Multiple unique environments
- Unlockable paper plane designs
- Special challenge modes
- Personal best tracking and achievements
- Global leaderboards
- Friend challenges via share codes
- Weekly special courses
- Seasonal themed updates

## Project Structure

The project is organized into the following directories:

- `Scenes/`: Game scenes for different environments and game modes
- `Models/`: Data models and game state
- `Managers/`: Service classes for physics, game state, etc.
- `UI/`: User interface components
- `Resources/`: Assets, sounds, and other resources
- `Utils/`: Utility functions and game configuration

## Development Requirements

- Xcode 14.0+
- Swift 6.0+
- iOS 16.0+
- iPhone 8 or newer / iPad 5th generation or newer

## Setup and Installation

1. Clone the repository
2. Open `Tiny Pilots.xcodeproj` in Xcode
3. Build and run the project on a device or simulator

## Game Mechanics

Tiny Pilots features tilt-based controls for navigating paper airplanes through beautifully crafted environments. Players can:

- Customize their paper airplane designs, affecting flight characteristics
- Navigate through wind currents and obstacles
- Collect items to gain XP and unlock new content
- Compete in daily challenges and friend competitions

## Performance Goals

- 60 FPS (120 FPS on ProMotion displays)
- Initial load under 3 seconds
- Level loads under 1 second

## License

© 2025. All rights reserved.

# Tiny Pilots - Environment System

## Overview
The environment system in Tiny Pilots provides diverse, interactive game worlds with unique visual elements, physics properties, and gameplay mechanics. Each environment offers a distinct experience through custom obstacles, collectibles, weather conditions, and visual effects.

## Environments

### Available Environments
1. **Sunny Meadows** (Default)
   - Light wind conditions
   - Tree and fence obstacles
   - Grassy terrain with rolling hills
   - Unlocked by default

2. **Alpine Heights**
   - Strong wind conditions
   - Mountain and rock obstacles
   - Snowy terrain with peaks
   - Unlocks at level 5

3. **Coastal Breeze**
   - Variable wind conditions
   - Palm trees and umbrella obstacles
   - Sandy beach terrain
   - Unlocks at level 10

4. **Urban Skyline**
   - Variable wind conditions
   - Buildings and billboard obstacles
   - City terrain with skyscrapers
   - Unlocks at level 15

5. **Desert Canyon**
   - Strong wind conditions
   - Mesa and cactus obstacles
   - Rocky canyon terrain
   - Unlocks at level 20

### Environment Features
- **Dynamic Weather**: Each environment has unique wind patterns and weather conditions
- **Parallax Backgrounds**: Multi-layered backgrounds create depth and immersion
- **Interactive Elements**: Environment-specific obstacles and collectibles
- **Visual Effects**: Custom particle effects and animations
- **Ambient Audio**: Environment-specific sound effects and music

## Technical Implementation

### Core Classes
- `Environment`: Manages environment properties and configuration
- `ParallaxBackground`: Handles multi-layered scrolling backgrounds
- `Obstacle`: Represents environment-specific obstacles
- `Collectible`: Manages collectible items

### Physics Integration
- Wind effects through `PhysicsManager`
- Environment-specific physics properties
- Collision detection and response

### Visual Effects
- Custom particle systems for wind and weather
- Environment-specific textures and colors
- Dynamic lighting and atmospheric effects

## Usage

### Selecting Environments
```swift
// Set environment through GameManager
GameManager.shared.setEnvironment(type: .meadow)

// Check available environments
let availableEnvironments = GameManager.shared.getAvailableEnvironments()

// Check if environment is unlocked
let isUnlocked = Environment.EnvironmentType.mountains.isUnlocked
```

### Customizing Environments
```swift
// Create custom environment
let environment = Environment(type: .beach)
environment.weatherCondition = .strongWind

// Add custom obstacles
let obstacle = Obstacle(type: .palmTree)
obstacle.position(at: CGPoint(x: 100, y: 100))

// Add collectibles
let collectible = Collectible(type: .star)
collectible.position(at: CGPoint(x: 200, y: 200))
```

## Asset Requirements

### Textures
- Background textures for each environment
- Ground textures
- Obstacle textures
- Collectible textures
- Particle effect textures

### Audio
- Environment-specific ambient sounds
- Weather effect sounds
- Collision sounds
- Collection sounds

## Contributing
When adding new environments:
1. Add the environment type to `EnvironmentType`
2. Create configuration method in `Environment`
3. Add required assets
4. Update unlock requirements in `GameConfig`
5. Test with all game modes 