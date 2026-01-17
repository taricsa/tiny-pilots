//
//  ViewModelProtocol.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation

/// Protocol defining common ViewModel behavior
protocol ViewModelProtocol: AnyObject {
    
    /// Handle a user action
    /// - Parameter action: The action to handle
    func handle(_ action: ViewAction)
    
    /// Initialize the ViewModel with any required setup
    func initialize()
    
    /// Clean up resources when the ViewModel is deallocated
    func cleanup()
}

// MARK: - Default Implementation

extension ViewModelProtocol {
    
    /// Default implementation for initialize - can be overridden
    func initialize() {
        // Default empty implementation
    }
    
    /// Default implementation for cleanup - can be overridden
    func cleanup() {
        // Default empty implementation
    }
}