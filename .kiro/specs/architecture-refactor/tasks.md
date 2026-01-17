# Implementation Plan

- [x] 1. Set up new folder structure and core infrastructure
  - Create new folder hierarchy following MVVM pattern
  - Implement dependency injection container
  - Create base protocols and abstract classes
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 1.1 Create new folder structure
  - Create Models/Entities, Models/ValueObjects, Models/BusinessLogic folders
  - Create ViewModels folder with appropriate subfolders
  - Create Services/Protocols and Services/Implementations folders
  - Create Core/DependencyInjection, Core/Extensions, Core/Utilities folders
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 1.2 Implement dependency injection container
  - Create DIContainer class with registration and resolution methods
  - Implement ServiceRegistration class for configuring dependencies
  - Create protocol-based service registration system
  - Write unit tests for dependency injection functionality
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 1.3 Create base ViewModel and protocol infrastructure using Observation
  - Implement ViewModelProtocol for common ViewModel behavior
  - Create BaseViewModel class using @Observable macro
  - Define ViewAction protocol for handling user interactions
  - Set up Observation framework for reactive state management
  - _Requirements: 1.3, 1.4, 3.3, 6.4_

- [x] 2. Extract and refactor service layer with SwiftData integration
  - Create service protocols for all major functionalities
  - Extract existing manager logic into service implementations
  - Set up SwiftData ModelContainer and ModelContext for data persistence
  - _Requirements: 2.2, 3.3, 5.2, 6.1, 6.2, 6.3_

- [x] 2.1 Create core service protocols and SwiftData setup
  - Define GameCenterServiceProtocol with authentication and leaderboard methods
  - Create AudioServiceProtocol for sound and music management
  - Implement PhysicsServiceProtocol for airplane physics calculations
  - Set up SwiftData ModelContainer with PlayerData, GameResult, and Achievement models
  - _Requirements: 6.1, 6.2, 6.5_

- [x] 2.2 Implement GameCenterService
  - Extract Game Center functionality from existing GameCenterManager
  - Implement GameCenterServiceProtocol with proper error handling
  - Add authentication, leaderboard, and achievement methods
  - Write unit tests with mocked Game Center dependencies
  - _Requirements: 2.1, 3.1, 5.2, 7.2_

- [x] 2.3 Implement AudioService
  - Extract audio functionality from existing SoundManager
  - Create AudioServiceProtocol implementation with volume controls
  - Add background music and sound effect management
  - Write unit tests for audio service functionality
  - _Requirements: 2.1, 3.1, 5.2_

- [x] 2.4 Implement PhysicsService
  - Extract physics calculations from PaperAirplane class
  - Create PhysicsServiceProtocol implementation for force calculations
  - Add collision detection and response methods
  - Write unit tests for physics calculations and airplane behavior
  - _Requirements: 2.1, 3.1, 5.2, 7.3_

- [x] 2.5 Configure SwiftData models and relationships
  - Create PlayerData, GameResult, and Achievement SwiftData models
  - Set up proper relationships between models using @Relationship
  - Configure ModelContainer with all required models
  - Write unit tests for SwiftData model operations and queries
  - _Requirements: 2.1, 3.3, 5.2, 6.2_

- [x] 3. Refactor data models following SRP
  - Separate business logic from data structures
  - Create value objects for game state
  - Implement proper entity relationships
  - _Requirements: 1.4, 2.1, 2.4, 3.1_

- [x] 3.1 Create GameState value object
  - Extract game state from GameManager into immutable value object
  - Implement GameState with mode, status, score, distance, and time properties
  - Add state transition methods following business rules
  - Write unit tests for state transitions and validation
  - _Requirements: 1.4, 2.1, 2.4_

- [x] 3.2 Create SwiftData PlayerData model
  - Convert PlayerData from struct to SwiftData @Model class
  - Add proper relationships to GameResult and Achievement models
  - Implement business rule validation within the model
  - Write unit tests for SwiftData model operations and queries
  - _Requirements: 1.4, 2.1, 2.4_

- [x] 3.3 Extract business logic classes
  - Create GameRules class for game logic validation
  - Implement PhysicsCalculations class for airplane physics
  - Add ProgressionLogic class for XP and level calculations
  - Write comprehensive unit tests for all business logic
  - _Requirements: 2.1, 2.4, 3.1_

- [x] 3.4 Refactor PaperAirplane model
  - Separate airplane data from physics behavior
  - Extract physics calculations to PhysicsService
  - Keep only airplane configuration and properties in model
  - Write unit tests for airplane model and physics integration
  - _Requirements: 2.1, 2.4, 7.3_

- [x] 4. Create ViewModels for all major screens
  - Implement GameViewModel for gameplay coordination
  - Create MainMenuViewModel for menu interactions
  - Add HangarViewModel for airplane customization
  - _Requirements: 1.1, 1.2, 1.3, 5.4_

- [x] 4.1 Implement GameViewModel
  - Create GameViewModel with game state management using @Observable
  - Add methods for starting, pausing, and ending games
  - Implement tilt input handling and physics coordination
  - Integrate with GameService, PhysicsService, AudioService, and SwiftData ModelContext
  - _Requirements: 1.1, 1.2, 1.3, 5.4_

- [x] 4.2 Create MainMenuViewModel
  - Implement MainMenuViewModel for menu navigation using @Observable
  - Add game mode selection and settings management
  - Integrate with SwiftData ModelContext for user preferences
  - Write unit tests for menu interactions and navigation
  - _Requirements: 1.1, 1.2, 1.3, 5.4_

