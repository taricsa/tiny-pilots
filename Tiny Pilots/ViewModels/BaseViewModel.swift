//
//  BaseViewModel.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation
import Observation

/// Base ViewModel class that provides common functionality for all ViewModels
@Observable
class BaseViewModel: ViewModelProtocol {
    
    // MARK: - Properties
    
    /// Indicates if the ViewModel is currently loading
    var isLoading: Bool = false
    
    /// Current error message, if any
    var errorMessage: String?
    
    /// Indicates if the ViewModel has been initialized
    private(set) var isInitialized: Bool = false
    
    // MARK: - Initialization
    
    init() {
        // Base initialization
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - ViewModelProtocol Implementation
    
    /// Handle a user action - override in subclasses
    /// - Parameter action: The action to handle
    func handle(_ action: ViewAction) {
        // Base implementation - log unhandled actions in debug mode
        #if DEBUG
        print("⚠️ Unhandled action: \(action.actionType) in \(String(describing: type(of: self)))")
        #endif
    }
    
    /// Initialize the ViewModel
    func initialize() {
        guard !isInitialized else { return }
        
        isInitialized = true
        performInitialization()
    }
    
    /// Clean up resources
    func cleanup() {
        performCleanup()
    }
    
    // MARK: - Protected Methods (Override in subclasses)
    
    /// Override this method in subclasses to perform specific initialization
    func performInitialization() {
        // Override in subclasses
    }
    
    /// Override this method in subclasses to perform specific cleanup
    func performCleanup() {
        // Override in subclasses
    }
    
    // MARK: - Utility Methods
    
    /// Set loading state
    /// - Parameter loading: Whether the ViewModel is loading
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    /// Set error message
    /// - Parameter error: The error to display, or nil to clear
    func setError(_ error: Error?) {
        if let error = error {
            errorMessage = error.localizedDescription
        } else {
            errorMessage = nil
        }
    }
    
    /// Set error message with custom text
    /// - Parameter message: The error message to display, or nil to clear
    func setErrorMessage(_ message: String?) {
        errorMessage = message
    }
    
    /// Clear any current error
    func clearError() {
        errorMessage = nil
    }
    
    /// Execute an async operation with loading state management
    /// - Parameter operation: The async operation to execute
    func executeWithLoading<T>(_ operation: @escaping () async throws -> T) async -> T? {
        setLoading(true)
        clearError()
        
        do {
            let result = try await operation()
            setLoading(false)
            return result
        } catch {
            setLoading(false)
            setError(error)
            return nil
        }
    }
}