//
//  ViewModelFactoryTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
import SwiftData
import SpriteKit
import GameKit
import CoreMotion
@testable import Tiny_Pilots

final class ViewModelFactoryTests: XCTestCase {
    
    var sut: ViewModelFactory!
    var mockContainer: DIContainer!
    var mockModelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        
        // Create a separate container for testing
        mockContainer = DIContainer()
        
        // Create an in-memory model context for testing
        do {
            let schema = Schema([
                PlayerData.self,
                GameResult.self,
                Achievement.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            mockModelContext = ModelContext(container)
        } catch {
            XCTFail("Failed to create test ModelContext: \(error)")
        }
        
        // Set up test service registration
        setupTestServices()
        
        sut = ViewModelFactory(container: mockContainer)
    }
    
    override func tearDown() {
        sut = nil
        mockContainer.clear()
        mockContainer = nil
        mockModelContext = nil
        super.tearDown()
    }
    
    // MARK: - Test Setup Helpers
    
    private func setupTestServices() {
        // Register ModelContext
        mockContainer.registerSingleton(ModelContext.self, instance: mockModelContext)
        
        // Register mock services
        mockContainer.register(AudioServiceProtocol.self, lifetime: .singleton) { _ in
            return MockAudioService()
        }
        
        mockContainer.register(PhysicsServiceProtocol.self, lifetime: .singleton) { _ in
            return MockPhysicsService()
        }
        
        mockContainer.register(GameCenterServiceProtocol.self, lifetime: .singleton) { _ in
            return MockGameCenterService()
        }
        
        // Register ViewModels
        mockContainer.register(GameViewModel.self, lifetime: .transient) { container in
            do {
                let physicsService = try container.resolve(PhysicsServiceProtocol.self)
                let audioService = try container.resolve(AudioServiceProtocol.self)
                let gameCenterService = try container.resolve(GameCenterServiceProtocol.self)
                let modelContext = try container.resolve(ModelContext.self)
                
                return GameViewModel(
                    physicsService: physicsService,
                    audioService: audioService,
                    gameCenterService: gameCenterService,
                    modelContext: modelContext
                )
            } catch {
                fatalError("Failed to resolve dependencies for GameViewModel: \(error)")
            }
        }
        
        mockContainer.register(MainMenuViewModel.self, lifetime: .transient) { container in
            do {
                let gameCenterService = try container.resolve(GameCenterServiceProtocol.self)
                let audioService = try container.resolve(AudioServiceProtocol.self)
                let modelContext = try container.resolve(ModelContext.self)
                
                return MainMenuViewModel(
                    gameCenterService: gameCenterService,
                    audioService: audioService,
                    modelContext: modelContext
                )
            } catch {
                fatalError("Failed to resolve dependencies for MainMenuViewModel: \(error)")
            }
        }
        
        mockContainer.register(HangarViewModel.self, lifetime: .transient) { container in
            do {
                let audioService = try container.resolve(AudioServiceProtocol.self)
                let modelContext = try container.resolve(ModelContext.self)
                
                return HangarViewModel(
                    audioService: audioService,
                    modelContext: modelContext
                )
            } catch {
                fatalError("Failed to resolve dependencies for HangarViewModel: \(error)")
            }
        }
        
        mockContainer.register(SettingsViewModel.self, lifetime: .transient) { container in
            do {
                let audioService = try container.resolve(AudioServiceProtocol.self)
                let physicsService = try container.resolve(PhysicsServiceProtocol.self)
                let gameCenterService = try container.resolve(GameCenterServiceProtocol.self)
                let modelContext = try container.resolve(ModelContext.self)
                
                return SettingsViewModel(
                    audioService: audioService,
                    physicsService: physicsService,
                    gameCenterService: gameCenterService,
                    modelContext: modelContext
                )
            } catch {
                fatalError("Failed to resolve dependencies for SettingsViewModel: \(error)")
            }
        }
    }
    
    // MARK: - ViewModel Creation Tests
    
    func testCreateGameViewModel_Success() throws {
        // When
        let viewModel = try sut.createGameViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel is GameViewModel)
    }
    
