//
//  LoggerProtocol.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import Foundation

/// Log levels for filtering and categorizing log messages
enum LogLevel: Int, CaseIterable, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "💥"
        }
    }
    
    var name: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Categories for organizing log messages by functional area
enum LogCategory: String, CaseIterable {
    case app = "App"
    case game = "Game"
    case network = "Network"
    case gameCenter = "GameCenter"
    case audio = "Audio"
    case physics = "Physics"
    case ui = "UI"
    case accessibility = "Accessibility"
    case performance = "Performance"
    case data = "Data"
    case security = "Security"
}

/// Protocol defining logging functionality
protocol LoggerProtocol {
    /// Log a debug message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The functional category
    ///   - file: Source file (automatically filled)
    ///   - function: Source function (automatically filled)
    ///   - line: Source line number (automatically filled)
    func debug(_ message: String, category: LogCategory, file: String, function: String, line: Int)
    
    /// Log an info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The functional category
    ///   - file: Source file (automatically filled)
    ///   - function: Source function (automatically filled)
    ///   - line: Source line number (automatically filled)
    func info(_ message: String, category: LogCategory, file: String, function: String, line: Int)
    
    /// Log a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The functional category
    ///   - file: Source file (automatically filled)
    ///   - function: Source function (automatically filled)
    ///   - line: Source line number (automatically filled)
    func warning(_ message: String, category: LogCategory, file: String, function: String, line: Int)
    
    /// Log an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object for additional context
    ///   - category: The functional category
    ///   - file: Source file (automatically filled)
    ///   - function: Source function (automatically filled)
    ///   - line: Source line number (automatically filled)
    func error(_ message: String, error: Error?, category: LogCategory, file: String, function: String, line: Int)
    
    /// Log a critical message
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object for additional context
    ///   - category: The functional category
    ///   - file: Source file (automatically filled)
    ///   - function: Source function (automatically filled)
    ///   - line: Source line number (automatically filled)
    func critical(_ message: String, error: Error?, category: LogCategory, file: String, function: String, line: Int)
    
    /// Set the minimum log level for filtering
    /// - Parameter level: Minimum level to log
    func setMinimumLogLevel(_ level: LogLevel)
    
    /// Get the current minimum log level
    /// - Returns: Current minimum log level
    func getMinimumLogLevel() -> LogLevel
}

/// Convenience extensions for easier logging
extension LoggerProtocol {
    func debug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        debug(message, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        info(message, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        warning(message, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, error: Error? = nil, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        self.error(message, error: error, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, error: Error? = nil, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        self.critical(message, error: error, category: category, file: file, function: function, line: line)
    }
}