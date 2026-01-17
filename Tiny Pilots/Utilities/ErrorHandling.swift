import Foundation
import UIKit

/// A centralized error handling system for Tiny Pilots
class ErrorHandler {
    // MARK: - Singleton
    
    /// Shared instance of the error handler
    static let shared = ErrorHandler()
    
    private init() {}
    
    // MARK: - Properties
    
    /// Whether to log errors to the console
    var loggingEnabled = true
    
    /// Whether to track errors with analytics
    var analyticsEnabled = true
    
    /// The view controller to present error alerts from
    weak var presentingViewController: UIViewController?
    
    // MARK: - Error Types
    
    /// Game-specific errors
    enum GameError: Error, LocalizedError {
        case gameInitializationFailed
        case invalidGameState(current: String, expected: String)
        case resourceLoadFailed(name: String, type: String)
        case saveFailed(reason: String)
        case loadFailed(reason: String)
        case physicsSimulationError
        case audioPlaybackError(name: String)
        
        var errorDescription: String? {
            switch self {
            case .gameInitializationFailed:
                return "Failed to initialize game"
            case .invalidGameState(let current, let expected):
                return "Invalid game state: current '\(current)', expected '\(expected)'"
            case .resourceLoadFailed(let name, let type):
                return "Failed to load resource: \(name).\(type)"
            case .saveFailed(let reason):
                return "Failed to save game data: \(reason)"
            case .loadFailed(let reason):
                return "Failed to load game data: \(reason)"
            case .physicsSimulationError:
                return "Physics simulation error occurred"
            case .audioPlaybackError(let name):
                return "Failed to play audio: \(name)"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .gameInitializationFailed:
                return "Please restart the app"
            case .invalidGameState:
                return "Please restart the current game"
            case .resourceLoadFailed:
                return "Please check your internet connection and try again"
            case .saveFailed, .loadFailed:
                return "Please check your device storage and try again"
            case .physicsSimulationError:
                return "Please restart the current game"
            case .audioPlaybackError:
                return "Please check your device audio settings"
            }
        }
    }
    
    /// Network-related errors
    enum NetworkError: Error, LocalizedError {
        case connectionFailed
        case serverError(code: Int)
        case requestTimeout
        case invalidResponse
        case noData
        
