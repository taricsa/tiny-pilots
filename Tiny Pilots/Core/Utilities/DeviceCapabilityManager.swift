import UIKit
import SpriteKit

/// Manages device capability detection and performance optimization settings
class DeviceCapabilityManager {
    static let shared = DeviceCapabilityManager()
    
    // MARK: - Device Information
    
    /// Current device model information
    private(set) var deviceModel: DeviceModel
    
    /// Current device performance tier
    private(set) var performanceTier: PerformanceTier
    
    /// Whether the device supports ProMotion (120Hz)
    private(set) var supportsProMotion: Bool
    
    /// Current thermal state
    private(set) var thermalState: ProcessInfo.ThermalState = .nominal
    
    /// Device memory information
    private(set) var availableMemory: UInt64 = 0
    
    // MARK: - Performance Settings
    
    /// Current quality settings based on device capabilities
    private(set) var qualitySettings: QualitySettings
    
    /// Whether performance monitoring is active
    private var isMonitoringPerformance = false
    
    /// Thermal state observer
    private var thermalStateObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    private init() {
        self.deviceModel = DeviceCapabilityManager.detectDeviceModel()
        self.performanceTier = DeviceCapabilityManager.determinePerformanceTier(for: deviceModel)
        self.supportsProMotion = DeviceCapabilityManager.detectProMotionSupport()
        self.qualitySettings = QualitySettings.recommended(for: performanceTier)
        
        updateMemoryInfo()
        startThermalStateMonitoring()
    }
    
    deinit {
        stopThermalStateMonitoring()
    }
    
    // MARK: - Device Detection
    
    private static func detectDeviceModel() -> DeviceModel {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        
        guard let code = modelCode else { return .unknown }
        
        // iPhone models
        if code.hasPrefix("iPhone") {
            if code >= "iPhone15" { return .iPhone15Pro }
            if code >= "iPhone14" { return .iPhone14Pro }
            if code >= "iPhone13" { return .iPhone13Pro }
            if code >= "iPhone12" { return .iPhone12Pro }
            if code >= "iPhone11" { return .iPhone11Pro }
            if code >= "iPhone10" { return .iPhoneX }
            if code >= "iPhone9" { return .iPhone7 }
            if code >= "iPhone8" { return .iPhone6s }
            return .iPhone6
        }
        
        // iPad models
        if code.hasPrefix("iPad") {
            if code.contains("Pro") {
                if code >= "iPad13" { return .iPadPro2022 }
                if code >= "iPad11" { return .iPadPro2021 }
                return .iPadPro2020
            }
            if code >= "iPad13" { return .iPad10thGen }
            if code >= "iPad11" { return .iPad9thGen }
            return .iPad8thGen
        }
        
        return .unknown
    }
    
    private static func determinePerformanceTier(for model: DeviceModel) -> PerformanceTier {
        switch model {
        case .iPhone15Pro, .iPhone14Pro, .iPadPro2022, .iPadPro2021:
            return .high
        case .iPhone13Pro, .iPhone12Pro, .iPhone11Pro, .iPadPro2020, .iPad10thGen:
            return .medium
        case .iPhoneX, .iPhone7, .iPad9thGen, .iPad8thGen:
            return .low
        case .iPhone6s, .iPhone6:
            return .minimal
        case .unknown:
            return .low
        }
    }
    