- [x] 4.3 Implement HangarViewModel
  - Create HangarViewModel for airplane customization using @Observable
  - Add airplane selection and configuration methods
  - Integrate with SwiftData ModelContext for unlocked content queries
  - Write unit tests for customization logic and validation
  - _Requirements: 1.1, 1.2, 1.3, 5.4_

- [x] 4.4 Create SettingsViewModel
  - Implement SettingsViewModel for game configuration
  - Add audio, graphics, and control settings management
  - Integrate with appropriate services for settings persistence
  - Write unit tests for settings validation and persistence
  - _Requirements: 1.1, 1.2, 1.3, 5.4_

- [x] 5. Refactor Views to use ViewModels
  - Update SpriteKit scenes to use ViewModels
  - Remove direct model dependencies from views
  - Implement proper data binding and state observation
  - _Requirements: 1.1, 1.2, 1.5, 7.1_

- [x] 5.1 Refactor GameScene
  - Update GameScene to use GameViewModel instead of GameManager
  - Remove direct access to models and services
  - Implement proper state observation and UI updates
  - Ensure all gameplay functionality remains intact
  - _Requirements: 1.1, 1.2, 1.5, 7.1, 7.3_

- [x] 5.2 Update MainMenuScene
  - Refactor MainMenuScene to use MainMenuViewModel
  - Remove direct dependencies on GameManager and other services
  - Implement proper navigation and state management
  - Verify all menu functionality works correctly
  - _Requirements: 1.1, 1.2, 1.5, 7.1_

- [x] 5.3 Refactor HangarScene
  - Update HangarScene to use HangarViewModel
  - Remove direct model access for airplane customization
  - Implement proper airplane preview and selection
  - Ensure customization features work as expected
  - _Requirements: 1.1, 1.2, 1.5, 7.1_

- [x] 5.4 Update remaining scenes and UI components
  - Refactor GameModeSelectionScene with appropriate ViewModel
  - Update UI overlays to use ViewModels for data binding
  - Remove any remaining direct model dependencies from views
  - Verify all UI functionality remains intact
  - _Requirements: 1.1, 1.2, 1.5, 7.1_

- [x] 6. Configure dependency injection and service registration
  - Set up service registration in application startup
  - Configure dependency injection for all ViewModels
  - Implement proper service lifecycle management
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 6.1 Configure service registration
  - Set up DIContainer configuration in AppDelegate
  - Register all service implementations with their protocols
  - Configure singleton vs transient service lifetimes
  - Add proper error handling for missing dependencies
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 6.2 Implement ViewModel factory
  - Create ViewModelFactory for ViewModel instantiation
  - Configure dependency injection for all ViewModels
  - Add proper error handling for ViewModel creation
  - Write unit tests for ViewModel factory functionality
  - _Requirements: 5.1, 5.2, 5.4_

- [x] 6.3 Update application startup
  - Modify AppDelegate to configure dependency injection
  - Set up service registration and ViewModel factory
  - Ensure proper initialization order for all dependencies
  - Add error handling for startup configuration failures
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 7. Add comprehensive unit tests
  - Write tests for all ViewModels and business logic
  - Create mock implementations for all service protocols
  - Achieve minimum 80% code coverage for business logic
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 7.1 Create mock service implementations
  - Implement MockGameCenterService for testing
  - Create MockAudioService and MockPhysicsService
  - Add MockDataPersistenceService for repository testing
  - Write helper methods for common test scenarios
  - _Requirements: 8.5_

- [x] 7.2 Write ViewModel unit tests
  - Create comprehensive tests for GameViewModel state management
  - Add tests for MainMenuViewModel navigation logic
  - Write tests for HangarViewModel customization features
  - Test all ViewModel error handling and edge cases
  - _Requirements: 8.1, 8.4_

- [x] 7.3 Add service and repository tests
  - Write unit tests for all service implementations
  - Create tests for repository data operations
  - Add integration tests for service interactions
  - Test error handling and recovery scenarios
  - _Requirements: 8.2, 8.3, 8.4_

- [x] 7.4 Create business logic tests
  - Write comprehensive tests for GameRules validation
  - Add tests for PhysicsCalculations accuracy
  - Create tests for ProgressionLogic XP and level calculations
  - Test all business rule edge cases and validation
  - _Requirements: 8.2, 8.4_

- [x] 8. Integration testing and validation
  - Verify all existing functionality works correctly
  - Test performance impact of architectural changes
  - Validate Game Center integration still functions
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 8.1 Functional integration testing
  - Test complete gameplay flow from start to finish
  - Verify airplane physics and controls work correctly
  - Test all game modes and environment switching
  - Validate progression system and unlocks function properly
  - _Requirements: 7.1, 7.3, 7.4, 7.5_

- [x] 8.2 Game Center integration testing
  - Test authentication and leaderboard submission
  - Verify achievement tracking and unlocking
  - Test offline/online mode transitions
  - Validate all Game Center features work as expected
  - _Requirements: 7.2_

- [x] 8.3 Performance validation
  - Measure frame rate and memory usage impact
  - Test loading times for scenes and game modes
  - Validate 60 FPS target is maintained
  - Optimize any performance regressions found
  - _Requirements: 7.1_

- [x] 8.4 Clean up legacy code
  - Remove old manager classes that have been replaced
  - Delete unused code and commented-out sections
  - Update documentation and code comments
  - Verify no dead code remains in the project
  - _Requirements: 2.1, 2.2_