        var errorDescription: String? {
            switch self {
            case .connectionFailed:
                return "Failed to connect to server"
            case .serverError(let code):
                return "Server error occurred (code: \(code))"
            case .requestTimeout:
                return "Request timed out"
            case .invalidResponse:
                return "Invalid response from server"
            case .noData:
                return "No data received from server"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .connectionFailed, .requestTimeout:
                return "Please check your internet connection and try again"
            case .serverError:
                return "Please try again later"
            case .invalidResponse, .noData:
                return "Please try again or contact support if the issue persists"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Handle an error by logging, tracking, and potentially displaying it
    /// - Parameters:
    ///   - error: The error to handle
    ///   - presentAlert: Whether to present an alert to the user
    ///   - file: The file where the error occurred
    ///   - function: The function where the error occurred
    ///   - line: The line where the error occurred
    ///   - completion: Optional completion handler called after error is handled
    func handle(_ error: Error, 
                presentAlert: Bool = true,
                file: String = #file, 
                function: String = #function, 
                line: Int = #line,
                completion: (() -> Void)? = nil) {
        
        // Log the error
        if loggingEnabled {
            let fileName = (file as NSString).lastPathComponent
            print("🚨 ERROR in \(fileName):\(line) - \(function): \(error.localizedDescription)")
            
            if let localizedError = error as? LocalizedError, let recoverySuggestion = localizedError.recoverySuggestion {
                print("💡 SUGGESTION: \(recoverySuggestion)")
            }
        }
        
        // Track with analytics
        if analyticsEnabled {
            trackErrorWithAnalytics(error, file: file, function: function, line: line)
        }
        
        // Present alert if needed
        if presentAlert {
            showErrorAlert(for: error, completion: completion)
        } else if let completion = completion {
            completion()
        }
    }
    
    /// Show an error alert to the user
    /// - Parameters:
    ///   - error: The error to display
    ///   - viewController: Optional view controller to present from (uses presentingViewController if nil)
    ///   - completion: Optional completion handler called after alert is dismissed
    func showErrorAlert(for error: Error, 
                        in viewController: UIViewController? = nil,
                        completion: (() -> Void)? = nil) {
        
        let presenter = viewController ?? presentingViewController
        guard let presenter = presenter else {
            print("⚠️ Cannot present error alert: no presenting view controller")
            completion?()
            return
        }
        
        let title = "Error"
        let message: String
        let recoverySuggestion: String?
        
        if let localizedError = error as? LocalizedError {
            message = localizedError.errorDescription ?? error.localizedDescription
            recoverySuggestion = localizedError.recoverySuggestion
        } else {
            message = error.localizedDescription
            recoverySuggestion = nil
        }
        
        let fullMessage = recoverySuggestion != nil ? "\(message)\n\n\(recoverySuggestion!)" : message
        
        let alert = UIAlertController(title: title, message: fullMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        
        DispatchQueue.main.async {
            presenter.present(alert, animated: true)
        }
    }
    
    /// Try to execute a throwing function and handle any errors
    /// - Parameters:
    ///   - operation: The operation to execute
    ///   - presentAlert: Whether to present an alert if an error occurs
    ///   - file: The file where the operation is being executed
    ///   - function: The function where the operation is being executed
    ///   - line: The line where the operation is being executed
    ///   - completion: Optional completion handler called after operation completes or fails
    func tryOperation(_ operation: @escaping () throws -> Void,
                      presentAlert: Bool = true,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line,
                      completion: (() -> Void)? = nil) {
        do {
            try operation()
            completion?()
        } catch {
            handle(error, 
                   presentAlert: presentAlert,
                   file: file, 
                   function: function, 
                   line: line,
                   completion: completion)
        }
    }
    
    /// Try to execute a throwing function that returns a value and handle any errors
    /// - Parameters:
    ///   - operation: The operation to execute
    ///   - defaultValue: The default value to return if the operation fails
    ///   - presentAlert: Whether to present an alert if an error occurs
    ///   - file: The file where the operation is being executed
    ///   - function: The function where the operation is being executed
    ///   - line: The line where the operation is being executed
    /// - Returns: The result of the operation or the default value if it fails
    func tryOperation<T>(_ operation: @escaping () throws -> T,
                         defaultValue: T,
                         presentAlert: Bool = true,
                         file: String = #file,
                         function: String = #function,
                         line: Int = #line) -> T {
        do {
            return try operation()
        } catch {
            handle(error, 
                   presentAlert: presentAlert,
                   file: file, 
                   function: function, 
                   line: line)
            return defaultValue
        }
    }
    
    // MARK: - Private Methods
    
    private func trackErrorWithAnalytics(_ error: Error, file: String, function: String, line: Int) {
        // In a real implementation, this would send the error to an analytics service
        // For now, we'll just print a message
        let fileName = (file as NSString).lastPathComponent
        let errorType = String(describing: type(of: error))
        let errorMessage = error.localizedDescription
        
        print("📊 ANALYTICS: Error tracked - Type: \(errorType), Message: \(errorMessage), Location: \(fileName):\(line) in \(function)")
    }
}

// MARK: - Result Type Extensions

extension Result {
    /// Handle the result by returning the success value or handling the error
    /// - Parameters:
    ///   - defaultValue: The default value to return if the result is a failure
    ///   - presentAlert: Whether to present an alert if the result is a failure
    ///   - file: The file where the result is being handled
    ///   - function: The function where the result is being handled
    ///   - line: The line where the result is being handled
    /// - Returns: The success value or the default value if the result is a failure
    func handleResult(defaultValue: Success,
                      presentAlert: Bool = true,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            ErrorHandler.shared.handle(error, 
                                      presentAlert: presentAlert,
                                      file: file, 
                                      function: function, 
                                      line: line)
            return defaultValue
        }
    }
    
    /// Handle the result by executing a completion handler with the success value or handling the error
    /// - Parameters:
    ///   - presentAlert: Whether to present an alert if the result is a failure
    ///   - file: The file where the result is being handled
    ///   - function: The function where the result is being handled
    ///   - line: The line where the result is being handled
    ///   - completion: The completion handler to execute with the success value
    func handleResult(presentAlert: Bool = true,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line,
                      completion: @escaping (Success) -> Void) {
        switch self {
        case .success(let value):
            completion(value)
        case .failure(let error):
            ErrorHandler.shared.handle(error, 
                                      presentAlert: presentAlert,
                                      file: file, 
                                      function: function, 
                                      line: line)
        }
    }
}

// MARK: - Convenience Functions

/// Global function to handle errors
/// - Parameters:
///   - error: The error to handle
///   - presentAlert: Whether to present an alert to the user
///   - file: The file where the error occurred
///   - function: The function where the error occurred
///   - line: The line where the error occurred
///   - completion: Optional completion handler called after error is handled
func handleError(_ error: Error,
                presentAlert: Bool = true,
                file: String = #file,
                function: String = #function,
                line: Int = #line,
                completion: (() -> Void)? = nil) {
    ErrorHandler.shared.handle(error, 
                              presentAlert: presentAlert,
                              file: file, 
                              function: function, 
                              line: line,
                              completion: completion)
}

/// Global function to try an operation and handle any errors
/// - Parameters:
///   - operation: The operation to execute
///   - presentAlert: Whether to present an alert if an error occurs
///   - file: The file where the operation is being executed
///   - function: The function where the operation is being executed
///   - line: The line where the operation is being executed
///   - completion: Optional completion handler called after operation completes or fails
func tryOperation(_ operation: @escaping () throws -> Void,
                 presentAlert: Bool = true,
                 file: String = #file,
                 function: String = #function,
                 line: Int = #line,
                 completion: (() -> Void)? = nil) {
    ErrorHandler.shared.tryOperation(operation, 
                                    presentAlert: presentAlert,
                                    file: file, 
                                    function: function, 
                                    line: line,
                                    completion: completion)
}

/// Global function to try an operation that returns a value and handle any errors
/// - Parameters:
///   - operation: The operation to execute
///   - defaultValue: The default value to return if the operation fails
///   - presentAlert: Whether to present an alert if an error occurs
///   - file: The file where the operation is being executed
///   - function: The function where the operation is being executed
///   - line: The line where the operation is being executed
/// - Returns: The result of the operation or the default value if it fails
func tryOperation<T>(_ operation: @escaping () throws -> T,
                    defaultValue: T,
                    presentAlert: Bool = true,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) -> T {
    return ErrorHandler.shared.tryOperation(operation, 
                                           defaultValue: defaultValue,
                                           presentAlert: presentAlert,
                                           file: file, 
                                           function: function, 
                                           line: line)
} 