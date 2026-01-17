//
//  DeviceInfoTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on Build Fixes Implementation
//

import XCTest
@testable import Tiny_Pilots

final class DeviceInfoTests: XCTestCase {
    
    var deviceInfo: DeviceInfo!
    
    override func setUp() {
        super.setUp()
        deviceInfo = DeviceInfo.current
    }
    
    override func tearDown() {
        deviceInfo = nil
        super.tearDown()
    }
    
    // MARK: - Basic Information Tests
    
    func testBasicDeviceInformation() {
        XCTAssertFalse(deviceInfo.modelName.isEmpty)
        XCTAssertFalse(deviceInfo.modelIdentifier.isEmpty)
        XCTAssertFalse(deviceInfo.systemVersion.isEmpty)
        XCTAssertFalse(deviceInfo.systemName.isEmpty)
        
        print("Device: \(deviceInfo.modelName) (\(deviceInfo.modelIdentifier))")
        print("System: \(deviceInfo.systemName) \(deviceInfo.systemVersion)")
    }
    
    func testDisplayInformation() {
        XCTAssertGreaterThan(deviceInfo.screenSize.width, 0)
        XCTAssertGreaterThan(deviceInfo.screenSize.height, 0)
        XCTAssertGreaterThan(deviceInfo.screenScale, 0)
        XCTAssertGreaterThan(deviceInfo.maximumFramesPerSecond, 0)
        
        print("Screen: \(deviceInfo.screenSize) @\(deviceInfo.screenScale)x")
        print("Max FPS: \(deviceInfo.maximumFramesPerSecond)")
    }
    
    func testHardwareCapabilities() {
        XCTAssertGreaterThan(deviceInfo.processorCount, 0)
        XCTAssertGreaterThan(deviceInfo.physicalMemory, 0)
        XCTAssertGreaterThanOrEqual(deviceInfo.availableMemory, 0)
        XCTAssertGreaterThan(deviceInfo.diskSpace, 0)
        XCTAssertGreaterThanOrEqual(deviceInfo.availableDiskSpace, 0)
        
        let memoryGB = Double(deviceInfo.physicalMemory) / (1024 * 1024 * 1024)
        let diskGB = Double(deviceInfo.diskSpace) / (1024 * 1024 * 1024)
        
        print("Processors: \(deviceInfo.processorCount)")
        print("Memory: \(String(format: "%.1f", memoryGB)) GB")
        print("Storage: \(String(format: "%.1f", diskGB)) GB")
    }
    
    func testGraphicsCapabilities() {
        XCTAssertFalse(deviceInfo.metalFeatureSet.isEmpty)
        XCTAssertFalse(deviceInfo.gpuFamily.isEmpty)
        XCTAssertGreaterThan(deviceInfo.maxTextureSize, 0)
        
        print("Metal Feature Set: \(deviceInfo.metalFeatureSet)")
        print("GPU: \(deviceInfo.gpuFamily)")
        print("Max Texture Size: \(deviceInfo.maxTextureSize)")
        print("Metal Performance Shaders: \(deviceInfo.supportsMetalPerformanceShaders)")
    }
    
    // MARK: - Performance Classification Tests
    
    func testPerformanceTier() {
        let tier = deviceInfo.performanceTier
        XCTAssertTrue(DevicePerformanceTier.allCases.contains(tier))
        
        print("Performance Tier: \(tier.rawValue)")
        
        // Test tier consistency
        switch tier {
        case .low:
            XCTAssertTrue(deviceInfo.isLowEndDevice)
            XCTAssertFalse(deviceInfo.isHighEndDevice)
        case .medium:
            XCTAssertFalse(deviceInfo.isLowEndDevice)
            XCTAssertFalse(deviceInfo.isHighEndDevice)
        case .high, .flagship:
            XCTAssertFalse(deviceInfo.isLowEndDevice)
            XCTAssertTrue(deviceInfo.isHighEndDevice)
        }
    }
    
    func testQualityLevelRecommendation() {
        let recommendedQuality = deviceInfo.recommendedQualityLevel
        XCTAssertTrue(QualityLevel.allCases.contains(recommendedQuality))
        
        print("Recommended Quality: \(recommendedQuality.displayName)")
        
        // Test that device can handle its recommended quality
        XCTAssertTrue(deviceInfo.canHandle(qualityLevel: recommendedQuality))
        
        // Test quality level properties
        XCTAssertGreaterThan(recommendedQuality.particleCount, 0)
        XCTAssertGreaterThan(recommendedQuality.targetFrameRate, 0)
        XCTAssertGreaterThan(recommendedQuality.shadowQuality, 0)
        XCTAssertGreaterThan(recommendedQuality.textureQuality, 0)
    }
    
    // MARK: - Quality Level Tests
    
