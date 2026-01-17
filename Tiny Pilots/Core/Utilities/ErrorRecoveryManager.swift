//
//  ErrorRecoveryManager.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import Foundation

/// Protocol defining error recovery functionality
protocol ErrorRecoveryProtocol {
    /// Handle an error and determine the appropriate recovery action
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - context: Additional context about the error
    /// - Returns: The recommended recovery action
    func handleError(_ error: Error, context: ErrorContext) -> ErrorRecoveryAction
    
    /// Check if recovery is possible for a given error
    /// - Parameter error: The error to check
    /// - Returns: True if recovery is possible
    func canRecover(from error: Error) -> Bool
    
    /// Attempt to recover from an error
    /// - Parameters:
    ///   - error: The error to recover from
    ///   - context: Additional context about the error
    /// - Returns: True if recovery was successful
    func attemptRecovery(from error: Error, context: ErrorContext) async -> Bool
    
    /// Reset retry counters for a specific operation
    /// - Parameter operation: The operation to reset
    func resetRetryCounter(for operation: String)
    
    /// Get the current retry count for an operation
    /// - Parameter operation: The operation to check
    /// - Returns: Current retry count
    func getRetryCount(for operation: String) -> Int
}

/// Actions that can be taken in response to an error
enum ErrorRecoveryAction {
    case retry
    case fallback
    case userIntervention(message: String)
    case gracefulDegradation
    case fatal(message: String)
}

/// Context information about an error occurrence
struct ErrorContext {
    let operation: String
    let userFacing: Bool
    let retryCount: Int
    let additionalInfo: [String: Any]
    
    init(operation: String, userFacing: Bool = false, retryCount: Int = 0, additionalInfo: [String: Any] = [:]) {
        self.operation = operation
        self.userFacing = userFacing
        self.retryCount = retryCount
        self.additionalInfo = additionalInfo
    }
}

/// Custom error types for the application
enum TinyPilotsError: Error, LocalizedError {
    case networkUnavailable
    case gameCenterUnavailable
    case dataCorruption
    case insufficientStorage
    case configurationError(String)
    case serviceUnavailable(String)
    case validationError(String)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection is not available"
        case .gameCenterUnavailable:
            return "Game Center is not available"
        case .dataCorruption:
            return "Data corruption detected"
        case .insufficientStorage:
            return "Insufficient storage space"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .serviceUnavailable(let service):
            return "\(service) service is unavailable"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection and try again"
        case .gameCenterUnavailable:
            return "Please sign in to Game Center and try again"
        case .dataCorruption:
            return "The app will attempt to restore from backup"
        case .insufficientStorage:
            return "Please free up storage space and try again"
        case .configurationError:
            return "The app will use default settings"
        case .serviceUnavailable:
            return "Please try again later"
        case .validationError:
            return "Please check your input and try again"
        case .unknownError:
            return "Please restart the app and try again"
        }
    }
}

/// Concrete implementation of ErrorRecoveryProtocol
class ErrorRecoveryManager: ErrorRecoveryProtocol {
    static let shared = ErrorRecoveryManager()
    
    // MARK: - Private Properties
    private let maxRetryAttempts = 3
    private var retryCounters: [String: Int] = [:]
    private let retryQueue = DispatchQueue(label: "com.tinypilots.errorrecovery", qos: .utility)
    private let logger = Logger.shared
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    func handleError(_ error: Error, context: ErrorContext) -> ErrorRecoveryAction {
        logger.error("Error occurred in \(context.operation)", error: error, category: .app)
        
        // Check if we can recover
        if canRecover(from: error) && context.retryCount < maxRetryAttempts {
            logger.info("Attempting recovery for \(context.operation), retry \(context.retryCount + 1)", category: .app)
            return .retry
        }
        
        // Determine appropriate action based on error type
        let action = determineRecoveryAction(for: error, context: context)
        
        logger.info("Recovery action for \(context.operation): \(action)", category: .app)
        return action
    }
    
