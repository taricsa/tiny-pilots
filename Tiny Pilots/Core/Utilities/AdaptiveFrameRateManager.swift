import UIKit
import SpriteKit

/// Manages adaptive frame rate for ProMotion displays and device-specific optimizations
class AdaptiveFrameRateManager {
    static let shared = AdaptiveFrameRateManager()
    
    // MARK: - Properties
    
    /// Current target frame rate
    private(set) var currentFrameRate: Int = 60
    
    /// Whether adaptive frame rate is enabled
    private(set) var isAdaptiveEnabled: Bool = false
    
    /// Frame rate history for adaptive decisions
    private var frameRateHistory: [Double] = []
    
    /// Performance monitoring
    private var performanceTracker = AdaptivePerformanceTracker()
    
    /// Current scene reference for optimization
    private weak var currentScene: SKScene?
    
    /// Timer for adaptive adjustments
    private var adaptiveTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        setupAdaptiveFrameRate()
    }
    
    // MARK: - Setup
    
    private func setupAdaptiveFrameRate() {
        let deviceManager = DeviceCapabilityManager.shared
        
        if deviceManager.shouldUseAdaptiveFrameRate() {
            isAdaptiveEnabled = true
            currentFrameRate = deviceManager.maximumFrameRate
            
            Logger.shared.info("Adaptive frame rate enabled - max: \(currentFrameRate)fps", category: .performance)
            
            startAdaptiveMonitoring()
        } else {
            isAdaptiveEnabled = false
            currentFrameRate = 60
            
            Logger.shared.info("Adaptive frame rate disabled - fixed: \(currentFrameRate)fps", category: .performance)
        }
    }
    
    // MARK: - Public Interface
    
    /// Set the current scene for optimization
    func setCurrentScene(_ scene: SKScene?) {
        currentScene = scene
        
        if let scene = scene {
            applyFrameRateToScene(scene)
        }
    }
    
    /// Record frame performance for adaptive decisions
    func recordFramePerformance(fps: Double, memoryUsage: Double) {
        frameRateHistory.append(fps)
        
        // Keep only recent history
        if frameRateHistory.count > 120 { // 2 seconds at 60fps
            frameRateHistory.removeFirst()
        }
        
        performanceTracker.recordPerformance(fps: fps, memoryUsage: memoryUsage)
        
        // Check if adaptive adjustment is needed
        if isAdaptiveEnabled {
            checkAdaptiveAdjustment()
        }
    }
    
    /// Force a specific frame rate
    func setFrameRate(_ frameRate: Int, reason: String) {
        let oldFrameRate = currentFrameRate
        currentFrameRate = frameRate
        
        Logger.shared.info("Frame rate changed: \(oldFrameRate) -> \(frameRate)fps (\(reason))", category: .performance)
        
        if let scene = currentScene {
            applyFrameRateToScene(scene)
        }
        
        // Notify observers
        NotificationCenter.default.post(
            name: .frameRateDidChange,
            object: self,
            userInfo: [
                "oldFrameRate": oldFrameRate,
                "newFrameRate": frameRate,
                "reason": reason
            ]
        )
    }
    
    /// Get optimal frame rate for current conditions
    func getOptimalFrameRate() -> Int {
        guard isAdaptiveEnabled else { return currentFrameRate }
        
        let deviceManager = DeviceCapabilityManager.shared
        let thermalState = ProcessInfo.processInfo.thermalState
        
        // Check thermal state first
        switch thermalState {
        case .critical:
            return 30
        case .serious:
            return 30
        case .fair:
            return 60
        case .nominal:
            break
        @unknown default:
            break
        }
        
        // Check performance history
        if let averageFPS = getAverageRecentFPS() {
            let maxFrameRate = deviceManager.maximumFrameRate
            
            if averageFPS < 45 && currentFrameRate > 30 {
                // Performance is poor, reduce to 30fps
                return 30
            } else if averageFPS < 90 && currentFrameRate > 60 {
                // Can't maintain high frame rate, reduce to 60fps
                return 60
            } else if averageFPS > 110 && currentFrameRate < maxFrameRate {
                // Performance is good, can increase frame rate
                return maxFrameRate
            }
        }
        
        return currentFrameRate
    }
    
    // MARK: - Adaptive Monitoring
    
    private func startAdaptiveMonitoring() {
        adaptiveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.performAdaptiveAdjustment()
        }
    }
    
    private func stopAdaptiveMonitoring() {
        adaptiveTimer?.invalidate()
        adaptiveTimer = nil
    }
    
    private func checkAdaptiveAdjustment() {
        // Only adjust every few seconds to avoid rapid changes
        guard performanceTracker.shouldConsiderAdjustment() else { return }
        
        let optimalFrameRate = getOptimalFrameRate()
        
        if optimalFrameRate != currentFrameRate {
            let reason = determineAdjustmentReason(from: currentFrameRate, to: optimalFrameRate)
            setFrameRate(optimalFrameRate, reason: reason)
        }
    }
    
    private func performAdaptiveAdjustment() {
        guard isAdaptiveEnabled else { return }
        
        let optimalFrameRate = getOptimalFrameRate()
        
        if optimalFrameRate != currentFrameRate {
            let reason = "Adaptive adjustment based on performance"
            setFrameRate(optimalFrameRate, reason: reason)
        }
    }
    
    // MARK: - Helper Methods
    
    private func applyFrameRateToScene(_ scene: SKScene) {
        scene.view?.preferredFramesPerSecond = currentFrameRate
        
        // Adjust physics update rate based on frame rate
        let physicsUpdateRate = min(currentFrameRate, 60) // Cap physics at 60fps for stability
        
        // This would typically be applied to a physics service
        // For now, we'll just log the change
        Logger.shared.debug("Applied \(currentFrameRate)fps to scene (physics: \(physicsUpdateRate)fps)", category: .performance)
    }
    
    private func getAverageRecentFPS() -> Double? {
        guard !frameRateHistory.isEmpty else { return nil }
        
        let recentFrames = Array(frameRateHistory.suffix(60)) // Last second
        return recentFrames.reduce(0, +) / Double(recentFrames.count)
    }
    
    private func determineAdjustmentReason(from oldRate: Int, to newRate: Int) -> String {
        if newRate < oldRate {
            if ProcessInfo.processInfo.thermalState != .nominal {
                return "Thermal throttling"
            } else {
                return "Performance optimization"
            }
        } else {
            return "Performance improvement"
        }
    }
    
    deinit {
        stopAdaptiveMonitoring()
    }
}

