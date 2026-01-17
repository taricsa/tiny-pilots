//
//  ViewModelFactory.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation
import SwiftData

/// Factory class for creating ViewModels with proper dependency injection
class ViewModelFactory {
    
    // MARK: - Properties
    
    private let container: DIContainer
    
    // MARK: - Shared Instance
    
    static let shared = ViewModelFactory()
    
    // MARK: - Initialization
    
    init(container: DIContainer = DIContainer.shared) {
        self.container = container
    }
    
    // MARK: - ViewModel Creation Methods
    
    /// Create a GameViewModel instance
    /// - Returns: Configured GameViewModel instance
    /// - Throws: ViewModelFactoryError if creation fails
    func createGameViewModel() throws -> GameViewModel {
        do {
            return try container.resolve(GameViewModel.self)
        } catch {
            throw ViewModelFactoryError.creationFailed("GameViewModel", underlying: error)
        }
    }
    
    /// Create a MainMenuViewModel instance
    /// - Returns: Configured MainMenuViewModel instance
    /// - Throws: ViewModelFactoryError if creation fails
    func createMainMenuViewModel() throws -> MainMenuViewModel {
        do {
            return try container.resolve(MainMenuViewModel.self)
        } catch {
            throw ViewModelFactoryError.creationFailed("MainMenuViewModel", underlying: error)
        }
    }
    
    /// Create a HangarViewModel instance
    /// - Returns: Configured HangarViewModel instance
    /// - Throws: ViewModelFactoryError if creation fails
    func createHangarViewModel() throws -> HangarViewModel {
        do {
            return try container.resolve(HangarViewModel.self)
        } catch {
            throw ViewModelFactoryError.creationFailed("HangarViewModel", underlying: error)
        }
    }
    
    /// Create a SettingsViewModel instance
    /// - Returns: Configured SettingsViewModel instance
    /// - Throws: ViewModelFactoryError if creation fails
    func createSettingsViewModel() throws -> SettingsViewModel {
        do {
            return try container.resolve(SettingsViewModel.self)
        } catch {
            throw ViewModelFactoryError.creationFailed("SettingsViewModel", underlying: error)
        }
    }
    
    // MARK: - Generic ViewModel Creation
    
    /// Create a ViewModel of the specified type
    /// - Parameter type: The ViewModel type to create
    /// - Returns: Configured ViewModel instance
    /// - Throws: ViewModelFactoryError if creation fails
    func createViewModel<T>(_ type: T.Type) throws -> T {
        do {
            return try container.resolve(type)
        } catch {
            throw ViewModelFactoryError.creationFailed(String(describing: type), underlying: error)
        }
    }
    
    /// Try to create a ViewModel of the specified type without throwing
    /// - Parameter type: The ViewModel type to create
    /// - Returns: Configured ViewModel instance or nil if creation fails
    func tryCreateViewModel<T>(_ type: T.Type) -> T? {
        return container.tryResolve(type)
    }
    
    // MARK: - Validation Methods
    
    /// Check if a ViewModel type can be created
    /// - Parameter type: The ViewModel type to check
    /// - Returns: Whether the ViewModel can be created
    func canCreateViewModel<T>(_ type: T.Type) -> Bool {
        return container.isRegistered(type)
    }
    
    /// Validate that all required ViewModels can be created
    /// - Returns: Array of ViewModel types that cannot be created
    func validateViewModelRegistration() -> [String] {
        var missingViewModels: [String] = []
        
        if !canCreateViewModel(GameViewModel.self) {
            missingViewModels.append("GameViewModel")
        }
        if !canCreateViewModel(MainMenuViewModel.self) {
            missingViewModels.append("MainMenuViewModel")
        }
        if !canCreateViewModel(HangarViewModel.self) {
            missingViewModels.append("HangarViewModel")
        }
        if !canCreateViewModel(SettingsViewModel.self) {
            missingViewModels.append("SettingsViewModel")
        }
        
        return missingViewModels
    }
    
