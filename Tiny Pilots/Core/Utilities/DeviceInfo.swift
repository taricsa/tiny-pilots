//
//  DeviceInfo.swift
//  Tiny Pilots
//
//  Created by Kiro on Build Fixes Implementation
//

import UIKit
import Metal

/// Quality levels for performance optimization
enum QualityLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case ultra = "Ultra"
    
    var displayName: String {
        return rawValue
    }
    
    var particleCount: Int {
        switch self {
        case .low: return 50
        case .medium: return 100
        case .high: return 200
        case .ultra: return 400
        }
    }
    
    var targetFrameRate: Int {
        switch self {
        case .low: return 30
        case .medium: return 60
        case .high: return 60
        case .ultra: return 120
        }
    }
    
    var shadowQuality: Float {
        switch self {
        case .low: return 0.5
        case .medium: return 0.75
        case .high: return 1.0
        case .ultra: return 1.0
        }
    }
    
    var textureQuality: Float {
        switch self {
        case .low: return 0.5
        case .medium: return 0.75
        case .high: return 1.0
        case .ultra: return 1.0
        }
    }
}

/// Device performance tier classification
enum DevicePerformanceTier: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case flagship = "Flagship"
    
    var recommendedQuality: QualityLevel {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .flagship: return .ultra
        }
    }
}

/// Comprehensive device information for performance optimization
struct DeviceInfo: Codable {
    // MARK: - Basic Device Information
    
    let modelName: String
    let modelIdentifier: String
    let systemVersion: String
    let systemName: String
    
    // MARK: - Display Information
    
    let screenSize: CGSize
    let screenScale: CGFloat
    let screenBounds: CGRect
    let nativeScale: CGFloat
    let maximumFramesPerSecond: Int
    
    // MARK: - Hardware Capabilities
    
    let processorCount: Int
    let physicalMemory: UInt64
    let availableMemory: UInt64
    let diskSpace: UInt64
    let availableDiskSpace: UInt64
    
    // MARK: - Graphics Capabilities
    
    let supportsMetalPerformanceShaders: Bool
    let metalFeatureSet: String
    let gpuFamily: String
    let maxTextureSize: Int
    
    // MARK: - Performance Features
    
    let supportsProMotion: Bool
    let supportsHDR: Bool
    let supportsTrueDepth: Bool
    let supportsWirelessCharging: Bool
    let hasFaceID: Bool
    let hasTouchID: Bool
    
    // MARK: - Computed Properties
    
    /// Whether this is considered a low-end device
    var isLowEndDevice: Bool {
        return performanceTier == .low
    }
    
    /// Whether this is a high-end device
    var isHighEndDevice: Bool {
        return performanceTier == .high || performanceTier == .flagship
    }
    
    /// Device performance tier
    var performanceTier: DevicePerformanceTier {
        // Memory-based classification
        let memoryGB = Double(physicalMemory) / (1024 * 1024 * 1024)
        
        // Processor-based classification
        let hasHighPerformanceProcessor = processorCount >= 6
        
        // Feature-based classification
        let hasAdvancedFeatures = supportsProMotion || supportsHDR || hasFaceID
        
        if memoryGB >= 6 && hasHighPerformanceProcessor && hasAdvancedFeatures {
            return .flagship
        } else if memoryGB >= 4 && (hasHighPerformanceProcessor || hasAdvancedFeatures) {
            return .high
        } else if memoryGB >= 3 {
            return .medium
        } else {
            return .low
        }
    }
    
    /// Recommended quality level based on device capabilities
    var recommendedQualityLevel: QualityLevel {
        return performanceTier.recommendedQuality
    }
    
    /// Whether the device can handle high frame rates
    var canHandleHighFrameRate: Bool {
        return maximumFramesPerSecond > 60 && !isLowEndDevice
    }
    
    /// Whether the device should use reduced particle effects
    var shouldUseReducedParticles: Bool {
        return isLowEndDevice || availableMemory < 1_000_000_000 // Less than 1GB available
    }
    
    /// Whether the device supports advanced graphics features
    var supportsAdvancedGraphics: Bool {
        return supportsMetalPerformanceShaders && !isLowEndDevice
    }
    
    /// Thermal throttling risk level (0.0 = low, 1.0 = high)
    var thermalThrottlingRisk: Float {
        // Estimate based on device characteristics
        if isLowEndDevice {
            return 0.8 // High risk for low-end devices
        } else if performanceTier == .medium {
            return 0.5 // Medium risk
        } else {
            return 0.2 // Low risk for high-end devices
        }
    }
    
    // MARK: - Static Properties
    