    private static func detectProMotionSupport() -> Bool {
        if #available(iOS 15.0, *) {
            return UIScreen.main.maximumFramesPerSecond > 60
        }
        return false
    }
    
    /// Get the maximum supported frame rate for this device
    var maximumFrameRate: Int {
        if supportsProMotion {
            return 120
        }
        return 60
    }
    
    /// Check if device supports adaptive refresh rate
    var supportsAdaptiveRefreshRate: Bool {
        return supportsProMotion
    }
    
    // MARK: - Memory Management
    
    private func updateMemoryInfo() {
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
            availableMemory = info.resident_size
        }
    }
    
    // MARK: - Thermal State Monitoring
    
    private func startThermalStateMonitoring() {
        thermalState = ProcessInfo.processInfo.thermalState
        
        thermalStateObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleThermalStateChange()
        }
    }
    
    private func stopThermalStateMonitoring() {
        if let observer = thermalStateObserver {
            NotificationCenter.default.removeObserver(observer)
            thermalStateObserver = nil
        }
    }
    
    private func handleThermalStateChange() {
        let newState = ProcessInfo.processInfo.thermalState
        let previousState = thermalState
        thermalState = newState
        
        Logger.shared.info("Thermal state changed from \(previousState) to \(newState)", category: .performance)
        
        // Adjust quality settings based on thermal state
        adjustQualityForThermalState(newState)
        
        // Notify performance monitor
        PerformanceMonitor.shared.handleThermalStateChange(newState)
    }
    
    private func adjustQualityForThermalState(_ state: ProcessInfo.ThermalState) {
        var adjustedSettings = qualitySettings
        
        switch state {
        case .nominal:
            // Use recommended settings
            adjustedSettings = QualitySettings.recommended(for: performanceTier)
            
        case .fair:
            // Slightly reduce quality
            adjustedSettings.particleCount = max(Int(Double(adjustedSettings.particleCount) * 0.8), 10)
            if adjustedSettings.shadowQuality.rawValue > 0 {
                adjustedSettings.shadowQuality = ShadowQuality(rawValue: adjustedSettings.shadowQuality.rawValue - 1) ?? .off
            }
            
        case .serious:
            // Significantly reduce quality
            adjustedSettings.particleCount = max(Int(Double(adjustedSettings.particleCount) * 0.5), 5)
            adjustedSettings.shadowQuality = .off
            adjustedSettings.enableBloom = false
            adjustedSettings.targetFrameRate = min(adjustedSettings.targetFrameRate, 30)
            
        case .critical:
            // Minimal quality settings
            adjustedSettings = QualitySettings.minimal()
            
        @unknown default:
            break
        }
        
        updateQualitySettings(adjustedSettings)
    }
    
    // MARK: - Quality Settings Management
    
    /// Update quality settings and notify observers
    func updateQualitySettings(_ newSettings: QualitySettings) {
        let oldSettings = qualitySettings
        qualitySettings = newSettings
        
        Logger.shared.info("Quality settings updated: \(newSettings)", category: .performance)
        
        // Post notification for observers
        NotificationCenter.default.post(
            name: .qualitySettingsDidChange,
            object: self,
            userInfo: [
                "oldSettings": oldSettings,
                "newSettings": newSettings
            ]
        )
    }
    
    /// Get recommended settings for current device and thermal state
    func getRecommendedSettings() -> QualitySettings {
        var settings = QualitySettings.recommended(for: performanceTier)
        
        // Adjust for thermal state
        switch thermalState {
        case .fair:
            settings.particleCount = Int(Double(settings.particleCount) * 0.8)
        case .serious:
            settings.particleCount = Int(Double(settings.particleCount) * 0.5)
            settings.shadowQuality = .low
            settings.enableBloom = false
        case .critical:
            settings = QualitySettings.minimal()
        default:
            break
        }
        
        return settings
    }
    
    /// Check if device can handle specific quality level
    func canHandle(qualityLevel: QualityLevel) -> Bool {
        switch performanceTier {
        case .high:
            return true
        case .medium:
            return qualityLevel != .ultra
        case .low:
            return qualityLevel == .low || qualityLevel == .medium
        case .minimal:
            return qualityLevel == .low
        }
    }
    
    // MARK: - Device-Specific Optimizations
    
    /// Get optimized settings for older devices
    func getCompatibilitySettings() -> QualitySettings {
        var settings = qualitySettings
        
        // Specific optimizations for older devices
        switch deviceModel {
        case .iPhone6, .iPhone6s:
            // Very conservative settings for iPhone 6/6s
            settings.targetFrameRate = 30
            settings.particleCount = 5
            settings.shadowQuality = .off
            settings.enableBloom = false
            settings.enableAntialiasing = false
            settings.textureQuality = .low
            settings.physicsUpdateRate = 20
            settings.maxConcurrentSounds = 2
            
        case .iPhone7:
            // Slightly better for iPhone 7
            settings.targetFrameRate = 30
            settings.particleCount = 10
            settings.shadowQuality = .off
            settings.enableBloom = false
            settings.enableAntialiasing = false
            settings.textureQuality = .low
            settings.physicsUpdateRate = 30
            settings.maxConcurrentSounds = 4
            
        case .iPhoneX, .iPad8thGen, .iPad9thGen:
            // Moderate settings for mid-range devices
            settings.targetFrameRate = 60
            settings.particleCount = 25
            settings.shadowQuality = .low
            settings.enableBloom = false
            settings.enableAntialiasing = false
            settings.textureQuality = .medium
            settings.physicsUpdateRate = 30
            settings.maxConcurrentSounds = 8
            
        default:
            // Use recommended settings for newer devices
            break
        }
        
        return settings
    }
    
    /// Get ProMotion optimized settings
    func getProMotionSettings() -> QualitySettings? {
        guard supportsProMotion else { return nil }
        
        var settings = qualitySettings
        settings.targetFrameRate = 120
        
        // Adjust other settings to maintain 120fps
        switch performanceTier {
        case .high:
            // High-end devices can handle 120fps with good quality
            settings.particleCount = 80
            settings.shadowQuality = .medium
            settings.enableBloom = true
            settings.enableAntialiasing = true
            settings.textureQuality = .high
            settings.physicsUpdateRate = 60
            
        case .medium:
            // Medium devices need reduced quality for 120fps
            settings.particleCount = 40
            settings.shadowQuality = .low
            settings.enableBloom = false
            settings.enableAntialiasing = false
            settings.textureQuality = .medium
            settings.physicsUpdateRate = 60
            
        default:
            // Lower tier devices shouldn't use 120fps
            return nil
        }
        
        return settings
    }
    
    /// Check if device should use adaptive frame rate
    func shouldUseAdaptiveFrameRate() -> Bool {
        return supportsProMotion && performanceTier != .minimal
    }
    
    /// Get thermal throttling response settings
    func getThermalThrottlingSettings(for state: ProcessInfo.ThermalState) -> QualitySettings {
        var settings = qualitySettings
        
        switch state {
        case .nominal:
            // Return to recommended settings
            settings = getRecommendedSettings()
            
        case .fair:
            // Slight reduction
            settings.targetFrameRate = min(settings.targetFrameRate, 60)
            settings.particleCount = Int(Double(settings.particleCount) * 0.8)
            if settings.shadowQuality.rawValue > 0 {
                settings.shadowQuality = ShadowQuality(rawValue: settings.shadowQuality.rawValue - 1) ?? .off
            }
            
        case .serious:
            // Significant reduction
            settings.targetFrameRate = 30
            settings.particleCount = max(Int(Double(settings.particleCount) * 0.5), 5)
            settings.shadowQuality = .off
            settings.enableBloom = false
            settings.enableAntialiasing = false
            settings.physicsUpdateRate = 20
            
        case .critical:
            // Emergency settings
            settings = QualitySettings.minimal()
            
        @unknown default:
            break
        }
        
        return settings
    }
    
    /// Get memory pressure response settings
    func getMemoryPressureSettings(for level: MemoryPressureLevel) -> QualitySettings {
        var settings = qualitySettings
        
        switch level {
        case .normal:
            // Use recommended settings
            break
            
        case .moderate:
            // Reduce texture quality and particle count
            settings.particleCount = Int(Double(settings.particleCount) * 0.8)
            // Downgrade texture quality
            switch settings.textureQuality {
            case .ultra:
                settings.textureQuality = .high
            case .high:
                settings.textureQuality = .medium
            case .medium:
                settings.textureQuality = .low
            case .low:
                break // Already at lowest
            }
            
        case .high:
            // More aggressive reduction
            settings.particleCount = Int(Double(settings.particleCount) * 0.5)
            settings.textureQuality = .low
            settings.shadowQuality = .off
            settings.enableBloom = false
            settings.maxConcurrentSounds = max(settings.maxConcurrentSounds / 2, 2)
            
        case .critical:
            // Minimal settings to preserve memory
            settings.particleCount = 5
            settings.textureQuality = .low
            settings.shadowQuality = .off
            settings.enableBloom = false
            settings.enableAntialiasing = false
            settings.maxConcurrentSounds = 2
        }
        
        return settings
    }
}