    func canRecover(from error: Error) -> Bool {
        switch error {
        case TinyPilotsError.networkUnavailable,
             TinyPilotsError.gameCenterUnavailable,
             TinyPilotsError.serviceUnavailable:
            return true
        case TinyPilotsError.dataCorruption,
             TinyPilotsError.insufficientStorage,
             TinyPilotsError.configurationError,
             TinyPilotsError.validationError:
            return false
        case TinyPilotsError.unknownError:
            return true // Try to recover from unknown errors
        default:
            // For system errors, check if they're recoverable
            if let nsError = error as NSError? {
                switch nsError.domain {
                case NSURLErrorDomain:
                    return isRecoverableNetworkError(nsError.code)
                case NSCocoaErrorDomain:
                    return isRecoverableCocoaError(nsError.code)
                default:
                    return true // Default to recoverable for unknown domains
                }
            }
            return true
        }
    }
    
    func attemptRecovery(from error: Error, context: ErrorContext) async -> Bool {
        let operationKey = context.operation
        let currentRetryCount = getRetryCount(for: operationKey)
        
        guard currentRetryCount < maxRetryAttempts else {
            logger.warning("Max retry attempts reached for \(operationKey)", category: .app)
            return false
        }
        
        // Increment retry counter
        retryQueue.sync {
            retryCounters[operationKey] = currentRetryCount + 1
        }
        
        // Wait before retry with exponential backoff
        let delay = calculateBackoffDelay(retryCount: currentRetryCount)
        logger.info("Waiting \(delay)s before retry for \(operationKey)", category: .app)
        
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        logger.info("Attempting recovery for \(operationKey), attempt \(currentRetryCount + 1)", category: .app)
        
        // Perform error-specific recovery logic
        let recoverySuccess = await performRecovery(for: error, context: context)
        
        if recoverySuccess {
            // Reset counter on successful recovery
            resetRetryCounter(for: operationKey)
            logger.info("Recovery successful for \(operationKey)", category: .app)
        } else {
            logger.warning("Recovery failed for \(operationKey)", category: .app)
        }
        
        return recoverySuccess
    }
    
    func resetRetryCounter(for operation: String) {
        retryQueue.sync {
            retryCounters[operation] = 0
        }
    }
    
    func getRetryCount(for operation: String) -> Int {
        return retryQueue.sync {
            return retryCounters[operation, default: 0]
        }
    }
    
    // MARK: - Private Methods
    
    private func determineRecoveryAction(for error: Error, context: ErrorContext) -> ErrorRecoveryAction {
        switch error {
        case TinyPilotsError.networkUnavailable:
            return .fallback
        case TinyPilotsError.gameCenterUnavailable:
            return .gracefulDegradation
        case TinyPilotsError.dataCorruption:
            return .userIntervention(message: "Data corruption detected. The app will attempt to restore from backup.")
        case TinyPilotsError.insufficientStorage:
            return .userIntervention(message: "Insufficient storage space. Please free up space and try again.")
        case TinyPilotsError.configurationError:
            return .gracefulDegradation
        case TinyPilotsError.serviceUnavailable(let service):
            return .userIntervention(message: "\(service) is temporarily unavailable. Please try again later.")
        case TinyPilotsError.validationError(let message):
            return .userIntervention(message: message)
        case TinyPilotsError.unknownError:
            if context.userFacing {
                return .userIntervention(message: "An unexpected error occurred. Please try again.")
            } else {
                return .gracefulDegradation
            }
        default:
            // Handle system errors
            if let nsError = error as NSError? {
                switch nsError.domain {
                case NSURLErrorDomain:
                    return .fallback
                case NSCocoaErrorDomain:
                    return .gracefulDegradation
                default:
                    if context.userFacing {
                        return .userIntervention(message: "Something went wrong. Please try again.")
                    } else {
                        return .gracefulDegradation
                    }
                }
            }
            
            return context.userFacing ? .userIntervention(message: "Please try again.") : .gracefulDegradation
        }
    }
    