    /// Current device information
    static var current: DeviceInfo {
        let device = UIDevice.current
        let screen = UIScreen.main
        let processInfo = ProcessInfo.processInfo
        
        // Get Metal device information
        let metalDevice = MTLCreateSystemDefaultDevice()
        let supportsMetalPerformanceShaders = metalDevice != nil
        let metalFeatureSet = getMetalFeatureSet(metalDevice)
        let gpuFamily = getGPUFamily(metalDevice)
        let maxTextureSize = getMaxTextureSize(metalDevice)
        
        // Get memory information
        let physicalMemory = processInfo.physicalMemory
        let availableMemory = getAvailableMemory()
        
        // Get disk space information
        let (diskSpace, availableDiskSpace) = getDiskSpaceInfo()
        
        return DeviceInfo(
            modelName: device.modelName,
            modelIdentifier: device.modelIdentifier,
            systemVersion: device.systemVersion,
            systemName: device.systemName,
            screenSize: screen.bounds.size,
            screenScale: screen.scale,
            screenBounds: screen.bounds,
            nativeScale: screen.nativeScale,
            maximumFramesPerSecond: screen.maximumFramesPerSecond,
            processorCount: processInfo.processorCount,
            physicalMemory: physicalMemory,
            availableMemory: availableMemory,
            diskSpace: diskSpace,
            availableDiskSpace: availableDiskSpace,
            supportsMetalPerformanceShaders: supportsMetalPerformanceShaders,
            metalFeatureSet: metalFeatureSet,
            gpuFamily: gpuFamily,
            maxTextureSize: maxTextureSize,
            supportsProMotion: screen.maximumFramesPerSecond > 60,
            supportsHDR: screen.traitCollection.displayGamut != .unspecified,
            supportsTrueDepth: device.supportsTrueDepth,
            supportsWirelessCharging: device.supportsWirelessCharging,
            hasFaceID: device.hasFaceID,
            hasTouchID: device.hasTouchID
        )
    }
    
    // MARK: - Performance Recommendations
    
    /// Get recommended settings for the current device
    func getRecommendedSettings() -> PerformanceSettings {
        let quality = recommendedQualityLevel
        
        return PerformanceSettings(
            qualityLevel: quality,
            targetFrameRate: canHandleHighFrameRate ? quality.targetFrameRate : 60,
            particleCount: shouldUseReducedParticles ? quality.particleCount / 2 : quality.particleCount,
            shadowQuality: quality.shadowQuality,
            textureQuality: quality.textureQuality,
            enableAdvancedEffects: supportsAdvancedGraphics,
            enableProMotion: supportsProMotion && canHandleHighFrameRate,
            thermalThrottlingEnabled: thermalThrottlingRisk > 0.5
        )
    }
    
    /// Check if the device can handle a specific quality level
    func canHandle(qualityLevel: QualityLevel) -> Bool {
        switch qualityLevel {
        case .low:
            return true // All devices can handle low quality
        case .medium:
            return performanceTier != .low
        case .high:
            return performanceTier == .high || performanceTier == .flagship
        case .ultra:
            return performanceTier == .flagship && supportsAdvancedGraphics
        }
    }
    
    /// Get memory pressure level (0.0 = no pressure, 1.0 = high pressure)
    func getMemoryPressure() -> Float {
        let usedMemory = physicalMemory - availableMemory
        let memoryUsageRatio = Float(usedMemory) / Float(physicalMemory)
        
        return min(memoryUsageRatio, 1.0)
    }
    
    /// Get storage pressure level (0.0 = no pressure, 1.0 = high pressure)
    func getStoragePressure() -> Float {
        let usedStorage = diskSpace - availableDiskSpace
        let storageUsageRatio = Float(usedStorage) / Float(diskSpace)
        
        return min(storageUsageRatio, 1.0)
    }
}

// MARK: - Performance Settings

/// Recommended performance settings for a device
struct PerformanceSettings: Codable {
    let qualityLevel: QualityLevel
    let targetFrameRate: Int
    let particleCount: Int
    let shadowQuality: Float
    let textureQuality: Float
    let enableAdvancedEffects: Bool
    let enableProMotion: Bool
    let thermalThrottlingEnabled: Bool
    
    var description: String {
        return """
        Performance Settings:
        - Quality: \(qualityLevel.displayName)
        - Target FPS: \(targetFrameRate)
        - Particles: \(particleCount)
        - Shadows: \(String(format: "%.1f", shadowQuality))
        - Textures: \(String(format: "%.1f", textureQuality))
        - Advanced Effects: \(enableAdvancedEffects ? "Yes" : "No")
        - ProMotion: \(enableProMotion ? "Yes" : "No")
        - Thermal Throttling: \(thermalThrottlingEnabled ? "Yes" : "No")
        """
    }
}

// MARK: - UIDevice Extensions

extension UIDevice {
    /// Human-readable model name
    var modelName: String {
        return modelIdentifier.modelName
    }
    