// MARK: - Supporting Types

enum DeviceModel: String, CaseIterable {
    case iPhone15Pro = "iPhone15Pro"
    case iPhone14Pro = "iPhone14Pro"
    case iPhone13Pro = "iPhone13Pro"
    case iPhone12Pro = "iPhone12Pro"
    case iPhone11Pro = "iPhone11Pro"
    case iPhoneX = "iPhoneX"
    case iPhone7 = "iPhone7"
    case iPhone6s = "iPhone6s"
    case iPhone6 = "iPhone6"
    case iPadPro2022 = "iPadPro2022"
    case iPadPro2021 = "iPadPro2021"
    case iPadPro2020 = "iPadPro2020"
    case iPad10thGen = "iPad10thGen"
    case iPad9thGen = "iPad9thGen"
    case iPad8thGen = "iPad8thGen"
    case unknown = "Unknown"
}

enum PerformanceTier: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case minimal = "Minimal"
}



enum ShadowQuality: Int, CaseIterable, Codable {
    case off = 0
    case low = 1
    case medium = 2
    case high = 3
}

struct QualitySettings: Codable {
    var targetFrameRate: Int
    var particleCount: Int
    var shadowQuality: ShadowQuality
    var enableBloom: Bool
    var enableAntialiasing: Bool
    var textureQuality: QualityLevel
    var physicsUpdateRate: Int
    var maxConcurrentSounds: Int
    