// MARK: - Adaptive Performance Tracker

class AdaptivePerformanceTracker {
    private var performanceHistory: [PerformanceSnapshot] = []
    private var lastAdjustmentTime: TimeInterval = 0
    private let adjustmentCooldown: TimeInterval = 5.0 // 5 seconds between adjustments
    
    func recordPerformance(fps: Double, memoryUsage: Double) {
        let snapshot = PerformanceSnapshot(
            fps: fps,
            memoryUsage: memoryUsage,
            timestamp: CACurrentMediaTime(),
            thermalState: ProcessInfo.processInfo.thermalState
        )
        
        performanceHistory.append(snapshot)
        
        // Keep only recent history (last 30 seconds)
        let cutoffTime = snapshot.timestamp - 30.0
        performanceHistory.removeAll { $0.timestamp < cutoffTime }
    }
    
    func shouldConsiderAdjustment() -> Bool {
        let currentTime = CACurrentMediaTime()
        return currentTime - lastAdjustmentTime > adjustmentCooldown
    }
    
    func getPerformanceTrend() -> PerformanceTrend {
        guard performanceHistory.count >= 10 else { return .stable }
        
        let recent = Array(performanceHistory.suffix(10))
        let older = Array(performanceHistory.prefix(max(0, performanceHistory.count - 10)).suffix(10))
        
        guard !older.isEmpty else { return .stable }
        
        let recentAvgFPS = recent.reduce(0) { $0 + $1.fps } / Double(recent.count)
        let olderAvgFPS = older.reduce(0) { $0 + $1.fps } / Double(older.count)
        
        let change = (recentAvgFPS - olderAvgFPS) / olderAvgFPS
        
        if change > 0.1 {
            return .improving
        } else if change < -0.1 {
            return .degrading
        } else {
            return .stable
        }
    }
    