    private func calculateBackoffDelay(retryCount: Int) -> Double {
        // Exponential backoff: 1s, 2s, 4s, 8s, etc.
        let baseDelay = 1.0
        let maxDelay = 30.0
        let delay = baseDelay * pow(2.0, Double(retryCount))
        return min(delay, maxDelay)
    }
    
    private func performRecovery(for error: Error, context: ErrorContext) async -> Bool {
        switch error {
        case TinyPilotsError.networkUnavailable:
            return await checkNetworkConnectivity()
        case TinyPilotsError.gameCenterUnavailable:
            return await checkGameCenterAvailability()
        case TinyPilotsError.serviceUnavailable:
            return await checkServiceAvailability(context: context)
        default:
            // For unknown errors, assume recovery might be possible
            return true
        }
    }
    
    private func checkNetworkConnectivity() async -> Bool {
        // Placeholder for network connectivity check
        // In a real implementation, this would check actual network status
        return true
    }
    
    private func checkGameCenterAvailability() async -> Bool {
        // Placeholder for Game Center availability check
        // In a real implementation, this would check Game Center status
        return true
    }
    
    private func checkServiceAvailability(context: ErrorContext) async -> Bool {
        // Placeholder for service availability check
        // In a real implementation, this would ping the specific service
        return true
    }
    
    private func isRecoverableNetworkError(_ code: Int) -> Bool {
        switch code {
        case NSURLErrorTimedOut,
             NSURLErrorCannotConnectToHost,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorDNSLookupFailed,
             NSURLErrorNotConnectedToInternet:
            return true
        default:
            return false
        }
    }
    
    private func isRecoverableCocoaError(_ code: Int) -> Bool {
        switch code {
        case NSFileReadNoSuchFileError,
             NSFileWriteFileExistsError:
            return false
        default:
            return true
        }
    }
}

// MARK: - Convenience Extensions

extension ErrorRecoveryAction: CustomStringConvertible {
    var description: String {
        switch self {
        case .retry:
            return "retry"
        case .fallback:
            return "fallback"
        case .userIntervention(let message):
            return "userIntervention(\(message))"
        case .gracefulDegradation:
            return "gracefulDegradation"
        case .fatal(let message):
            return "fatal(\(message))"
        }
    }
}

// MARK: - Global Error Handling Functions

/// Handle an error with automatic recovery attempt
/// - Parameters:
///   - error: The error to handle
///   - operation: The operation that failed
///   - userFacing: Whether this error affects the user directly
///   - additionalInfo: Additional context information
/// - Returns: The recovery action taken
@discardableResult
func handleError(_ error: Error, operation: String, userFacing: Bool = false, additionalInfo: [String: Any] = [:]) -> ErrorRecoveryAction {
    let context = ErrorContext(
        operation: operation,
        userFacing: userFacing,
        retryCount: ErrorRecoveryManager.shared.getRetryCount(for: operation),
        additionalInfo: additionalInfo
    )
    
    return ErrorRecoveryManager.shared.handleError(error, context: context)
}

/// Attempt to recover from an error with retry logic
/// - Parameters:
///   - error: The error to recover from
///   - operation: The operation that failed
///   - userFacing: Whether this error affects the user directly
///   - additionalInfo: Additional context information
/// - Returns: True if recovery was successful
func attemptErrorRecovery(_ error: Error, operation: String, userFacing: Bool = false, additionalInfo: [String: Any] = [:]) async -> Bool {
    let context = ErrorContext(
        operation: operation,
        userFacing: userFacing,
        retryCount: ErrorRecoveryManager.shared.getRetryCount(for: operation),
        additionalInfo: additionalInfo
    )
    
    return await ErrorRecoveryManager.shared.attemptRecovery(from: error, context: context)
}