    /// Device model identifier (e.g., "iPhone14,2")
    var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(bitPattern: value)))
        }
        return identifier
    }
    
    /// Whether the device supports TrueDepth camera
    var supportsTrueDepth: Bool {
        return hasFaceID // Simplified check
    }
    
    /// Whether the device supports wireless charging
    var supportsWirelessCharging: Bool {
        // Check for devices that support wireless charging
        let identifier = modelIdentifier
        return identifier.contains("iPhone") && (
            identifier.contains("iPhone10,") || // iPhone 8, 8 Plus, X
            identifier.contains("iPhone11,") || // iPhone XS, XS Max, XR
            identifier.contains("iPhone12,") || // iPhone 11 series
            identifier.contains("iPhone13,") || // iPhone 12 series
            identifier.contains("iPhone14,") || // iPhone 13 series
            identifier.contains("iPhone15,") || // iPhone 14 series
            identifier.contains("iPhone16,")    // iPhone 15 series
        )
    }
    
    /// Whether the device has Face ID
    var hasFaceID: Bool {
        let identifier = modelIdentifier
        return identifier.contains("iPhone") && (
            identifier.contains("iPhone10,3") || identifier.contains("iPhone10,6") || // iPhone X
            identifier.contains("iPhone11,") || // iPhone XS, XS Max, XR
            identifier.contains("iPhone12,") || // iPhone 11 series
            identifier.contains("iPhone13,") || // iPhone 12 series
            identifier.contains("iPhone14,") || // iPhone 13 series
            identifier.contains("iPhone15,") || // iPhone 14 series
            identifier.contains("iPhone16,")    // iPhone 15 series
        )
    }
    
    /// Whether the device has Touch ID
    var hasTouchID: Bool {
        let identifier = modelIdentifier
        return identifier.contains("iPhone") && (
            identifier.contains("iPhone6,") ||  // iPhone 5s
            identifier.contains("iPhone7,") ||  // iPhone 6, 6 Plus
            identifier.contains("iPhone8,") ||  // iPhone 6s, 6s Plus, SE
            identifier.contains("iPhone9,") ||  // iPhone 7, 7 Plus
            identifier.contains("iPhone10,1") || identifier.contains("iPhone10,4") || // iPhone 8
            identifier.contains("iPhone10,2") || identifier.contains("iPhone10,5")    // iPhone 8 Plus
        )
    }
}

// MARK: - Model Identifier Extensions

extension String {
    /// Convert device identifier to human-readable name
    var modelName: String {
        switch self {
        // iPhone models
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        
        // iPad models
        case "iPad13,1", "iPad13,2": return "iPad Air (4th generation)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 11-inch (3rd generation)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 12.9-inch (5th generation)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th generation)"
        
        // Simulator
        case "i386", "x86_64", "arm64":
            return "Simulator"
            
        default:
            return self
        }
    }
}

// MARK: - Helper Functions

private func getAvailableMemory() -> UInt64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    
    if kerr == KERN_SUCCESS {
        return info.resident_size
    } else {
        return 0
    }
}

private func getDiskSpaceInfo() -> (total: UInt64, available: UInt64) {
    do {
        let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        let totalSpace = (systemAttributes[.systemSize] as? NSNumber)?.uint64Value ?? 0
        let availableSpace = (systemAttributes[.systemFreeSize] as? NSNumber)?.uint64Value ?? 0
        return (totalSpace, availableSpace)
    } catch {
        return (0, 0)
    }
}

private func getMetalFeatureSet(_ device: MTLDevice?) -> String {
    guard let device = device else { return "None" }
    
    #if targetEnvironment(simulator)
    return "Simulator"
    #else
    if device.supportsFeatureSet(.iOS_GPUFamily5_v1) {
        return "iOS_GPUFamily5_v1"
    } else if device.supportsFeatureSet(.iOS_GPUFamily4_v1) {
        return "iOS_GPUFamily4_v1"
    } else if device.supportsFeatureSet(.iOS_GPUFamily3_v1) {
        return "iOS_GPUFamily3_v1"
    } else if device.supportsFeatureSet(.iOS_GPUFamily2_v1) {
        return "iOS_GPUFamily2_v1"
    } else if device.supportsFeatureSet(.iOS_GPUFamily1_v1) {
        return "iOS_GPUFamily1_v1"
    } else {
        return "Unknown"
    }
    #endif
}

private func getGPUFamily(_ device: MTLDevice?) -> String {
    guard let device = device else { return "None" }
    return device.name
}

private func getMaxTextureSize(_ device: MTLDevice?) -> Int {
    guard let device = device else { return 0 }
    
    #if targetEnvironment(simulator)
    return 4096
    #else
    if device.supportsFeatureSet(.iOS_GPUFamily5_v1) {
        return 16384
    } else if device.supportsFeatureSet(.iOS_GPUFamily4_v1) {
        return 16384
    } else if device.supportsFeatureSet(.iOS_GPUFamily3_v1) {
        return 16384
    } else if device.supportsFeatureSet(.iOS_GPUFamily2_v1) {
        return 8192
    } else {
        return 4096
    }
    #endif
}