    /// Check if the factory is properly configured
    /// - Returns: Whether all ViewModels can be created
    func isProperlyConfigured() -> Bool {
        return validateViewModelRegistration().isEmpty
    }
    
    // MARK: - Convenience Methods
    
    /// Create all ViewModels for testing purposes
    /// - Returns: Dictionary of ViewModel type names to instances
    /// - Throws: ViewModelFactoryError if any creation fails
    func createAllViewModels() throws -> [String: Any] {
        var viewModels: [String: Any] = [:]
        
        viewModels["GameViewModel"] = try createGameViewModel()
        viewModels["MainMenuViewModel"] = try createMainMenuViewModel()
        viewModels["HangarViewModel"] = try createHangarViewModel()
        viewModels["SettingsViewModel"] = try createSettingsViewModel()
        
        return viewModels
    }
    
    /// Get factory status information
    /// - Returns: Factory status information
    func getFactoryStatus() -> ViewModelFactoryStatus {
        let missingViewModels = validateViewModelRegistration()
        let isConfigured = missingViewModels.isEmpty
        
        return ViewModelFactoryStatus(
            isConfigured: isConfigured,
            missingViewModels: missingViewModels,
            availableViewModels: [
                "GameViewModel": canCreateViewModel(GameViewModel.self),
                "MainMenuViewModel": canCreateViewModel(MainMenuViewModel.self),
                "HangarViewModel": canCreateViewModel(HangarViewModel.self),
                "SettingsViewModel": canCreateViewModel(SettingsViewModel.self)
            ]
        )
    }
}

// MARK: - Supporting Types

/// ViewModel factory errors
enum ViewModelFactoryError: Error, LocalizedError {
    case creationFailed(String, underlying: Error)
    case dependencyMissing(String)
    case configurationInvalid(String)
    
    var errorDescription: String? {
        switch self {
        case .creationFailed(let viewModelType, let underlying):
            return "Failed to create \(viewModelType): \(underlying.localizedDescription)"
        case .dependencyMissing(let dependency):
            return "Missing dependency for ViewModel creation: \(dependency)"
        case .configurationInvalid(let reason):
            return "Invalid ViewModel factory configuration: \(reason)"
        }
    }
}

/// ViewModel factory status information
struct ViewModelFactoryStatus {
    let isConfigured: Bool
    let missingViewModels: [String]
    let availableViewModels: [String: Bool]
    
    var description: String {
        if isConfigured {
            return "ViewModelFactory is properly configured with all ViewModels available"
        } else {
            return "ViewModelFactory is missing: \(missingViewModels.joined(separator: ", "))"
        }
    }
}

// MARK: - Extensions

extension ViewModelFactory {
    
    /// Create a ViewModel with custom error handling
    /// - Parameters:
    ///   - type: The ViewModel type to create
    ///   - errorHandler: Custom error handler
    /// - Returns: ViewModel instance or nil if creation fails
    func createViewModel<T>(
        _ type: T.Type,
        errorHandler: ((ViewModelFactoryError) -> Void)? = nil
    ) -> T? {
        if let resolved: T = container.tryResolve(type) {
            return resolved
        } else {
            errorHandler?(.dependencyMissing(String(describing: type)))
            return nil
        }
    }
    
    /// Create a ViewModel with retry logic
    /// - Parameters:
    ///   - type: The ViewModel type to create
    ///   - maxRetries: Maximum number of retry attempts
    ///   - retryDelay: Delay between retry attempts in seconds
    /// - Returns: ViewModel instance or nil if all attempts fail
    func createViewModelWithRetry<T>(
        _ type: T.Type,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 0.1
    ) async -> T? {
        for attempt in 0...maxRetries {
            if let viewModel = tryCreateViewModel(type) {
                return viewModel
            }
            
            if attempt < maxRetries {
                try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            }
        }
        
        print("Failed to create \(String(describing: type)) after \(maxRetries + 1) attempts")
        return nil
    }
}