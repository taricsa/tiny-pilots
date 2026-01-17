# Project Structure & Architecture

## Folder Organization

### Core Application (`Tiny Pilots/`)
- **Scenes/**: SpriteKit scene classes for different game screens
  - `GameScene.swift`: Main gameplay scene
  - `MainMenuScene.swift`: Main menu interface
  - `FlightScene.swift`: Flight simulation scene
  - `HangarScene.swift`: Airplane customization scene
  - `GameModeSelectionScene.swift`: Game mode selection

- **Models/**: Data models and game entities
  - `PaperAirplane.swift`: Airplane physics and behavior
  - `Environment.swift`: Environment configurations
  - `Obstacle.swift`: Obstacle definitions
  - `Collectible.swift`: Collectible items
  - `ParallaxBackground.swift`: Background rendering

- **Managers/**: Service classes following singleton pattern
  - `GameManager.swift`: Core game state management
  - `GameCenterManager.swift`: Game Center integration
  - `PhysicsManager.swift`: Physics simulation
  - `SoundManager.swift`: Audio management
  - `GameStateManager.swift`: State persistence

- **Views/**: SwiftUI/UIKit view components
  - UI components for menus and overlays
  - Game mode selection interfaces
  - Settings and customization screens

- **UI/**: SpriteKit UI overlays
  - `ProgressionOverlay.swift`: In-game progression display
  - `GameCenterView.swift`: Game Center integration UI

- **Utils/**: Utility classes and configurations
  - `GameConfig.swift`: Game constants and settings
  - `PhysicsCategory.swift`: Physics collision categories

- **Resources/**: Game assets
  - `Assets.xcassets/`: Images and textures
  - `*.sks`: SpriteKit scene files and particle effects

### Test Targets
- `Tiny PilotsTests/`: Unit tests for managers and game logic
- `Tiny PilotsUITests/`: UI automation tests

## Architecture Patterns

### Singleton Pattern
- Used for managers (`GameManager.shared`, `GameCenterManager.shared`)
- Ensures single source of truth for game state

### MVC/MVVM Hybrid
- Models: Game entities and data structures
- Views: SpriteKit scenes and SwiftUI components  
- Controllers: Manager classes coordinate between models and views

### Physics-Driven Architecture
- SpriteKit physics engine handles airplane movement
- Custom physics categories for collision detection
- Realistic flight simulation through force application

## Naming Conventions

### Swift Code Style
- Classes: PascalCase (`GameManager`, `PaperAirplane`)
- Properties/Methods: camelCase (`currentState`, `startGame()`)
- Constants: camelCase with descriptive names
- Enums: PascalCase with lowercase raw values where applicable

### File Organization
- Group related functionality in folders
- Use descriptive file names matching class names
- Separate concerns (UI, logic, data, resources)

### Asset Naming
- Use descriptive, hierarchical names
- Follow Apple's asset naming conventions
- Include resolution suffixes (@2x, @3x) where needed