    func markAdjustmentMade() {
        lastAdjustmentTime = CACurrentMediaTime()
    }
}

// MARK: - Supporting Types

struct PerformanceSnapshot {
    let fps: Double
    let memoryUsage: Double
    let timestamp: TimeInterval
    let thermalState: ProcessInfo.ThermalState
}

enum PerformanceTrend {
    case improving
    case stable
    case degrading
}

// MARK: - Device-Specific Optimization Extensions

extension AdaptiveFrameRateManager {
    
    /// Apply device-specific optimizations
    func applyDeviceOptimizations() {
        let deviceManager = DeviceCapabilityManager.shared
        
        switch deviceManager.deviceModel {
        case .iPhone6, .iPhone6s:
            // Force 30fps for very old devices
            setFrameRate(30, reason: "Device compatibility (iPhone 6/6s)")
            
        case .iPhone7:
            // Conservative 30fps for iPhone 7
            setFrameRate(30, reason: "Device compatibility (iPhone 7)")
            
        case .iPhoneX, .iPad8thGen, .iPad9thGen:
            // Standard 60fps for mid-range devices
            setFrameRate(60, reason: "Device optimization (mid-range)")
            
        case .iPhone11Pro, .iPhone12Pro, .iPhone13Pro:
            // 60fps default, can go to 120fps if ProMotion available
            if deviceManager.supportsProMotion {
                setFrameRate(120, reason: "ProMotion optimization")
            } else {
                setFrameRate(60, reason: "Device optimization (high-end)")
            }
            
        case .iPhone14Pro, .iPhone15Pro, .iPadPro2021, .iPadPro2022:
            // Latest devices can handle 120fps
            if deviceManager.supportsProMotion {
                setFrameRate(120, reason: "ProMotion optimization (latest)")
            } else {
                setFrameRate(60, reason: "Device optimization (latest)")
            }
            
        default:
            // Default to 60fps for unknown devices
            setFrameRate(60, reason: "Default optimization")
        }
    }
    
    /// Handle thermal state changes
    func handleThermalStateChange(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal:
            // Can return to optimal frame rate
            let optimalRate = getOptimalFrameRate()
            setFrameRate(optimalRate, reason: "Thermal state normal")
            
        case .fair:
            // Slight reduction if currently at high frame rate
            if currentFrameRate > 60 {
                setFrameRate(60, reason: "Thermal state fair")
            }
            
        case .serious:
            // Reduce to 30fps
            setFrameRate(30, reason: "Thermal state serious")
            
        case .critical:
            // Emergency 30fps
            setFrameRate(30, reason: "Thermal state critical")
            
        @unknown default:
            break
        }
    }
    
    /// Handle memory pressure
    func handleMemoryPressure(_ level: MemoryPressureLevel) {
        switch level {
        case .normal:
            // Can use optimal frame rate
            break
            
        case .moderate:
            // Slight reduction if at high frame rate
            if currentFrameRate > 60 {
                setFrameRate(60, reason: "Memory pressure moderate")
            }
            
        case .high:
            // Reduce to 30fps to save memory
            setFrameRate(30, reason: "Memory pressure high")
            
        case .critical:
            // Emergency 30fps
            setFrameRate(30, reason: "Memory pressure critical")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let frameRateDidChange = Notification.Name("FrameRateDidChange")
}

