# Requirements Document

## Introduction

This specification outlines the architectural refactoring of Tiny Pilots to implement proper MVVM (Model-View-ViewModel) structure and ensure all files adhere to Single Responsibility Principle (SRP) and SOLID principles. The current codebase has mixed architectural patterns and some classes that handle multiple responsibilities, which makes the code harder to maintain, test, and extend.

## Requirements

### Requirement 1

**User Story:** As a developer, I want the codebase to follow MVVM architecture, so that the separation of concerns is clear and the code is more maintainable.

#### Acceptance Criteria

1. WHEN examining the project structure THEN the code SHALL be organized into distinct Model, View, and ViewModel layers
2. WHEN looking at View classes THEN they SHALL only handle UI presentation and user interaction
3. WHEN examining ViewModel classes THEN they SHALL contain presentation logic and coordinate between Models and Views
4. WHEN reviewing Model classes THEN they SHALL only contain data structures and business logic
5. WHEN analyzing dependencies THEN Views SHALL NOT directly access Models, but only through ViewModels

### Requirement 2

**User Story:** As a developer, I want each class to follow the Single Responsibility Principle, so that each class has only one reason to change.

#### Acceptance Criteria

1. WHEN examining any class THEN it SHALL have only one primary responsibility
2. WHEN reviewing manager classes THEN they SHALL be split if they handle multiple unrelated concerns
3. WHEN looking at scene classes THEN they SHALL only handle scene-specific presentation logic
4. WHEN analyzing model classes THEN they SHALL only contain data and related business rules
5. WHEN checking utility classes THEN they SHALL provide only one type of functionality

### Requirement 3

**User Story:** As a developer, I want the code to follow SOLID principles, so that the system is flexible, maintainable, and extensible.

#### Acceptance Criteria

1. WHEN examining classes THEN they SHALL be open for extension but closed for modification (Open/Closed Principle)
2. WHEN reviewing interfaces THEN they SHALL be segregated so clients don't depend on methods they don't use (Interface Segregation Principle)
3. WHEN analyzing dependencies THEN high-level modules SHALL NOT depend on low-level modules, both SHALL depend on abstractions (Dependency Inversion Principle)
4. WHEN looking at inheritance hierarchies THEN derived classes SHALL be substitutable for their base classes (Liskov Substitution Principle)
5. WHEN checking class responsibilities THEN each class SHALL have only one reason to change (Single Responsibility Principle)

### Requirement 4

**User Story:** As a developer, I want proper folder structure that reflects MVVM architecture, so that code organization is intuitive and scalable.

#### Acceptance Criteria

1. WHEN examining the project structure THEN there SHALL be clear separation between Models, Views, and ViewModels folders
2. WHEN looking at the Models folder THEN it SHALL contain only data models and business logic classes
3. WHEN reviewing the Views folder THEN it SHALL contain only UI-related classes (Scenes, UI components)
4. WHEN checking the ViewModels folder THEN it SHALL contain classes that handle presentation logic
5. WHEN analyzing shared components THEN they SHALL be organized in appropriate subfolders (Services, Utilities, Extensions)

### Requirement 5

**User Story:** As a developer, I want dependency injection to be implemented, so that classes are loosely coupled and easily testable.

#### Acceptance Criteria

1. WHEN examining class constructors THEN dependencies SHALL be injected rather than created internally
2. WHEN reviewing manager classes THEN they SHALL depend on protocols/interfaces rather than concrete implementations
3. WHEN looking at ViewModels THEN they SHALL receive their dependencies through constructor injection
4. WHEN analyzing the dependency graph THEN there SHALL be no circular dependencies
5. WHEN checking testability THEN all dependencies SHALL be mockable for unit testing

### Requirement 6

**User Story:** As a developer, I want proper protocols and interfaces defined, so that the system is flexible and follows dependency inversion.

#### Acceptance Criteria

1. WHEN examining manager classes THEN they SHALL implement well-defined protocols
2. WHEN reviewing data access THEN there SHALL be repository protocols for data operations
3. WHEN looking at services THEN they SHALL be defined by interfaces that describe their contracts
4. WHEN analyzing ViewModels THEN they SHALL depend on protocol abstractions rather than concrete classes
5. WHEN checking protocol design THEN each protocol SHALL follow Interface Segregation Principle

### Requirement 7

**User Story:** As a developer, I want the refactored code to maintain all existing functionality, so that no features are broken during the architectural changes.

#### Acceptance Criteria

1. WHEN running the game THEN all existing gameplay features SHALL work exactly as before
2. WHEN testing Game Center integration THEN leaderboards and achievements SHALL function correctly
3. WHEN checking airplane physics THEN flight behavior SHALL remain unchanged
4. WHEN verifying environments THEN all environment types SHALL load and display properly
5. WHEN testing progression system THEN XP, levels, and unlocks SHALL work as expected

### Requirement 8

**User Story:** As a developer, I want comprehensive unit tests for the refactored architecture, so that the code quality and reliability are maintained.

#### Acceptance Criteria

1. WHEN examining ViewModels THEN they SHALL have unit tests covering all public methods
2. WHEN reviewing business logic THEN all critical paths SHALL be covered by tests
3. WHEN checking services THEN they SHALL have tests that verify their contracts
4. WHEN analyzing test coverage THEN it SHALL be at least 80% for business logic components
5. WHEN running tests THEN they SHALL be fast and independent of external dependencies