    func testQualityLevelProperties() {
        for quality in QualityLevel.allCases {
            XCTAssertGreaterThan(quality.particleCount, 0)
            XCTAssertGreaterThan(quality.targetFrameRate, 0)
            XCTAssertGreaterThan(quality.shadowQuality, 0)
            XCTAssertGreaterThan(quality.textureQuality, 0)
            XCTAssertFalse(quality.displayName.isEmpty)
        }
        
        // Test quality progression
        XCTAssertLessThan(QualityLevel.low.particleCount, QualityLevel.high.particleCount)
        XCTAssertLessThanOrEqual(QualityLevel.low.targetFrameRate, QualityLevel.high.targetFrameRate)
    }
    
    func testCanHandleQualityLevels() {
        // All devices should handle low quality
        XCTAssertTrue(deviceInfo.canHandle(qualityLevel: .low))
        
        // Test quality level restrictions based on performance tier
        switch deviceInfo.performanceTier {
        case .low:
            XCTAssertTrue(deviceInfo.canHandle(qualityLevel: .low))
            XCTAssertFalse(deviceInfo.canHandle(qualityLevel: .medium))
            XCTAssertFalse(deviceInfo.canHandle(qualityLevel: .high))
            XCTAssertFalse(deviceInfo.canHandle(qualityLevel: .ultra))
            
        case .medium:
            XCTAssertTrue(deviceInfo.canHandle(qualityLevel: .low))
            XCTAssertTrue(deviceInfo.canHandle(qualityLevel: .medium))
            XCTAssertFalse(deviceInfo.canHandle(qualityLevel: .high))
            XCTAssertFalse(deviceInfo.canHandle(qualityLevel: .ultra))
            
        case .high:
            XCTAssertTrue(deviceInfo.canHandle(qualityLevel: .low))
            XCTAssertTrue(deviceInfo.canHandle(qualityLevel: .medium))
            XCTAssertTrue(deviceInfo.canHandle(qualityLevel: .high))
            
        case .flagship:
            XCTAssertTrue(deviceInfo.canHandle(qualityLevel: .low))
            XCTAssertTrue(deviceInfo.canHandle(qualityLevel: .medium))
            XCTAssertTrue(deviceInfo.canHandle(qualityLevel: .high))
            // Ultra depends on advanced graphics support
        }
    }
    
    // MARK: - Performance Features Tests
    
    func testPerformanceFeatures() {
        print("ProMotion Support: \(deviceInfo.supportsProMotion)")
        print("HDR Support: \(deviceInfo.supportsHDR)")
        print("Can Handle High Frame Rate: \(deviceInfo.canHandleHighFrameRate)")
        print("Should Use Reduced Particles: \(deviceInfo.shouldUseReducedParticles)")
        print("Supports Advanced Graphics: \(deviceInfo.supportsAdvancedGraphics)")
        
        // Test logical consistency
        if deviceInfo.supportsProMotion {
            XCTAssertGreaterThan(deviceInfo.maximumFramesPerSecond, 60)
        }
        
        if deviceInfo.isLowEndDevice {
            XCTAssertTrue(deviceInfo.shouldUseReducedParticles)
            XCTAssertFalse(deviceInfo.supportsAdvancedGraphics)
        }
    }
    
    func testThermalThrottlingRisk() {
        let risk = deviceInfo.thermalThrottlingRisk
        XCTAssertGreaterThanOrEqual(risk, 0.0)
        XCTAssertLessThanOrEqual(risk, 1.0)
        
        print("Thermal Throttling Risk: \(String(format: "%.2f", risk))")
        
        // Low-end devices should have higher thermal risk
        if deviceInfo.isLowEndDevice {
            XCTAssertGreaterThan(risk, 0.5)
        }
    }
    
    // MARK: - Recommended Settings Tests
    
    func testRecommendedSettings() {
        let settings = deviceInfo.getRecommendedSettings()
        
        XCTAssertTrue(QualityLevel.allCases.contains(settings.qualityLevel))
        XCTAssertGreaterThan(settings.targetFrameRate, 0)
        XCTAssertGreaterThan(settings.particleCount, 0)
        XCTAssertGreaterThan(settings.shadowQuality, 0)
        XCTAssertGreaterThan(settings.textureQuality, 0)
        
        print("Recommended Settings:")
        print(settings.description)
        
        // Test settings consistency
        if deviceInfo.isLowEndDevice {
            XCTAssertEqual(settings.qualityLevel, .low)
            XCTAssertFalse(settings.enableAdvancedEffects)
        }
        
        if deviceInfo.supportsProMotion && deviceInfo.canHandleHighFrameRate {
            XCTAssertTrue(settings.enableProMotion)
        }
        
        if deviceInfo.thermalThrottlingRisk > 0.5 {
            XCTAssertTrue(settings.thermalThrottlingEnabled)
        }
    }
    
