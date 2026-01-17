//
//  CrashReportingProtocol.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation

/// Protocol defining crash reporting capabilities
protocol CrashReportingProtocol {
    /// Initialize crash reporting with configuration
    func initialize(with configuration: CrashReportingConfiguration)
    
    /// Record a custom error with context
    func recordError(_ error: Error, context: [String: Any]?)
    
    /// Record a non-fatal error with additional information
    func recordNonFatalError(_ error: Error, userInfo: [String: Any]?)
    
    /// Set user identifier for crash reports
    func setUserIdentifier(_ identifier: String)
    
    /// Set custom key-value pairs for crash context
    func setCustomValue(_ value: Any, forKey key: String)
    
    /// Log a message that will be included in crash reports
    func log(_ message: String, level: CrashLogLevel)
    
    /// Force a crash (for testing purposes only)
    func forceCrash()
    
    /// Check if crash reporting is enabled
    var isEnabled: Bool { get }
    
    /// Enable or disable crash reporting
    func setEnabled(_ enabled: Bool)
}

/// Configuration for crash reporting
struct CrashReportingConfiguration {
    let apiKey: String?
    let environment: String
    let enableAutomaticCollection: Bool
    let enableCustomLogs: Bool
    let enablePerformanceMonitoring: Bool
    let maxCustomKeys: Int
    let maxLogMessages: Int
    
    static func forEnvironment(_ environment: BuildEnvironment) -> CrashReportingConfiguration {
        switch environment {
        case .debug:
            return CrashReportingConfiguration(
                apiKey: nil, // No API key needed for debug
                environment: "debug",
                enableAutomaticCollection: false,
                enableCustomLogs: true,
                enablePerformanceMonitoring: false,
                maxCustomKeys: 50,
                maxLogMessages: 100
            )
        case .testFlight:
            return CrashReportingConfiguration(
                apiKey: "test-api-key", // Replace with actual TestFlight key
                environment: "testflight",
                enableAutomaticCollection: true,
                enableCustomLogs: true,
                enablePerformanceMonitoring: true,
                maxCustomKeys: 30,
                maxLogMessages: 50
            )
        case .production:
            return CrashReportingConfiguration(
                apiKey: "prod-api-key", // Replace with actual production key
                environment: "production",
                enableAutomaticCollection: true,
                enableCustomLogs: false,
                enablePerformanceMonitoring: true,
                maxCustomKeys: 20,
                maxLogMessages: 25
            )
        }
    }
}

/// Log levels for crash reporting
enum CrashLogLevel: String, CaseIterable {
    case verbose = "verbose"
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
    
    var priority: Int {
        switch self {
        case .verbose: return 0
        case .debug: return 1
        case .info: return 2
        case .warning: return 3
        case .error: return 4
        case .critical: return 5
        }
    }
}

/// Custom error types for crash reporting
enum CrashReportingError: Error, LocalizedError {
    case notInitialized
    case configurationInvalid
    case apiKeyMissing
    case networkUnavailable
    case rateLimitExceeded
    case customKeyLimitExceeded
    case logMessageLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Crash reporting service is not initialized"
        case .configurationInvalid:
            return "Crash reporting configuration is invalid"
        case .apiKeyMissing:
            return "API key is required for crash reporting"
        case .networkUnavailable:
            return "Network is unavailable for crash reporting"
        case .rateLimitExceeded:
            return "Crash reporting rate limit exceeded"
        case .customKeyLimitExceeded:
            return "Maximum number of custom keys exceeded"
        case .logMessageLimitExceeded:
            return "Maximum number of log messages exceeded"
        }
    }
}

/// Crash report data structure
struct CrashReport {
    let timestamp: Date
    let error: Error
    let context: [String: Any]
    let userInfo: [String: Any]
    let customKeys: [String: Any]
    let logMessages: [CrashLogMessage]
    let deviceInfo: DeviceInfo
    let appInfo: AppInfo
    
    struct CrashLogMessage {
        let timestamp: Date
        let level: CrashLogLevel
        let message: String
    }
    
    struct DeviceInfo {
        let model: String
        let osVersion: String
        let appVersion: String
        let buildNumber: String
        let freeMemory: UInt64
        let totalMemory: UInt64
        let batteryLevel: Float
        let isLowPowerModeEnabled: Bool
    }
    
    struct AppInfo {
        let bundleIdentifier: String
        let version: String
        let buildNumber: String
        let environment: String
        let launchTime: Date
        let sessionDuration: TimeInterval
    }
}