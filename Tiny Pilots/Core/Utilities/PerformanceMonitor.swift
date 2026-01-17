//
//  PerformanceMonitor.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/15/25.
//

import Foundation
import UIKit
import SpriteKit

/// Performance monitoring system for tracking app performance metrics
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    // MARK: - Properties
    
    private var isEnabled = false
    private var configuration: PerformanceConfiguration?
    
    // Frame rate monitoring
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var lastFrameTime: CFAbsoluteTime = 0
    private var frameRateHistory: [Double] = []
    private let maxFrameRateHistory = 60 // Keep last 60 FPS measurements
    
    // Memory monitoring
    private var memoryTimer: Timer?
    private var memoryHistory: [MemoryUsage] = []
    private let maxMemoryHistory = 100 // Keep last 100 memory measurements
    
    // Performance measurements
    private var activeMeasurements: [String: PerformanceMeasurement] = [:]
    private var completedMeasurements: [CompletedMeasurement] = []
    private let maxCompletedMeasurements = 500
    
    // App launch tracking
    private var appLaunchStartTime: CFAbsoluteTime?
    private var appLaunchCompleted = false
    
    // Scene transition tracking
    private var sceneTransitionStartTime: CFAbsoluteTime?
    private var currentScene: String?
    
    // Thermal state monitoring
    private var thermalStateObserver: NSObjectProtocol?
    
    // Performance optimization
    private var optimizationDelegate: PerformanceOptimizationDelegate?
    private var memoryPressureLevel: MemoryPressureLevel = .normal
    private var frameRateTracker = FrameRateTracker()
    
    // MARK: - Initialization
    
    private init() {
        setupThermalStateMonitoring()
        setupMemoryPressureMonitoring()
        trackAppLaunchStart()
    }
    
    // MARK: - Public Interface
    
    func configure(with configuration: PerformanceConfiguration) {
        self.configuration = configuration
        self.isEnabled = configuration.enablePerformanceMetrics
        
        if isEnabled {
            startMonitoring()
        } else {
            stopMonitoring()
        }
        
        Logger.shared.info("Performance monitor configured - enabled: \(isEnabled)", category: .performance)
    }
    
    func startMeasuring(_ operation: String, category: String = "general") -> PerformanceMeasurement {
        let measurement = PerformanceMeasurement(operation: operation, category: category)
        activeMeasurements[measurement.id] = measurement
        
        Logger.shared.debug("Started measuring: \(operation)", category: .performance)
        return measurement
    }
    
    func finishMeasurement(_ measurement: PerformanceMeasurement) {
        guard let activeMeasurement = activeMeasurements.removeValue(forKey: measurement.id) else {
            Logger.shared.warning("Attempted to finish unknown measurement: \(measurement.operation)", category: .performance)
            return
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - activeMeasurement.startTime
        let completedMeasurement = CompletedMeasurement(
            operation: activeMeasurement.operation,
            category: activeMeasurement.category,
            duration: duration,
            timestamp: Date(),
            metadata: activeMeasurement.metadata
        )
        
        addCompletedMeasurement(completedMeasurement)
        
        // Check for slow operations
        if duration > 2.0 {
            Logger.shared.warning("Slow operation detected: \(activeMeasurement.operation) took \(String(format: "%.2f", duration))s", category: .performance)
            
            // Track slow operations in analytics
            AnalyticsManager.shared.trackEvent(.slowSceneTransition(
                fromScene: currentScene ?? "unknown",
                toScene: activeMeasurement.operation,
                duration: duration
            ))
        }
        
        // Track performance metric in analytics
        let stringInfo: [String: String] = activeMeasurement.metadata.reduce(into: [:]) { dict, pair in
            let (key, value) = pair
            if let str = value as? String { dict[key] = str }
            else { dict[key] = String(describing: value) }
        }
        let metric = PerformanceMetric(
            name: activeMeasurement.operation,
            value: duration,
            unit: "seconds",
            category: activeMeasurement.category,
            additionalInfo: stringInfo
        )
        AnalyticsManager.shared.trackPerformance(metric)
        
        Logger.shared.debug("Finished measuring: \(activeMeasurement.operation) - \(String(format: "%.3f", duration))s", category: .performance)
    }
    
    func trackSceneTransition(from fromScene: String, to toScene: String) {
        if let startTime = sceneTransitionStartTime {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            let measurement = CompletedMeasurement(
                operation: "scene_transition",
                category: "scene",
                duration: duration,
                timestamp: Date(),
                metadata: [
                    "from_scene": fromScene,
                    "to_scene": toScene
                ]
            )
            
            addCompletedMeasurement(measurement)
            
            // Track in analytics
            AnalyticsManager.shared.trackEvent(.slowSceneTransition(
                fromScene: fromScene,
                toScene: toScene,
                duration: duration
            ))
        }
        
        currentScene = toScene
        sceneTransitionStartTime = CFAbsoluteTimeGetCurrent()
    }
    
    func trackAppLaunchCompleted() {
        guard !appLaunchCompleted, let startTime = appLaunchStartTime else { return }
        
        let launchDuration = CFAbsoluteTimeGetCurrent() - startTime
        appLaunchCompleted = true
        
        let measurement = CompletedMeasurement(
            operation: "app_launch",
            category: "app",
            duration: launchDuration,
            timestamp: Date(),
            metadata: [:]
        )
        
        addCompletedMeasurement(measurement)
        
        // Track in analytics
        AnalyticsManager.shared.trackEvent(.appLaunchCompleted(duration: launchDuration))
        
        Logger.shared.info("App launch completed in \(String(format: "%.2f", launchDuration))s", category: .performance)
    }
    
    func getCurrentFrameRate() -> Double {
        guard !frameRateHistory.isEmpty else { return 0.0 }
        return frameRateHistory.last ?? 0.0
    }
    
    func getAverageFrameRate() -> Double {
        guard !frameRateHistory.isEmpty else { return 0.0 }
        return frameRateHistory.reduce(0, +) / Double(frameRateHistory.count)
    }
    
    func getCurrentMemoryUsage() -> MemoryUsage {
        return getMemoryUsage()
    }
    
    func getPerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            currentFrameRate: getCurrentFrameRate(),
            averageFrameRate: getAverageFrameRate(),
            currentMemoryUsage: getCurrentMemoryUsage(),
            recentMeasurements: Array(completedMeasurements.suffix(20)),
            thermalState: ProcessInfo.processInfo.thermalState
        )
    }
    
    // MARK: - Performance Optimization
    
    func setOptimizationDelegate(_ delegate: PerformanceOptimizationDelegate?) {
        optimizationDelegate = delegate
    }
    
    func recordFrame(at currentTime: TimeInterval) {
        frameRateTracker.recordFrame(currentTime)
        
        let currentFPS = frameRateTracker.currentFPS
        
        // Check for frame rate issues
        if let config = configuration, currentFPS < Double(config.targetFrameRate) * 0.8 && frameRateTracker.isStable {
            handleLowFPS(currentFPS)
        }
    }
    
    func handleThermalStateChange(_ newState: ProcessInfo.ThermalState) {
        Logger.shared.info("Thermal state changed to \(thermalStateDescription(newState))", category: .performance)
        
        // Notify optimization delegate
        optimizationDelegate?.performanceMonitorDetectedThermalChange(self, state: newState)
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(.errorOccurred(category: "performance", message: "thermal_state_changed: \(newState)", isFatal: false))
    }
    
    func getOptimizationRecommendations() -> [PerformanceRecommendation] {
        var recommendations: [PerformanceRecommendation] = []
        
        // FPS recommendations
        let avgFPS = getAverageFrameRate()
        if let config = configuration, avgFPS < Double(config.targetFrameRate) * 0.8 {
            recommendations.append(.reduceParticleEffects)
            recommendations.append(.lowerRenderQuality)
            
            if DeviceCapabilityManager.shared.performanceTier == .minimal {
                recommendations.append(.reducePhysicsAccuracy)
            }
        }
        
        // Memory recommendations
        if memoryPressureLevel != .normal {
            recommendations.append(.clearTextureCache)
            recommendations.append(.reduceNodeCount)
            
            if memoryPressureLevel == .critical {
                recommendations.append(.forceGarbageCollection)
            }
        }
        
        // Thermal recommendations
        let thermalState = ProcessInfo.processInfo.thermalState
        if thermalState != .nominal {
            recommendations.append(.reduceFrameRate)
            recommendations.append(.disableNonEssentialEffects)
            
            if thermalState == .critical {
                recommendations.append(.pauseBackgroundProcesses)
            }
        }
        
        return recommendations
    }
    
    private func handleLowFPS(_ fps: Double) {
        Logger.shared.warning("Low FPS detected: \(String(format: "%.1f", fps))", category: .performance)
        
        // Notify optimization delegate
        optimizationDelegate?.performanceMonitorDetectedLowFPS(self, fps: fps)
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(.lowFrameRateDetected(fps: fps, scene: currentScene ?? "unknown"))
    }
    
    private func setupMemoryPressureMonitoring() {
        // Monitor memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        Logger.shared.warning("Memory warning received", category: .performance)
        memoryPressureLevel = .high
        
        // Notify optimization delegate
        optimizationDelegate?.performanceMonitorDetectedMemoryPressure(self, level: .high)
        
        // Track analytics
        AnalyticsManager.shared.trackEvent(.errorOccurred(category: "performance", message: "memory_warning_received", isFatal: false))
    }
    
    private func updateMemoryPressure() {
        let currentMemory = getCurrentMemoryUsage().usedMemoryMB
        
        let newLevel: MemoryPressureLevel
        if let config = configuration {
            let threshold = Double(config.maxMemoryUsage)
            if currentMemory > threshold * 1.5 {
                newLevel = .critical
            } else if currentMemory > threshold {
                newLevel = .high
            } else if currentMemory > threshold * 0.7 {
                newLevel = .moderate
            } else {
                newLevel = .normal
            }
        } else {
            newLevel = .normal
        }
        
        if newLevel != memoryPressureLevel {
            let oldLevel = memoryPressureLevel
            memoryPressureLevel = newLevel
            
            Logger.shared.info("Memory pressure changed from \(oldLevel) to \(newLevel)", category: .performance)
            optimizationDelegate?.performanceMonitorDetectedMemoryPressure(self, level: newLevel)
        }
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        startFrameRateMonitoring()
        startMemoryMonitoring()
        Logger.shared.info("Performance monitoring started", category: .performance)
    }
    
    private func stopMonitoring() {
        stopFrameRateMonitoring()
        stopMemoryMonitoring()
        Logger.shared.info("Performance monitoring stopped", category: .performance)
    }
    
    private func startFrameRateMonitoring() {
        guard displayLink == nil else { return }
        
        displayLink = CADisplayLink(target: self, selector: #selector(frameRateUpdate))
        displayLink?.add(to: .main, forMode: .common)
        lastFrameTime = CFAbsoluteTimeGetCurrent()
    }
    
    private func stopFrameRateMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func frameRateUpdate() {
        frameCount += 1
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        // Calculate FPS every second
        if currentTime - lastFrameTime >= 1.0 {
            let fps = Double(frameCount) / (currentTime - lastFrameTime)
            addFrameRateReading(fps)
            
            frameCount = 0
            lastFrameTime = currentTime
            
            // Check for low frame rate
            if let config = configuration, fps < Double(config.targetFrameRate) * 0.8 {
                Logger.shared.warning("Low frame rate detected: \(String(format: "%.1f", fps)) FPS", category: .performance)
                
                // Track in analytics
                AnalyticsManager.shared.trackEvent(.lowFrameRateDetected(
                    fps: fps,
                    scene: currentScene ?? "unknown"
                ))
            }
        }
    }
    
    private func addFrameRateReading(_ fps: Double) {
        frameRateHistory.append(fps)
        
        // Keep only recent readings
        if frameRateHistory.count > maxFrameRateHistory {
            frameRateHistory.removeFirst(frameRateHistory.count - maxFrameRateHistory)
        }
    }
    
    private func startMemoryMonitoring() {
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
    }
    
    private func stopMemoryMonitoring() {
        memoryTimer?.invalidate()
        memoryTimer = nil
    }
    
    private func updateMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        addMemoryReading(memoryUsage)
        
        // Check for high memory usage
        if let config = configuration {
            let memoryMB = Double(memoryUsage.usedMemory) / 1024.0 / 1024.0
            if memoryMB > Double(config.maxMemoryUsage) {
                Logger.shared.warning("High memory usage detected: \(String(format: "%.1f", memoryMB)) MB", category: .performance)
                
                // Track in analytics
                AnalyticsManager.shared.trackEvent(.highMemoryUsageDetected(memoryMB: memoryMB))
            }
        }
    }
    
    private func getMemoryUsage() -> MemoryUsage {
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
            return MemoryUsage(
                usedMemory: UInt64(info.resident_size),
                totalMemory: ProcessInfo.processInfo.physicalMemory,
                timestamp: Date()
            )
        }
        
        return MemoryUsage(usedMemory: 0, totalMemory: 0, timestamp: Date())
    }
    
    private func addMemoryReading(_ memoryUsage: MemoryUsage) {
        memoryHistory.append(memoryUsage)
        
        // Keep only recent readings
        if memoryHistory.count > maxMemoryHistory {
            memoryHistory.removeFirst(memoryHistory.count - maxMemoryHistory)
        }
    }
    
    private func addCompletedMeasurement(_ measurement: CompletedMeasurement) {
        completedMeasurements.append(measurement)
        
        // Keep only recent measurements
        if completedMeasurements.count > maxCompletedMeasurements {
            completedMeasurements.removeFirst(completedMeasurements.count - maxCompletedMeasurements)
        }
    }
    
    private func setupThermalStateMonitoring() {
        thermalStateObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleThermalStateChange()
        }
    }
    
    private func handleThermalStateChange() {
        let thermalState = ProcessInfo.processInfo.thermalState
        Logger.shared.info("Thermal state changed: \(thermalStateDescription(thermalState))", category: .performance)
        
        // Adjust performance based on thermal state
        if thermalState == .serious || thermalState == .critical {
            Logger.shared.warning("High thermal state detected, consider reducing performance", category: .performance)
        }
    }
    
    private func thermalStateDescription(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
    
    func trackAppLaunchTime() {
        trackAppLaunchStart()
    }
    
    private func trackAppLaunchStart() {
        appLaunchStartTime = CFAbsoluteTimeGetCurrent()
    }
    
    deinit {
        stopMonitoring()
        if let observer = thermalStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - Supporting Types

struct MemoryUsage {
    let usedMemory: UInt64
    let totalMemory: UInt64
    let timestamp: Date
    
    var usedMemoryMB: Double {
        return Double(usedMemory) / 1024.0 / 1024.0
    }
    
    var totalMemoryMB: Double {
        return Double(totalMemory) / 1024.0 / 1024.0
    }
    
    var memoryPercentage: Double {
        guard totalMemory > 0 else { return 0.0 }
        return Double(usedMemory) / Double(totalMemory) * 100.0
    }
}

class PerformanceMeasurement {
    let id: String
    let operation: String
    let category: String
    let startTime: CFAbsoluteTime
    var metadata: [String: Any] = [:]
    
    init(operation: String, category: String = "general") {
        self.id = UUID().uuidString
        self.operation = operation
        self.category = category
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func addMetadata(_ key: String, value: Any) {
        metadata[key] = value
    }
    
    func finish() {
        PerformanceMonitor.shared.finishMeasurement(self)
    }
}

struct CompletedMeasurement {
    let operation: String
    let category: String
    let duration: TimeInterval
    let timestamp: Date
    let metadata: [String: Any]
    
    var durationMs: Double {
        return duration * 1000.0
    }
}

struct PerformanceReport {
    let currentFrameRate: Double
    let averageFrameRate: Double
    let currentMemoryUsage: MemoryUsage
    let recentMeasurements: [CompletedMeasurement]
    let thermalState: ProcessInfo.ThermalState
    
    var summary: String {
        return """
        Performance Report:
        - Current FPS: \(String(format: "%.1f", currentFrameRate))
        - Average FPS: \(String(format: "%.1f", averageFrameRate))
        - Memory Usage: \(String(format: "%.1f", currentMemoryUsage.usedMemoryMB)) MB
        - Thermal State: \(thermalStateString)
        - Recent Measurements: \(recentMeasurements.count)
        """
    }
    
    private var thermalStateString: String {
        switch thermalState {
        case .nominal: return "Normal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Additional Supporting Types

enum MemoryPressureLevel: String, CaseIterable {
    case normal = "Normal"
    case moderate = "Moderate"
    case high = "High"
    case critical = "Critical"
}

enum PerformanceRecommendation: String, CaseIterable {
    case reduceParticleEffects = "Reduce particle effects"
    case lowerRenderQuality = "Lower render quality"
    case reducePhysicsAccuracy = "Reduce physics accuracy"
    case clearTextureCache = "Clear texture cache"
    case reduceNodeCount = "Reduce node count"
    case forceGarbageCollection = "Force garbage collection"
    case reduceFrameRate = "Reduce frame rate"
    case disableNonEssentialEffects = "Disable non-essential effects"
    case pauseBackgroundProcesses = "Pause background processes"
}

class FrameRateTracker {
    private var frameTimes: [TimeInterval] = []
    private var lastFrameTime: TimeInterval = 0
    private(set) var frameCount: Int = 0
    
    var currentFPS: Double {
        guard frameTimes.count > 1 else { return 0 }
        let recentFrames = Array(frameTimes.suffix(10))
        let totalTime = recentFrames.last! - recentFrames.first!
        return totalTime > 0 ? Double(recentFrames.count - 1) / totalTime : 0
    }
    
    var averageFPS: Double {
        guard frameTimes.count > 1 else { return 0 }
        let totalTime = frameTimes.last! - frameTimes.first!
        return totalTime > 0 ? Double(frameTimes.count - 1) / totalTime : 0
    }
    
    var isStable: Bool {
        guard frameTimes.count >= 60 else { return false } // Need at least 1 second of data
        
        let recentFrames = Array(frameTimes.suffix(60))
        var fpsSamples: [Double] = []
        
        for i in 1..<recentFrames.count {
            let deltaTime = recentFrames[i] - recentFrames[i-1]
            if deltaTime > 0 {
                fpsSamples.append(1.0 / deltaTime)
            }
        }
        
        guard !fpsSamples.isEmpty else { return false }
        
        let average = fpsSamples.reduce(0, +) / Double(fpsSamples.count)
        let variance = fpsSamples.reduce(0) { $0 + pow($1 - average, 2) } / Double(fpsSamples.count)
        
        return variance < 25 // Low variance indicates stability
    }
    
    func recordFrame(_ currentTime: TimeInterval) {
        if lastFrameTime > 0 {
            frameTimes.append(currentTime)
            
            // Keep only recent frame times (last 5 seconds)
            if frameTimes.count > 300 {
                frameTimes.removeFirst()
            }
        }
        
        lastFrameTime = currentTime
        frameCount += 1
    }
}

protocol PerformanceOptimizationDelegate: AnyObject {
    func performanceMonitorDetectedLowFPS(_ monitor: PerformanceMonitor, fps: Double)
    func performanceMonitorDetectedMemoryPressure(_ monitor: PerformanceMonitor, level: MemoryPressureLevel)
    func performanceMonitorDetectedThermalChange(_ monitor: PerformanceMonitor, state: ProcessInfo.ThermalState)
}