    // MARK: - Memory and Storage Pressure Tests
    
    func testMemoryPressure() {
        let memoryPressure = deviceInfo.getMemoryPressure()
        XCTAssertGreaterThanOrEqual(memoryPressure, 0.0)
        XCTAssertLessThanOrEqual(memoryPressure, 1.0)
        
        print("Memory Pressure: \(String(format: "%.2f", memoryPressure))")
    }
    
    func testStoragePressure() {
        let storagePressure = deviceInfo.getStoragePressure()
        XCTAssertGreaterThanOrEqual(storagePressure, 0.0)
        XCTAssertLessThanOrEqual(storagePressure, 1.0)
        
        print("Storage Pressure: \(String(format: "%.2f", storagePressure))")
    }
    
    // MARK: - Device Feature Tests
    
    func testDeviceFeatures() {
        print("Face ID: \(deviceInfo.hasFaceID)")
        print("Touch ID: \(deviceInfo.hasTouchID)")
        print("TrueDepth: \(deviceInfo.supportsTrueDepth)")
        print("Wireless Charging: \(deviceInfo.supportsWirelessCharging)")
        
        // Test mutual exclusivity of Face ID and Touch ID for most devices
        // Note: Some devices might have neither, but typically not both
        if deviceInfo.hasFaceID && deviceInfo.hasTouchID {
            // This might be valid for some future devices, so we'll just log it
            print("Device has both Face ID and Touch ID")
        }
    }
    
    // MARK: - Model Name Tests
    
    func testModelNameMapping() {
        let identifier = deviceInfo.modelIdentifier
        let modelName = deviceInfo.modelName
        
        XCTAssertFalse(identifier.isEmpty)
        XCTAssertFalse(modelName.isEmpty)
        
        print("Model Identifier: \(identifier)")
        print("Model Name: \(modelName)")
        
        // Test that simulator is properly identified
        if identifier == "x86_64" || identifier == "arm64" || identifier == "i386" {
            XCTAssertEqual(modelName, "Simulator")
        }
    }
    
    // MARK: - Codable Tests
    
    func testCodableConformance() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(deviceInfo)
            XCTAssertGreaterThan(data.count, 0)
            
            let decodedDeviceInfo = try decoder.decode(DeviceInfo.self, from: data)
            
            XCTAssertEqual(decodedDeviceInfo.modelName, deviceInfo.modelName)
            XCTAssertEqual(decodedDeviceInfo.modelIdentifier, deviceInfo.modelIdentifier)
            XCTAssertEqual(decodedDeviceInfo.systemVersion, deviceInfo.systemVersion)
            XCTAssertEqual(decodedDeviceInfo.processorCount, deviceInfo.processorCount)
            XCTAssertEqual(decodedDeviceInfo.physicalMemory, deviceInfo.physicalMemory)
            
        } catch {
            XCTFail("DeviceInfo should be Codable: \(error)")
        }
    }
    
    func testPerformanceSettingsCodable() {
        let settings = deviceInfo.getRecommendedSettings()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(settings)
            XCTAssertGreaterThan(data.count, 0)
            
            let decodedSettings = try decoder.decode(PerformanceSettings.self, from: data)
            
            XCTAssertEqual(decodedSettings.qualityLevel, settings.qualityLevel)
            XCTAssertEqual(decodedSettings.targetFrameRate, settings.targetFrameRate)
            XCTAssertEqual(decodedSettings.particleCount, settings.particleCount)
            XCTAssertEqual(decodedSettings.enableAdvancedEffects, settings.enableAdvancedEffects)
            
        } catch {
            XCTFail("PerformanceSettings should be Codable: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testDeviceInfoPerformance() {
        measure {
            _ = DeviceInfo.current
        }
    }
    
    func testRecommendedSettingsPerformance() {
        measure {
            _ = deviceInfo.getRecommendedSettings()
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testZeroMemoryHandling() {
        // Test that the device info handles edge cases gracefully
        XCTAssertGreaterThan(deviceInfo.physicalMemory, 0)
        XCTAssertGreaterThanOrEqual(deviceInfo.availableMemory, 0)
        
        // Memory pressure should be valid even with edge cases
        let memoryPressure = deviceInfo.getMemoryPressure()
        XCTAssertFalse(memoryPressure.isNaN)
        XCTAssertFalse(memoryPressure.isInfinite)
    }
    
    func testStorageHandling() {
        XCTAssertGreaterThan(deviceInfo.diskSpace, 0)
        XCTAssertGreaterThanOrEqual(deviceInfo.availableDiskSpace, 0)
        
        // Storage pressure should be valid
        let storagePressure = deviceInfo.getStoragePressure()
        XCTAssertFalse(storagePressure.isNaN)
        XCTAssertFalse(storagePressure.isInfinite)
    }
}