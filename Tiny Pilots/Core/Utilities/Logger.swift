//
//  Logger.swift
//  Tiny Pilots
//
//  Created by Kiro on Production Readiness Implementation
//

import Foundation
import os.log

/// Concrete implementation of LoggerProtocol
class Logger: LoggerProtocol {
    static let shared = Logger()
    
    // MARK: - Private Properties
    private var minimumLogLevel: LogLevel
    private let dateFormatter: DateFormatter
    private let logQueue = DispatchQueue(label: "com.tinypilots.logging", qos: .utility)
    private let osLog = OSLog(subsystem: "com.tinypilots.app", category: "general")
    
    // MARK: - Initialization
    private init() {
        #if DEBUG
        self.minimumLogLevel = .debug
        #else
        self.minimumLogLevel = .info
        #endif
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        self.dateFormatter.timeZone = TimeZone.current
    }
    
    // MARK: - Public Methods
    
    func debug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, error: nil, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, error: nil, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, error: nil, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, error: Error? = nil, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, error: error, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, error: Error? = nil, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .critical, message: message, error: error, category: category, file: file, function: function, line: line)
    }
    
    func setMinimumLogLevel(_ level: LogLevel) {
        logQueue.async { [weak self] in
            self?.minimumLogLevel = level
        }
    }
    
    func getMinimumLogLevel() -> LogLevel {
        return logQueue.sync {
            return minimumLogLevel
        }
    }
    
    // MARK: - Private Methods
    
    private func log(level: LogLevel, message: String, error: Error?, category: LogCategory, file: String, function: String, line: Int) {
        guard level >= minimumLogLevel else { return }
        
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            let timestamp = self.dateFormatter.string(from: Date())
            let filename = URL(fileURLWithPath: file).lastPathComponent
            
            var logMessage = "\(level.emoji) [\(timestamp)] [\(level.name)] [\(category.rawValue)] \(filename):\(line) \(function) - \(message)"
            
            if let error = error {
                logMessage += " | Error: \(error.localizedDescription)"
                
                // Add additional error context if available
                if let nsError = error as NSError? {
                    logMessage += " (Domain: \(nsError.domain), Code: \(nsError.code))"
                    
                    if !nsError.userInfo.isEmpty {
                        let userInfoString = nsError.userInfo.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                        logMessage += " UserInfo: [\(userInfoString)]"
                    }
                }
            }
            
            // Output to console in debug builds
            #if DEBUG
            print(logMessage)
            #endif
            
            // Send to system log
            self.logToSystem(level: level, message: logMessage, category: category)
            
            // Send to analytics/crash reporting for errors and critical messages
            if level >= .error {
                self.sendToAnalytics(level: level, message: logMessage, category: category, error: error)
            }
        }
    }
    
    private func logToSystem(level: LogLevel, message: String, category: LogCategory) {
        let categoryLog = OSLog(subsystem: "com.tinypilots.app", category: category.rawValue.lowercased())
        
        switch level {
        case .debug:
            os_log("%{public}@", log: categoryLog, type: .debug, message)
        case .info:
            os_log("%{public}@", log: categoryLog, type: .info, message)
        case .warning:
            os_log("%{public}@", log: categoryLog, type: .default, message)
        case .error:
            os_log("%{public}@", log: categoryLog, type: .error, message)
        case .critical:
            os_log("%{public}@", log: categoryLog, type: .fault, message)
        }
    }
    
    private func sendToAnalytics(level: LogLevel, message: String, category: LogCategory, error: Error?) {
        // This will be integrated with AnalyticsManager when it's implemented
        // For now, we'll create a placeholder that can be easily replaced
        
        let errorData: [String: Any] = [
            "level": level.name,
            "category": category.rawValue,
            "message": message,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // TODO: Integrate with AnalyticsManager.shared.trackError(errorData)
        // This is a placeholder for future analytics integration
        NotificationCenter.default.post(
            name: .loggerErrorOccurred,
            object: nil,
            userInfo: errorData
        )
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let loggerErrorOccurred = Notification.Name("LoggerErrorOccurred")
}

// MARK: - Global Logging Functions
// These provide convenient global access to logging functionality

/// Log a debug message
/// - Parameters:
///   - message: The message to log
///   - category: The functional category
///   - file: Source file (automatically filled)
///   - function: Source function (automatically filled)
///   - line: Source line number (automatically filled)
func logDebug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, category: category, file: file, function: function, line: line)
}

/// Log an info message
/// - Parameters:
///   - message: The message to log
///   - category: The functional category
///   - file: Source file (automatically filled)
///   - function: Source function (automatically filled)
///   - line: Source line number (automatically filled)
func logInfo(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, category: category, file: file, function: function, line: line)
}

/// Log a warning message
/// - Parameters:
///   - message: The message to log
///   - category: The functional category
///   - file: Source file (automatically filled)
///   - function: Source function (automatically filled)
///   - line: Source line number (automatically filled)
func logWarning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, category: category, file: file, function: function, line: line)
}

/// Log an error message
/// - Parameters:
///   - message: The message to log
///   - error: Optional error object for additional context
///   - category: The functional category
///   - file: Source file (automatically filled)
///   - function: Source function (automatically filled)
///   - line: Source line number (automatically filled)
func logError(_ message: String, error: Error? = nil, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, error: error, category: category, file: file, function: function, line: line)
}

/// Log a critical message
/// - Parameters:
///   - message: The message to log
///   - error: Optional error object for additional context
///   - category: The functional category
///   - file: Source file (automatically filled)
///   - function: Source function (automatically filled)
///   - line: Source line number (automatically filled)
func logCritical(_ message: String, error: Error? = nil, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.critical(message, error: error, category: category, file: file, function: function, line: line)
}