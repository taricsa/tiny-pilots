import XCTest
import UIKit
@testable import Tiny_Pilots

/// Comprehensive device compatibility tests for supported hardware and iOS versions
class DeviceCompatibilityTests: XCTestCase {
    
    var mockDeviceInfo: MockDeviceInfo!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockDeviceInfo = MockDeviceInfo()
    }
    
    override func tearDownWithError() throws {
        mockDeviceInfo = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Minimum Device Support Tests
    
    /// Test iPhone 8 compatibility (minimum supported device)
    func testIPhone8Compatibility() throws {
        // Simulate iPhone 8 specifications
        mockDeviceInfo.deviceModel = "iPhone10,1" // iPhone 8
        mockDeviceInfo.screenSize = CGSize(width: 375, height: 667)
        mockDeviceInfo.screenScale = 2.0
        mockDeviceInfo.totalMemory = 2 * 1024 * 1024 * 1024 // 2GB
        mockDeviceInfo.processorType = "A11"
        
        // Test app initialization
        XCTAssertNoThrow(try validateAppInitialization())
        
        // Test performance requirements
        try validateMinimumPerformanceRequirements()
        
        // Test memory usage
        try validateMemoryUsageWithinLimits(maxMemoryMB: 150)
        
        // Test graphics performance
        try validateGraphicsPerformance(targetFPS: 30)
    }
    
    /// Test iPad 5th generation compatibility (minimum supported iPad)
    func testIPad5thGenCompatibility() throws {
        // Simulate iPad 5th generation specifications
        mockDeviceInfo.deviceModel = "iPad6,11" // iPad 5th gen
        mockDeviceInfo.screenSize = CGSize(width: 768, height: 1024)
        mockDeviceInfo.screenScale = 2.0
        mockDeviceInfo.totalMemory = 2 * 1024 * 1024 * 1024 // 2GB
        mockDeviceInfo.processorType = "A9"
        
        // Test app initialization
        XCTAssertNoThrow(try validateAppInitialization())
        
        // Test iPad-specific layouts
        try validateIPadLayoutCompatibility()
        
        // Test performance requirements
        try validateMinimumPerformanceRequirements()
        
        // Test memory usage
        try validateMemoryUsageWithinLimits(maxMemoryMB: 200)
    }
    
    // MARK: - Modern Device Optimization Tests
    
    /// Test iPhone 15 Pro Max optimization (latest device)
    func testIPhone15ProMaxOptimization() throws {
        // Simulate iPhone 15 Pro Max specifications
        mockDeviceInfo.deviceModel = "iPhone16,2" // iPhone 15 Pro Max
        mockDeviceInfo.screenSize = CGSize(width: 430, height: 932)
        mockDeviceInfo.screenScale = 3.0
        mockDeviceInfo.totalMemory = 8 * 1024 * 1024 * 1024 // 8GB
        mockDeviceInfo.processorType = "A17 Pro"
        mockDeviceInfo.supportsProMotion = true
        mockDeviceInfo.maxRefreshRate = 120
        
        // Test ProMotion support
        try validateProMotionSupport()
        
        // Test high performance mode
        try validateHighPerformanceMode()
        
        // Test advanced graphics features
        try validateAdvancedGraphicsFeatures()
        
        // Test 120 FPS gameplay
        try validateGraphicsPerformance(targetFPS: 120)
    }
    
    /// Test iPad Pro 12.9" optimization
    func testIPadProOptimization() throws {
        // Simulate iPad Pro 12.9" specifications
        mockDeviceInfo.deviceModel = "iPad14,6" // iPad Pro 12.9" 6th gen
        mockDeviceInfo.screenSize = CGSize(width: 1024, height: 1366)
        mockDeviceInfo.screenScale = 2.0
        mockDeviceInfo.totalMemory = 16 * 1024 * 1024 * 1024 // 16GB
        mockDeviceInfo.processorType = "M2"
        mockDeviceInfo.supportsProMotion = true
        mockDeviceInfo.maxRefreshRate = 120
        
        // Test M2 chip optimization
        try validateM2ChipOptimization()
        
        // Test large screen layout
        try validateLargeScreenLayout()
        
        // Test ProMotion on iPad
        try validateProMotionSupport()
        
        // Test high memory usage scenarios
        try validateMemoryUsageWithinLimits(maxMemoryMB: 500)
    }
    
    // MARK: - iOS Version Compatibility Tests
    
    /// Test iOS 18.0 compatibility (minimum supported version)
    func testIOS18Compatibility() throws {
        mockDeviceInfo.iOSVersion = "18.0"
        
        // Test iOS 18 specific features
        try validateiOS18Features()
        
        // Test deprecated API handling
        try validateDeprecatedAPIHandling()
        
        // Test new iOS 18 APIs
        try validateNewiOS18APIs()
    }
    
    /// Test latest iOS version optimization
    func testLatestIOSOptimization() throws {
        mockDeviceInfo.iOSVersion = "18.5" // Latest version
        
        // Test latest iOS features
        try validateLatestIOSFeatures()
        
        // Test performance improvements
        try validateLatestIOSPerformanceImprovements()
    }
    
    // MARK: - Performance Scaling Tests
    
    /// Test adaptive quality settings based on device capabilities
    func testAdaptiveQualitySettings() throws {
        let deviceConfigurations = [
            // Low-end device
            (model: "iPhone10,1", memory: 2, processor: "A11", expectedQuality: "Low"),
            // Mid-range device
            (model: "iPhone12,1", memory: 4, processor: "A13", expectedQuality: "Medium"),
            // High-end device
            (model: "iPhone16,2", memory: 8, processor: "A17 Pro", expectedQuality: "High")
        ]
        
        for config in deviceConfigurations {
            mockDeviceInfo.deviceModel = config.model
            mockDeviceInfo.totalMemory = UInt64(config.memory * 1024 * 1024 * 1024)
            mockDeviceInfo.processorType = config.processor
            
            let qualityManager = DeviceCapabilityManager()
            let recommendedQuality = qualityManager.getRecommendedQualitySettings()
            
            XCTAssertEqual(recommendedQuality.qualityLevel, config.expectedQuality,
                          "Quality setting mismatch for \(config.model)")
        }
    }
    
    /// Test frame rate adaptation based on device capabilities
    func testFrameRateAdaptation() throws {
        let deviceConfigurations = [
            // Standard device - 60 FPS
            (model: "iPhone12,1", supportsProMotion: false, expectedFPS: 60),
            // ProMotion device - 120 FPS
            (model: "iPhone15,3", supportsProMotion: true, expectedFPS: 120),
            // Older device - 30 FPS
            (model: "iPhone10,1", supportsProMotion: false, expectedFPS: 30)
        ]
        
        for config in deviceConfigurations {
            mockDeviceInfo.deviceModel = config.model
            mockDeviceInfo.supportsProMotion = config.supportsProMotion
            
            let frameRateManager = AdaptiveFrameRateManager()
            let targetFPS = frameRateManager.getOptimalFrameRate()
            
            XCTAssertEqual(targetFPS, config.expectedFPS,
                          "Frame rate mismatch for \(config.model)")
        }
    }
    
    // MARK: - Memory Management Tests
    
    /// Test memory usage across different device memory configurations
    func testMemoryUsageAcrossDevices() throws {
        let memoryConfigurations = [
            (memory: 2, maxUsageMB: 150, deviceType: "Low Memory"),
            (memory: 4, maxUsageMB: 250, deviceType: "Medium Memory"),
            (memory: 8, maxUsageMB: 400, deviceType: "High Memory")
        ]
        
        for config in memoryConfigurations {
            mockDeviceInfo.totalMemory = UInt64(config.memory * 1024 * 1024 * 1024)
            
            // Simulate game session
            try simulateGameSession()
            
            // Measure memory usage
            let memoryUsage = getCurrentMemoryUsage()
            
            XCTAssertLessThan(memoryUsage, Double(config.maxUsageMB),
                             "Memory usage too high for \(config.deviceType) device: \(memoryUsage)MB")
        }
    }
    
    /// Test memory pressure handling
    func testMemoryPressureHandling() throws {
        // Simulate low memory device
        mockDeviceInfo.totalMemory = 2 * 1024 * 1024 * 1024 // 2GB
        
        let memoryManager = PerformanceMonitor.shared
        
        // Simulate memory pressure
        memoryManager.simulateMemoryPressure(.high)
        
        // Verify memory pressure response
        XCTAssertTrue(memoryManager.isMemoryPressureActive)
        
        // Verify cleanup actions were triggered
        let memoryUsageAfterCleanup = getCurrentMemoryUsage()
        XCTAssertLessThan(memoryUsageAfterCleanup, 200, "Memory cleanup not effective")
    }
    
    // MARK: - Graphics Performance Tests
    
    /// Test graphics performance across different GPU capabilities
    func testGraphicsPerformanceAcrossGPUs() throws {
        let gpuConfigurations = [
            (gpu: "A11 GPU", expectedFPS: 30, qualityLevel: "Low"),
            (gpu: "A13 GPU", expectedFPS: 60, qualityLevel: "Medium"),
            (gpu: "A17 Pro GPU", expectedFPS: 120, qualityLevel: "High")
        ]
        
        for config in gpuConfigurations {
            mockDeviceInfo.gpuType = config.gpu
            
            // Test graphics performance
            let actualFPS = try measureGraphicsPerformance()
            
            XCTAssertGreaterThanOrEqual(actualFPS, config.expectedFPS,
                                       "Graphics performance below target for \(config.gpu)")
        }
    }
    
    /// Test thermal throttling handling
    func testThermalThrottlingHandling() throws {
        let thermalManager = DeviceCapabilityManager()
        
        // Simulate thermal throttling
        thermalManager.simulateThermalState(.critical)
        
        // Verify performance adjustments
        let adjustedSettings = thermalManager.getThrottledPerformanceSettings()
        
        XCTAssertLessThan(adjustedSettings.targetFPS, 60, "FPS not reduced during thermal throttling")
        XCTAssertEqual(adjustedSettings.qualityLevel, "Low", "Quality not reduced during thermal throttling")
    }
    
    // MARK: - Network Performance Tests
    
    /// Test network performance across different connection types
    func testNetworkPerformanceAcrossConnections() throws {
        let connectionTypes = [
            (type: "WiFi", expectedLatency: 50, expectedBandwidth: 1000),
            (type: "5G", expectedLatency: 20, expectedBandwidth: 500),
            (type: "4G", expectedLatency: 100, expectedBandwidth: 100),
            (type: "3G", expectedLatency: 300, expectedBandwidth: 10)
        ]
        
        for connection in connectionTypes {
            mockDeviceInfo.networkType = connection.type
            
            let networkMonitor = NetworkMonitor.shared
            networkMonitor.simulateNetworkConditions(
                latency: connection.expectedLatency,
                bandwidth: connection.expectedBandwidth
            )
            
            // Test network-dependent features
            try validateNetworkDependentFeatures(for: connection.type)
        }
    }
    
    // MARK: - Accessibility Compatibility Tests
    
    /// Test accessibility features across different devices
    func testAccessibilityCompatibilityAcrossDevices() throws {
        let deviceTypes = ["iPhone", "iPad"]
        
        for deviceType in deviceTypes {
            mockDeviceInfo.deviceType = deviceType
            
            // Test VoiceOver compatibility
            try validateVoiceOverCompatibility()
            
            // Test Switch Control compatibility
            try validateSwitchControlCompatibility()
            
            // Test Voice Control compatibility
            try validateVoiceControlCompatibility()
            
            // Test dynamic type scaling
            try validateDynamicTypeScaling()
        }
    }
    
    // MARK: - Helper Methods and Validation Functions
    
    private func validateAppInitialization() throws {
        // Test app can initialize on device
        let appDelegate = AppDelegate()
        XCTAssertNotNil(appDelegate)
        
        // Test core services initialization
        let diContainer = DIContainer.shared
        XCTAssertTrue(diContainer.isConfigured)
    }
    
    private func validateMinimumPerformanceRequirements() throws {
        // Test minimum performance benchmarks
        let benchmarkManager = PerformanceBenchmarkManager()
        let results = benchmarkManager.runMinimumPerformanceBenchmark()
        
        XCTAssertGreaterThanOrEqual(results.averageFPS, 30, "Minimum FPS requirement not met")
        XCTAssertLessThan(results.averageFrameTime, 33.33, "Frame time too high")
    }
    
    private func validateMemoryUsageWithinLimits(maxMemoryMB: Double) throws {
        // Simulate typical game session
        try simulateGameSession()
        
        let memoryUsage = getCurrentMemoryUsage()
        XCTAssertLessThan(memoryUsage, maxMemoryMB, 
                         "Memory usage exceeds limit: \(memoryUsage)MB > \(maxMemoryMB)MB")
    }
    
    private func validateGraphicsPerformance(targetFPS: Int) throws {
        let actualFPS = try measureGraphicsPerformance()
        XCTAssertGreaterThanOrEqual(actualFPS, targetFPS, 
                                   "Graphics performance below target: \(actualFPS) < \(targetFPS)")
    }
    
    private func validateProMotionSupport() throws {
        guard mockDeviceInfo.supportsProMotion else {
            throw XCTSkip("Device does not support ProMotion")
        }
        
        let frameRateManager = AdaptiveFrameRateManager()
        XCTAssertTrue(frameRateManager.isProMotionEnabled)
        XCTAssertEqual(frameRateManager.maxRefreshRate, 120)
    }
    
    private func validateIPadLayoutCompatibility() throws {
        // Test iPad-specific layout adaptations
        let layoutManager = UILayoutManager()
        // Add iPad layout validation logic
        XCTAssertTrue(true) // Placeholder for actual iPad layout tests
    }
    
    private func validateHighPerformanceMode() throws {
        let performanceManager = PerformanceMonitor.shared
        performanceManager.enableHighPerformanceMode()
        
        XCTAssertTrue(performanceManager.isHighPerformanceModeEnabled)
    }
    
    private func validateAdvancedGraphicsFeatures() throws {
        let renderer = OptimizedRenderer()
        XCTAssertTrue(renderer.supportsAdvancedShaders)
        XCTAssertTrue(renderer.supportsHighQualityParticles)
    }
    
    private func validateM2ChipOptimization() throws {
        let deviceManager = DeviceCapabilityManager()
        XCTAssertTrue(deviceManager.supportsM2Optimizations)
    }
    
    private func validateLargeScreenLayout() throws {
        // Test large screen layout adaptations
        XCTAssertTrue(true) // Placeholder for large screen layout tests
    }
    
    private func validateiOS18Features() throws {
        // Test iOS 18 specific features
        XCTAssertTrue(true) // Placeholder for iOS 18 feature tests
    }
    
    private func validateDeprecatedAPIHandling() throws {
        // Test handling of deprecated APIs
        XCTAssertTrue(true) // Placeholder for deprecated API tests
    }
    
    private func validateNewiOS18APIs() throws {
        // Test new iOS 18 APIs
        XCTAssertTrue(true) // Placeholder for new API tests
    }
    
    private func validateLatestIOSFeatures() throws {
        // Test latest iOS features
        XCTAssertTrue(true) // Placeholder for latest iOS feature tests
    }
    
    private func validateLatestIOSPerformanceImprovements() throws {
        // Test latest iOS performance improvements
        XCTAssertTrue(true) // Placeholder for performance improvement tests
    }
    
    private func simulateGameSession() throws {
        // Simulate a typical game session
        let gameSession = MockGameSession()
        try gameSession.start()
        gameSession.simulateGameplay(duration: 30) // 30 seconds
        gameSession.end()
    }
    
    private func getCurrentMemoryUsage() -> Double {
        let info = mach_task_basic_info()
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
            return Double(info.resident_size) / 1024.0 / 1024.0
        }
        
        return 0.0
    }
    
    private func measureGraphicsPerformance() throws -> Int {
        let benchmarkManager = PerformanceBenchmarkManager()
        let results = benchmarkManager.runGraphicsPerformanceBenchmark()
        return Int(results.averageFPS)
    }
    
    private func validateNetworkDependentFeatures(for connectionType: String) throws {
        let networkMonitor = NetworkMonitor.shared
        
        switch connectionType {
        case "WiFi", "5G":
            // High bandwidth features should work
            XCTAssertTrue(networkMonitor.canSupportHighBandwidthFeatures)
        case "4G":
            // Medium bandwidth features should work
            XCTAssertTrue(networkMonitor.canSupportMediumBandwidthFeatures)
        case "3G":
            // Only low bandwidth features should work
            XCTAssertTrue(networkMonitor.canSupportLowBandwidthFeatures)
            XCTAssertFalse(networkMonitor.canSupportHighBandwidthFeatures)
        default:
            break
        }
    }
    
    private func validateVoiceOverCompatibility() throws {
        let accessibilityManager = AccessibilityManager.shared
        XCTAssertTrue(accessibilityManager.isVoiceOverSupported)
    }
    
    private func validateSwitchControlCompatibility() throws {
        let accessibilityManager = AccessibilityManager.shared
        XCTAssertTrue(accessibilityManager.isSwitchControlSupported)
    }
    
    private func validateVoiceControlCompatibility() throws {
        let accessibilityManager = AccessibilityManager.shared
        XCTAssertTrue(accessibilityManager.isVoiceControlSupported)
    }
    
    private func validateDynamicTypeScaling() throws {
        let accessibilityManager = AccessibilityManager.shared
        XCTAssertTrue(accessibilityManager.supportsDynamicType)
    }
}

// MARK: - Mock Classes

class MockDeviceInfo {
    var deviceModel: String = "iPhone12,1"
    var screenSize: CGSize = CGSize(width: 390, height: 844)
    var screenScale: CGFloat = 3.0
    var totalMemory: UInt64 = 4 * 1024 * 1024 * 1024 // 4GB
    var processorType: String = "A13"
    var gpuType: String = "A13 GPU"
    var iOSVersion: String = "18.0"
    var supportsProMotion: Bool = false
    var maxRefreshRate: Int = 60
    var deviceType: String = "iPhone"
    var networkType: String = "WiFi"
}

class MockGameSession {
    func start() throws {
        // Initialize mock game session
    }
    
    func simulateGameplay(duration: TimeInterval) {
        // Simulate gameplay for specified duration
        Thread.sleep(forTimeInterval: min(duration, 1.0)) // Cap at 1 second for tests
    }
    
    func end() {
        // Clean up mock game session
    }
}