    func testCreateMainMenuViewModel_Success() throws {
        // When
        let viewModel = try sut.createMainMenuViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel is MainMenuViewModel)
    }
    
    func testCreateHangarViewModel_Success() throws {
        // When
        let viewModel = try sut.createHangarViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel is HangarViewModel)
    }
    
    func testCreateSettingsViewModel_Success() throws {
        // When
        let viewModel = try sut.createSettingsViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel is SettingsViewModel)
    }
    
    func testCreateViewModel_Generic_Success() throws {
        // When
        let viewModel = try sut.createViewModel(GameViewModel.self)
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel is GameViewModel)
    }
    
    func testTryCreateViewModel_Success() {
        // When
        let viewModel = sut.tryCreateViewModel(GameViewModel.self)
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel is GameViewModel)
    }
    
    func testTryCreateViewModel_Failure_ReturnsNil() {
        // Given - clear the container to simulate missing registration
        mockContainer.clear()
        
        // When
        let viewModel = sut.tryCreateViewModel(GameViewModel.self)
        
        // Then
        XCTAssertNil(viewModel)
    }
    
    // MARK: - Error Handling Tests
    
    func testCreateGameViewModel_MissingDependency_ThrowsError() {
        // Given - clear the container to simulate missing dependencies
        mockContainer.clear()
        
        // When & Then
        XCTAssertThrowsError(try sut.createGameViewModel()) { error in
            XCTAssertTrue(error is ViewModelFactoryError)
            if case .creationFailed(let viewModelType, _) = error as! ViewModelFactoryError {
                XCTAssertEqual(viewModelType, "GameViewModel")
            }
        }
    }
    
    func testCreateViewModel_MissingRegistration_ThrowsError() {
        // Given - clear the container
        mockContainer.clear()
        
        // When & Then
        XCTAssertThrowsError(try sut.createViewModel(GameViewModel.self)) { error in
            XCTAssertTrue(error is ViewModelFactoryError)
        }
    }
    
    // MARK: - Validation Tests
    
    func testCanCreateViewModel_RegisteredType_ReturnsTrue() {
        // When
        let canCreate = sut.canCreateViewModel(GameViewModel.self)
        
        // Then
        XCTAssertTrue(canCreate)
    }
    
    func testCanCreateViewModel_UnregisteredType_ReturnsFalse() {
        // Given - clear the container
        mockContainer.clear()
        
        // When
        let canCreate = sut.canCreateViewModel(GameViewModel.self)
        
        // Then
        XCTAssertFalse(canCreate)
    }
    
    func testValidateViewModelRegistration_AllRegistered_ReturnsEmpty() {
        // When
        let missingViewModels = sut.validateViewModelRegistration()
        
        // Then
        XCTAssertTrue(missingViewModels.isEmpty)
    }
    
    func testValidateViewModelRegistration_SomeMissing_ReturnsMissing() {
        // Given - clear the container to simulate missing registrations
        mockContainer.clear()
        
        // When
        let missingViewModels = sut.validateViewModelRegistration()
        
        // Then
        XCTAssertFalse(missingViewModels.isEmpty)
        XCTAssertTrue(missingViewModels.contains("GameViewModel"))
        XCTAssertTrue(missingViewModels.contains("MainMenuViewModel"))
        XCTAssertTrue(missingViewModels.contains("HangarViewModel"))
        XCTAssertTrue(missingViewModels.contains("SettingsViewModel"))
    }
    
    func testIsProperlyConfigured_AllRegistered_ReturnsTrue() {
        // When
        let isConfigured = sut.isProperlyConfigured()
        
        // Then
        XCTAssertTrue(isConfigured)
    }
    
    func testIsProperlyConfigured_SomeMissing_ReturnsFalse() {
        // Given - clear the container
        mockContainer.clear()
        
        // When
        let isConfigured = sut.isProperlyConfigured()
        
        // Then
        XCTAssertFalse(isConfigured)
    }
    
    // MARK: - Convenience Method Tests
    
    func testCreateAllViewModels_Success() throws {
        // When
        let viewModels = try sut.createAllViewModels()
        
        // Then
        XCTAssertEqual(viewModels.count, 4)
        XCTAssertNotNil(viewModels["GameViewModel"])
        XCTAssertNotNil(viewModels["MainMenuViewModel"])
        XCTAssertNotNil(viewModels["HangarViewModel"])
        XCTAssertNotNil(viewModels["SettingsViewModel"])
        
        XCTAssertTrue(viewModels["GameViewModel"] is GameViewModel)
        XCTAssertTrue(viewModels["MainMenuViewModel"] is MainMenuViewModel)
        XCTAssertTrue(viewModels["HangarViewModel"] is HangarViewModel)
        XCTAssertTrue(viewModels["SettingsViewModel"] is SettingsViewModel)
    }
    
    func testCreateAllViewModels_MissingDependency_ThrowsError() {
        // Given - clear the container
        mockContainer.clear()
        
        // When & Then
        XCTAssertThrowsError(try sut.createAllViewModels())
    }
    
    func testGetFactoryStatus_AllConfigured() {
        // When
        let status = sut.getFactoryStatus()
        
        // Then
        XCTAssertTrue(status.isConfigured)
        XCTAssertTrue(status.missingViewModels.isEmpty)
        XCTAssertEqual(status.availableViewModels.count, 4)
        XCTAssertTrue(status.availableViewModels["GameViewModel"] == true)
        XCTAssertTrue(status.availableViewModels["MainMenuViewModel"] == true)
        XCTAssertTrue(status.availableViewModels["HangarViewModel"] == true)
        XCTAssertTrue(status.availableViewModels["SettingsViewModel"] == true)
    }
    
    func testGetFactoryStatus_SomeMissing() {
        // Given - clear the container
        mockContainer.clear()
        
        // When
        let status = sut.getFactoryStatus()
        
        // Then
        XCTAssertFalse(status.isConfigured)
        XCTAssertFalse(status.missingViewModels.isEmpty)
        XCTAssertEqual(status.availableViewModels.count, 4)
        XCTAssertTrue(status.availableViewModels["GameViewModel"] == false)
        XCTAssertTrue(status.availableViewModels["MainMenuViewModel"] == false)
        XCTAssertTrue(status.availableViewModels["HangarViewModel"] == false)
        XCTAssertTrue(status.availableViewModels["SettingsViewModel"] == false)
    }
    
    // MARK: - Extension Method Tests
    
    func testCreateViewModelWithErrorHandler_Success() {
        // Given
        var errorHandlerCalled = false
        
        // When
        let viewModel = sut.createViewModel(GameViewModel.self) { _ in
            errorHandlerCalled = true
        }
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(errorHandlerCalled)
    }
    
    func testCreateViewModelWithErrorHandler_Failure() {
        // Given
        mockContainer.clear()
        var errorHandlerCalled = false
        var capturedError: ViewModelFactoryError?
        
        // When
        let viewModel = sut.createViewModel(GameViewModel.self) { error in
            errorHandlerCalled = true
            capturedError = error
        }
        
        // Then
        XCTAssertNil(viewModel)
        XCTAssertTrue(errorHandlerCalled)
        XCTAssertNotNil(capturedError)
        
        if case .creationFailed(let viewModelType, _) = capturedError! {
            XCTAssertEqual(viewModelType, "GameViewModel")
        } else {
            XCTFail("Expected creationFailed error")
        }
    }
    
    func testCreateViewModelWithRetry_Success() async {
        // When
        let viewModel = await sut.createViewModelWithRetry(GameViewModel.self, maxRetries: 1, retryDelay: 0.01)
        
        // Then
        XCTAssertNotNil(viewModel)
    }
    
    func testCreateViewModelWithRetry_Failure() async {
        // Given
        mockContainer.clear()
        
        // When
        let viewModel = await sut.createViewModelWithRetry(GameViewModel.self, maxRetries: 1, retryDelay: 0.01)
        
        // Then
        XCTAssertNil(viewModel)
    }
    
    // MARK: - Performance Tests
    
    func testCreateViewModel_Performance() {
        measure {
            for _ in 0..<100 {
                _ = sut.tryCreateViewModel(GameViewModel.self)
            }
        }
    }
}

// Mock services are now imported from Mocks/MockServices.swift