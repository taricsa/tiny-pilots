# Requirements Document

## Introduction

This specification addresses critical build issues preventing the Tiny Pilots iOS app from compiling successfully. The codebase has undergone architecture refactoring but still contains several compilation errors including property mutability issues, missing type definitions, duplicate declarations, naming conflicts, and missing protocol conformances that must be resolved before the app can build and run.

## Requirements

### Requirement 1

**User Story:** As a developer, I want all property mutability issues resolved, so that the code compiles without property access errors.

#### Acceptance Criteria

1. WHEN accessing audioService and physicsService in SettingsViewModel THEN they SHALL be declared as var instead of let to allow mutation
2. WHEN the compiler checks property declarations THEN all properties SHALL have correct mutability modifiers
3. WHEN services need to be reassigned or modified THEN their property declarations SHALL support the required operations
4. WHEN building the project THEN no property mutability compilation errors SHALL occur

### Requirement 2

**User Story:** As a developer, I want all missing type definitions created, so that referenced types exist and can be used throughout the codebase.

#### Acceptance Criteria

1. WHEN GameStateManager is referenced in View files THEN it SHALL exist as a proper class or struct
2. WHEN GameManager is referenced in FlightScene and GameViewController THEN it SHALL be defined with required functionality
3. WHEN DeviceInfo is referenced in PerformanceDashboard and PerformanceBenchmarkManager THEN it SHALL provide device capability information
4. WHEN the compiler resolves type references THEN all referenced types SHALL be found and accessible
5. WHEN building the project THEN no "undefined type" compilation errors SHALL occur

### Requirement 3

**User Story:** As a developer, I want all duplicate declarations removed, so that the compiler doesn't encounter conflicting definitions.

#### Acceptance Criteria

1. WHEN MockNetworkService is defined THEN it SHALL exist in only one location (either NetworkServiceProtocol.swift or WeeklySpecialService.swift)
2. WHEN handleTiltInput method is declared THEN it SHALL appear only once in GameViewModel.swift
3. WHEN the compiler processes declarations THEN no duplicate symbol errors SHALL occur
4. WHEN building the project THEN all type and method names SHALL be unique within their scope
5. WHEN resolving symbols THEN the compiler SHALL find exactly one definition for each symbol

### Requirement 4

**User Story:** As a developer, I want SwiftUI Environment naming conflicts resolved, so that both the game's Environment class and SwiftUI's @Environment can coexist.

#### Acceptance Criteria

1. WHEN using the game's Environment class THEN it SHALL be renamed to GameEnvironment or use fully qualified names
2. WHEN using SwiftUI's @Environment property wrapper THEN it SHALL not conflict with game types
3. WHEN importing SwiftUI and game modules THEN type resolution SHALL be unambiguous
4. WHEN building SwiftUI views THEN no naming conflicts SHALL occur between Environment types
5. WHEN the compiler resolves Environment references THEN it SHALL correctly identify the intended type

### Requirement 5

**User Story:** As a developer, I want all required Codable conformances added, so that data serialization and persistence work correctly.

#### Acceptance Criteria

1. WHEN structs need to be serialized THEN they SHALL conform to Codable protocol
2. WHEN enums are used in Codable types THEN they SHALL conform to Codable protocol
3. WHEN data persistence is required THEN all related types SHALL support encoding and decoding
4. WHEN JSON serialization occurs THEN all properties SHALL be properly codable
5. WHEN building the project THEN no Codable conformance compilation errors SHALL occur