    static func recommended(for tier: PerformanceTier) -> QualitySettings {
        switch tier {
        case .high:
            return QualitySettings(
                targetFrameRate: DeviceCapabilityManager.shared.supportsProMotion ? 120 : 60,
                particleCount: 100,
                shadowQuality: .high,
                enableBloom: true,
                enableAntialiasing: true,
                textureQuality: .ultra,
                physicsUpdateRate: 60,
                maxConcurrentSounds: 16
            )
        case .medium:
            return QualitySettings(
                targetFrameRate: 60,
                particleCount: 50,
                shadowQuality: .medium,
                enableBloom: true,
                enableAntialiasing: true,
                textureQuality: .high,
                physicsUpdateRate: 60,
                maxConcurrentSounds: 12
            )
        case .low:
            return QualitySettings(
                targetFrameRate: 60,
                particleCount: 25,
                shadowQuality: .low,
                enableBloom: false,
                enableAntialiasing: false,
                textureQuality: .medium,
                physicsUpdateRate: 30,
                maxConcurrentSounds: 8
            )
        case .minimal:
            return QualitySettings(
                targetFrameRate: 30,
                particleCount: 10,
                shadowQuality: .off,
                enableBloom: false,
                enableAntialiasing: false,
                textureQuality: .low,
                physicsUpdateRate: 30,
                maxConcurrentSounds: 4
            )
        }
    }
    
    static func minimal() -> QualitySettings {
        return QualitySettings(
            targetFrameRate: 30,
            particleCount: 5,
            shadowQuality: .off,
            enableBloom: false,
            enableAntialiasing: false,
            textureQuality: .low,
            physicsUpdateRate: 20,
            maxConcurrentSounds: 2
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let qualitySettingsDidChange = Notification.Name("QualitySettingsDidChange")
    static let thermalStateDidChange = Notification.Name("ThermalStateDidChange")
}