//
//  CrashReportingManager.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation
import UIKit

/// Main crash reporting manager implementing crash reporting functionality
class CrashReportingManager: CrashReportingProtocol {
    static let shared = CrashReportingManager()
    
    // MARK: - Properties
    
    private var configuration: CrashReportingConfiguration?
    private var customKeys: [String: Any] = [:]
    private var logMessages: [CrashReport.CrashLogMessage] = []
    private var userIdentifier: String?
    private var isInitialized = false
    private var _isEnabled = false
    
    private let logQueue = DispatchQueue(label: "com.tinypilots.crashreporting", qos: .utility)
    private let maxRetryAttempts = 3
    private var pendingReports: [CrashReport] = []
    
    // MARK: - Initialization
    
    private init() {
        setupExceptionHandling()
        setupSignalHandling()
        setupMemoryWarningObserver()
    }
    
    // MARK: - Public Interface
    
    func initialize() {
        let config = CrashReportingConfiguration.forEnvironment(AppConfiguration.current.environment)
        initialize(with: config)
    }
    
    var isEnabled: Bool {
        return _isEnabled && isInitialized
    }
    
    func initialize(with configuration: CrashReportingConfiguration) {
        self.configuration = configuration
        self.isInitialized = true
        self._isEnabled = configuration.enableAutomaticCollection
        
        Logger.shared.info("Crash reporting initialized for environment: \(configuration.environment)", category: .app)
        
        // Set initial context
        setCustomValue(configuration.environment, forKey: "environment")
        setCustomValue(AppConfiguration.current.fullVersionString, forKey: "app_version")
        setCustomValue(UIDevice.current.model, forKey: "device_model")
        setCustomValue(UIDevice.current.systemVersion, forKey: "os_version")
        
        // Process any pending reports
        processPendingReports()
    }
    
    func recordError(_ error: Error, context: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        logQueue.async { [weak self] in
            self?.handleError(error, context: context, isFatal: false)
        }
    }
    
    func recordNonFatalError(_ error: Error, userInfo: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        logQueue.async { [weak self] in
            self?.handleError(error, context: userInfo, isFatal: false)
        }
    }
    
    func setUserIdentifier(_ identifier: String) {
        self.userIdentifier = identifier
        setCustomValue(identifier, forKey: "user_id")
        Logger.shared.debug("Crash reporting user identifier set", category: .app)
    }
    
    func setCustomValue(_ value: Any, forKey key: String) {
        guard isEnabled else { return }
        guard let config = configuration else { return }
        
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.customKeys.count >= config.maxCustomKeys && self.customKeys[key] == nil {
                Logger.shared.warning("Custom key limit exceeded for crash reporting", category: .app)
                return
            }
            
            self.customKeys[key] = value
        }
    }
    
    func log(_ message: String, level: CrashLogLevel = .info) {
        guard isEnabled else { return }
        guard let config = configuration else { return }
        
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            let logMessage = CrashReport.CrashLogMessage(
                timestamp: Date(),
                level: level,
                message: message
            )
            
            self.logMessages.append(logMessage)
            
            // Keep only the most recent messages
            if self.logMessages.count > config.maxLogMessages {
                self.logMessages.removeFirst(self.logMessages.count - config.maxLogMessages)
            }
        }
    }
    
    func forceCrash() {
        #if DEBUG
        Logger.shared.critical("Force crash triggered for testing", category: .app)
        fatalError("Forced crash for testing purposes")
        #else
        Logger.shared.warning("Force crash ignored in non-debug build", category: .app)
        #endif
    }
    
    func setEnabled(_ enabled: Bool) {
        self._isEnabled = enabled
        Logger.shared.info("Crash reporting enabled: \(enabled)", category: .app)
    }
    
    // MARK: - Private Methods
    
    private func setupExceptionHandling() {
        NSSetUncaughtExceptionHandler { exception in
            CrashReportingManager.shared.handleUncaughtException(exception)
        }
    }
    
    private func setupSignalHandling() {
        signal(SIGABRT) { signal in
            CrashReportingManager.shared.handleSignal(signal)
        }
        signal(SIGILL) { signal in
            CrashReportingManager.shared.handleSignal(signal)
        }
        signal(SIGSEGV) { signal in
            CrashReportingManager.shared.handleSignal(signal)
        }
        signal(SIGFPE) { signal in
            CrashReportingManager.shared.handleSignal(signal)
        }
        signal(SIGBUS) { signal in
            CrashReportingManager.shared.handleSignal(signal)
        }
        signal(SIGPIPE) { signal in
            CrashReportingManager.shared.handleSignal(signal)
        }
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func handleUncaughtException(_ exception: NSException) {
        let error = NSError(
            domain: "UncaughtException",
            code: 0,
            userInfo: [
                NSLocalizedDescriptionKey: exception.reason ?? "Unknown exception",
                "exception_name": exception.name.rawValue,
                "call_stack": exception.callStackSymbols
            ]
        )
        
        handleError(error, context: nil, isFatal: true)
    }
    
    private func handleSignal(_ signal: Int32) {
        let error = NSError(
            domain: "Signal",
            code: Int(signal),
            userInfo: [
                NSLocalizedDescriptionKey: "Application received signal \(signal)",
                "signal_number": signal
            ]
        )
        
        handleError(error, context: nil, isFatal: true)
    }
    
    private func handleMemoryWarning() {
        log("Memory warning received", level: .warning)
        
        let memoryInfo = getMemoryInfo()
        setCustomValue(memoryInfo.freeMemory, forKey: "free_memory_at_warning")
        setCustomValue(memoryInfo.totalMemory, forKey: "total_memory")
    }
    
    private func handleError(_ error: Error, context: [String: Any]?, isFatal: Bool) {
        let crashReport = createCrashReport(error: error, context: context, isFatal: isFatal)
        
        if isFatal {
            // For fatal errors, try to save immediately
            saveCrashReportSynchronously(crashReport)
        } else {
            // For non-fatal errors, queue for async processing
            pendingReports.append(crashReport)
            processPendingReports()
        }
        
        // Log the error
        if isFatal {
            Logger.shared.critical("Crash report recorded: \(error.localizedDescription)", error: error, category: .app)
        } else {
            Logger.shared.error("Crash report recorded: \(error.localizedDescription)", error: error, category: .app)
        }
        
        // Track in analytics
        AnalyticsManager.shared.trackError(
            message: error.localizedDescription,
            category: "crash_reporting",
            error: error
        )
    }
    
    private func createCrashReport(error: Error, context: [String: Any]?, isFatal: Bool) -> CrashReport {
        let deviceInfo = getDeviceInfo()
        let appInfo = getAppInfo()
        
        var combinedContext = context ?? [:]
        combinedContext["is_fatal"] = isFatal
        combinedContext["thread"] = Thread.current.name ?? "unknown"
        combinedContext["timestamp"] = Date().timeIntervalSince1970
        
        return CrashReport(
            timestamp: Date(),
            error: error,
            context: combinedContext,
            userInfo: (error as NSError).userInfo,
            customKeys: customKeys,
            logMessages: Array(logMessages.suffix(10)), // Include last 10 log messages
            deviceInfo: deviceInfo,
            appInfo: appInfo
        )
    }
    
    private func getDeviceInfo() -> CrashReport.DeviceInfo {
        let memoryInfo = getMemoryInfo()
        
        return CrashReport.DeviceInfo(
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: AppConfiguration.current.buildVersion,
            buildNumber: AppConfiguration.current.buildNumber,
            freeMemory: memoryInfo.freeMemory,
            totalMemory: memoryInfo.totalMemory,
            batteryLevel: UIDevice.current.batteryLevel,
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
    }
    
    private func getAppInfo() -> CrashReport.AppInfo {
        return CrashReport.AppInfo(
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "unknown",
            version: AppConfiguration.current.buildVersion,
            buildNumber: AppConfiguration.current.buildNumber,
            environment: AppConfiguration.current.environment.rawValue,
            launchTime: Date(), // This should be set at app launch
            sessionDuration: Date().timeIntervalSince1970 // This should track actual session time
        )
    }
    
    private func getMemoryInfo() -> (freeMemory: UInt64, totalMemory: UInt64) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let totalMemory = ProcessInfo.processInfo.physicalMemory
            let usedMemory = UInt64(info.resident_size)
            let freeMemory = totalMemory > usedMemory ? totalMemory - usedMemory : 0
            
            return (freeMemory: freeMemory, totalMemory: totalMemory)
        }
        
        return (freeMemory: 0, totalMemory: 0)
    }
    
    private func processPendingReports() {
        guard !pendingReports.isEmpty else { return }
        
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            let reportsToProcess = Array(self.pendingReports.prefix(5)) // Process up to 5 at a time
            self.pendingReports.removeFirst(min(5, self.pendingReports.count))
            
            for report in reportsToProcess {
                self.sendCrashReport(report)
            }
        }
    }
    
    private func sendCrashReport(_ report: CrashReport) {
        // In a real implementation, this would send to a crash reporting service
        // For now, we'll simulate the network call and log the report
        
        Task {
            do {
                try await simulateNetworkCall(report)
                Logger.shared.info("Crash report sent successfully", category: .app)
            } catch {
                Logger.shared.error("Failed to send crash report", error: error, category: .app)
                
                // Re-queue for retry if not at max attempts
                if pendingReports.count < 10 { // Limit pending reports
                    pendingReports.append(report)
                }
            }
        }
    }
    
    private func saveCrashReportSynchronously(_ report: CrashReport) {
        // For fatal crashes, save to local storage immediately
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let crashReportsPath = documentsPath.appendingPathComponent("CrashReports")
        
        do {
            try FileManager.default.createDirectory(at: crashReportsPath, withIntermediateDirectories: true)
            
            let reportData = try JSONSerialization.data(withJSONObject: crashReportToDictionary(report))
            let fileName = "crash_\(Int(report.timestamp.timeIntervalSince1970)).json"
            let filePath = crashReportsPath.appendingPathComponent(fileName)
            
            try reportData.write(to: filePath)
            Logger.shared.info("Crash report saved locally: \(fileName)", category: .app)
        } catch {
            Logger.shared.error("Failed to save crash report locally", error: error, category: .app)
        }
    }
    
    private func crashReportToDictionary(_ report: CrashReport) -> [String: Any] {
        return [
            "timestamp": report.timestamp.timeIntervalSince1970,
            "error": [
                "domain": (report.error as NSError).domain,
                "code": (report.error as NSError).code,
                "description": report.error.localizedDescription
            ],
            "context": report.context,
            "user_info": report.userInfo,
            "custom_keys": report.customKeys,
            "log_messages": report.logMessages.map { logMessage in
                [
                    "timestamp": logMessage.timestamp.timeIntervalSince1970,
                    "level": logMessage.level.rawValue,
                    "message": logMessage.message
                ]
            },
            "device_info": [
                "model": report.deviceInfo.model,
                "os_version": report.deviceInfo.osVersion,
                "app_version": report.deviceInfo.appVersion,
                "build_number": report.deviceInfo.buildNumber,
                "free_memory": report.deviceInfo.freeMemory,
                "total_memory": report.deviceInfo.totalMemory,
                "battery_level": report.deviceInfo.batteryLevel,
                "is_low_power_mode": report.deviceInfo.isLowPowerModeEnabled
            ],
            "app_info": [
                "bundle_identifier": report.appInfo.bundleIdentifier,
                "version": report.appInfo.version,
                "build_number": report.appInfo.buildNumber,
                "environment": report.appInfo.environment,
                "launch_time": report.appInfo.launchTime.timeIntervalSince1970,
                "session_duration": report.appInfo.sessionDuration
            ]
        ]
    }
    
    private func simulateNetworkCall(_ report: CrashReport) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Simulate occasional network failures
        if Int.random(in: 1...10) == 1 {
            throw CrashReportingError.networkUnavailable
        }
        
        // In a real implementation, this would be an actual HTTP request
        Logger.shared.debug("Simulated crash report upload for error: \(report.error.localizedDescription)", category: .app)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}