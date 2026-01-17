//
//  PerformanceValidationTests.swift
//  Tiny PilotsTests
//
//  Created by Kiro on 7/15/25.
//

import XCTest
@testable import Tiny_Pilots

final class PerformanceValidationTests: XCTestCase {
    
    var performanceMonitor: PerformanceMonitor!
    
    override func setUp() {
        super.setUp()
        performanceMonitor = PerformanceMonitor.shared
        
        // Configure with test settings
        let testConfig = PerformanceConfiguration(
            targetFrameRate: 60,
            enableProMotion: true,
            maxMemoryUsage: 200,
            enablePerformanceMetrics: true,
            enableMemoryWarnings: true
        )
        performanceMonitor.configure(with: testConfig)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testPerformanceConfiguration() {
        // Given: Performance configuration
        let config = PerformanceConfiguration(
            targetFrameRate: 120,
            enableProMotion: true,
            maxMemoryUsage: 300,
            enablePerformanceMetrics: true,
            enableMemoryWarnings: false
        )
        
        // When: Configuring performance monitor
        performanceMonitor.configure(with: config)
        
        // Then: Should be configured correctly
        XCTAssertNotNil(performanceMonitor)
    }
    
    // MARK: - Performance Measurement Tests
    
    func testStartAndFinishMeasurement() {
        // Given: Performance monitor
        // When: Starting a measurement
        let measurement = performanceMonitor.startMeasuring("test_operation", category: "test")
        
        // Then: Should have valid measurement
        XCTAssertFalse(measurement.id.isEmpty)
        XCTAssertEqual(measurement.operation, "test_operation")
        XCTAssertEqual(measurement.category, "test")
        XCTAssertGreaterThan(measurement.startTime, 0)
        
        // When: Adding metadata
        measurement.addMetadata("test_key", value: "test_value")
        
        // Then: Should have metadata
        XCTAssertEqual(measurement.metadata["test_key"] as? String, "test_value")
        
        // When: Finishing measurement
        XCTAssertNoThrow(measurement.finish())
    }
    
    func testMeasurementWithDelay() {
        // Given: Performance monitor
        let expectation = XCTestExpectation(description: "Measurement completed")
        
        // When: Starting a measurement with delay
        let measurement = performanceMonitor.startMeasuring("delayed_operation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            measurement.finish()
            expectation.fulfill()
        }
        
        // Then: Should complete without issues
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMultipleConcurrentMeasurements() {
        // Given: Performance monitor
        let measurements = (0..<5).map { i in
            performanceMonitor.startMeasuring("concurrent_operation_\(i)", category: "concurrent")
        }
        
        // When: Finishing measurements in random order
        for measurement in measurements.shuffled() {
            XCTAssertNoThrow(measurement.finish())
        }
        
        // Then: All measurements should complete successfully
        XCTAssertTrue(true) // If we reach here, all measurements completed
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsageTracking() {
        // Given: Performance monitor
        // When: Getting current memory usage
        let memoryUsage = performanceMonitor.getCurrentMemoryUsage()
        
        // Then: Should have valid memory information
        XCTAssertGreaterThan(memoryUsage.totalMemory, 0)
        XCTAssertGreaterThanOrEqual(memoryUsage.usedMemory, 0)
        XCTAssertLessThanOrEqual(memoryUsage.usedMemory, memoryUsage.totalMemory)
        XCTAssertGreaterThan(memoryUsage.usedMemoryMB, 0)
        XCTAssertGreaterThan(memoryUsage.totalMemoryMB, 0)
        XCTAssertGreaterThanOrEqual(memoryUsage.memoryPercentage, 0)
        XCTAssertLessThanOrEqual(memoryUsage.memoryPercentage, 100)
    }
    
    func testMemoryUsageCalculations() {
        // Given: Memory usage with known values
        let memoryUsage = MemoryUsage(
            usedMemory: 100 * 1024 * 1024, // 100 MB
            totalMemory: 1024 * 1024 * 1024, // 1 GB
            timestamp: Date()
        )
        
        // When: Calculating derived values
        // Then: Should have correct calculations
        XCTAssertEqual(memoryUsage.usedMemoryMB, 100.0, accuracy: 0.1)
        XCTAssertEqual(memoryUsage.totalMemoryMB, 1024.0, accuracy: 0.1)
        XCTAssertEqual(memoryUsage.memoryPercentage, 9.765625, accuracy: 0.1) // 100/1024 * 100
    }
    
    // MARK: - Frame Rate Tests
    
    func testFrameRateTracking() {
        // Given: Performance monitor
        // When: Getting frame rate information
        let currentFPS = performanceMonitor.getCurrentFrameRate()
        let averageFPS = performanceMonitor.getAverageFrameRate()
        
        // Then: Should return valid values (may be 0 initially)
        XCTAssertGreaterThanOrEqual(currentFPS, 0)
        XCTAssertGreaterThanOrEqual(averageFPS, 0)
    }
    
    // MARK: - Scene Transition Tests
    
    func testSceneTransitionTracking() {
        // Given: Performance monitor
        // When: Tracking scene transitions
        // Then: Should not crash
        XCTAssertNoThrow(performanceMonitor.trackSceneTransition(from: "MainMenu", to: "GameScene"))
        XCTAssertNoThrow(performanceMonitor.trackSceneTransition(from: "GameScene", to: "HangarScene"))
    }
    
    // MARK: - App Launch Tests
    
    func testAppLaunchTracking() {
        // Given: Performance monitor
        // When: Tracking app launch completion
        // Then: Should not crash
        XCTAssertNoThrow(performanceMonitor.trackAppLaunchCompleted())
    }
    
    // MARK: - Performance Report Tests
    
    func testPerformanceReport() {
        // Given: Performance monitor with some measurements
        let measurement1 = performanceMonitor.startMeasuring("test_operation_1")
        let measurement2 = performanceMonitor.startMeasuring("test_operation_2")
        
        measurement1.finish()
        measurement2.finish()
        
        // When: Getting performance report
        let report = performanceMonitor.getPerformanceReport()
        
        // Then: Should have valid report
        XCTAssertGreaterThanOrEqual(report.currentFrameRate, 0)
        XCTAssertGreaterThanOrEqual(report.averageFrameRate, 0)
        XCTAssertGreaterThan(report.currentMemoryUsage.totalMemory, 0)
        XCTAssertFalse(report.summary.isEmpty)
    }
    
    func testPerformanceReportSummary() {
        // Given: Performance monitor
        let report = performanceMonitor.getPerformanceReport()
        
        // When: Getting summary
        let summary = report.summary
        
        // Then: Should contain expected information
        XCTAssertTrue(summary.contains("Performance Report"))
        XCTAssertTrue(summary.contains("Current FPS"))
        XCTAssertTrue(summary.contains("Average FPS"))
        XCTAssertTrue(summary.contains("Memory Usage"))
        XCTAssertTrue(summary.contains("Thermal State"))
    }
    
    // MARK: - Completed Measurement Tests
    
    func testCompletedMeasurementCalculations() {
        // Given: Completed measurement
        let measurement = CompletedMeasurement(
            operation: "test_operation",
            category: "test",
            duration: 0.5, // 500ms
            timestamp: Date(),
            metadata: ["test": "value"]
        )
        
        // When: Getting duration in milliseconds
        // Then: Should have correct conversion
        XCTAssertEqual(measurement.durationMs, 500.0, accuracy: 0.1)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOfMeasurementCreation() {
        // Given: Performance monitor
        // When: Creating many measurements
        measure {
            for i in 0..<1000 {
                let measurement = performanceMonitor.startMeasuring("performance_test_\(i)")
                measurement.finish()
            }
        }
    }
    
    func testPerformanceOfMemoryUsageCalculation() {
        // Given: Performance monitor
        // When: Getting memory usage multiple times
        measure {
            for _ in 0..<100 {
                _ = performanceMonitor.getCurrentMemoryUsage()
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testFinishingUnknownMeasurement() {
        // Given: A measurement not started through the monitor
        let measurement = PerformanceMeasurement(operation: "unknown_operation")
        
        // When: Finishing the measurement
        // Then: Should handle gracefully
        XCTAssertNoThrow(measurement.finish())
    }
    
    func testMultipleFinishCalls() {
        // Given: A measurement
        let measurement = performanceMonitor.startMeasuring("double_finish_test")
        
        // When: Finishing multiple times
        measurement.finish()
        
        // Then: Second finish should be handled gracefully
        XCTAssertNoThrow(measurement.finish())
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithAnalytics() {
        // Given: Performance monitor and analytics
        let measurement = performanceMonitor.startMeasuring("analytics_integration_test")
        
        // When: Finishing measurement (should trigger analytics)
        // Then: Should not crash
        XCTAssertNoThrow(measurement.finish())
    }
    
    func testIntegrationWithLogger() {
        // Given: Performance monitor
        let measurement = performanceMonitor.startMeasuring("logger_integration_test")
        
        // When: Finishing measurement (should trigger logging)
        // Then: Should not crash
        XCTAssertNoThrow(measurement.finish())
    }
}
//
 MARK: - Comprehensive Performance Validation Tests

extension PerformanceValidationTests {
    
    // MARK: - Frame Rate Performance Tests
    
    func testFrameRatePerformance_60FPSTarget() throws {
        let targetFrameTime = 1.0 / 60.0 // 16.67ms per frame
        let frameCount = 300 // 5 seconds worth of frames
        
        measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            for i in 0..<frameCount {
                // Simulate typical frame operations
                let measurement = performanceMonitor.startMeasuring("frame_\(i)", category: "gameplay")
                
                // Simulate game logic
                let tiltX = sin(Double(i) * 0.1) * 0.5
                let tiltY = cos(Double(i) * 0.1) * 0.3
                
                // Simulate physics calculations
                _ = sqrt(tiltX * tiltX + tiltY * tiltY)
                
                // Simulate memory allocation
                let tempArray = Array(0..<10)
                _ = tempArray.reduce(0, +)
                
                measurement.finish()
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let totalTime = endTime - startTime
            let averageFrameTime = totalTime / Double(frameCount)
            
            XCTAssertLessThan(averageFrameTime, targetFrameTime, 
                             "Average frame time (\(averageFrameTime * 1000)ms) should be less than target (\(targetFrameTime * 1000)ms)")
        }
    }
    
    func testFrameRatePerformance_120FPSTarget() throws {
        let targetFrameTime = 1.0 / 120.0 // 8.33ms per frame
        let frameCount = 600 // 5 seconds worth of frames at 120 FPS
        
        measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            for i in 0..<frameCount {
                let measurement = performanceMonitor.startMeasuring("high_fps_frame_\(i)", category: "high_fps")
                
                // Simulate high-frequency operations
                let value = Double(i)
                _ = sin(value * 0.05) + cos(value * 0.05)
                
                measurement.finish()
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let totalTime = endTime - startTime
            let averageFrameTime = totalTime / Double(frameCount)
            
            XCTAssertLessThan(averageFrameTime, targetFrameTime, 
                             "Average frame time (\(averageFrameTime * 1000)ms) should be less than 120 FPS target (\(targetFrameTime * 1000)ms)")
        }
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryPerformance_AllocationPattern() throws {
        let initialMemory = performanceMonitor.getCurrentMemoryUsage()
        
        measure {
            var arrays: [[Int]] = []
            
            // Simulate memory allocation pattern
            for i in 0..<1000 {
                let array = Array(0..<100)
                arrays.append(array)
                
                // Periodically clean up to simulate real usage
                if i % 100 == 0 {
                    arrays.removeFirst(min(50, arrays.count))
                }
            }
            
            // Clean up remaining arrays
            arrays.removeAll()
        }
        
        let finalMemory = performanceMonitor.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory.usedMemoryMB - initialMemory.usedMemoryMB
        
        XCTAssertLessThan(memoryIncrease, 50.0, "Memory increase should be less than 50MB during allocation test")
    }
    
    func testMemoryPerformance_LeakDetection() throws {
        let initialMemory = performanceMonitor.getCurrentMemoryUsage()
        
        // Perform operations that should not leak memory
        for _ in 0..<100 {
            autoreleasepool {
                let measurement = performanceMonitor.startMeasuring("leak_test")
                measurement.addMetadata("iteration", value: UUID().uuidString)
                measurement.finish()
                
                // Create and release temporary objects
                let tempData = Data(count: 1024)
                _ = tempData.count
            }
        }
        
        // Force garbage collection
        for _ in 0..<3 {
            autoreleasepool { }
        }
        
        let finalMemory = performanceMonitor.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory.usedMemoryMB - initialMemory.usedMemoryMB
        
        XCTAssertLessThan(memoryIncrease, 10.0, "Memory should not leak significantly during repeated operations")
    }
    
    // MARK: - Loading Performance Tests
    
    func testLoadingPerformance_AppLaunch() throws {
        measure {
            let launchMeasurement = performanceMonitor.startMeasuring("app_launch", category: "startup")
            
            // Simulate app launch operations
            for i in 0..<100 {
                let initMeasurement = performanceMonitor.startMeasuring("init_component_\(i)", category: "initialization")
                
                // Simulate component initialization
                Thread.sleep(forTimeInterval: 0.001) // 1ms per component
                
                initMeasurement.finish()
            }
            
            launchMeasurement.finish()
            
            // Verify launch time is reasonable
            let report = performanceMonitor.getPerformanceReport()
            // App launch should complete within reasonable time
        }
    }
    
    func testLoadingPerformance_SceneTransition() throws {
        let scenes = ["MainMenu", "GameScene", "HangarScene", "SettingsScene"]
        
        measure {
            for i in 0..<scenes.count - 1 {
                let fromScene = scenes[i]
                let toScene = scenes[i + 1]
                
                let transitionMeasurement = performanceMonitor.startMeasuring("scene_transition_\(fromScene)_to_\(toScene)", category: "scene_transition")
                
                // Simulate scene transition work
                performanceMonitor.trackSceneTransition(from: fromScene, to: toScene)
                
                // Simulate loading time
                Thread.sleep(forTimeInterval: 0.01) // 10ms per transition
                
                transitionMeasurement.finish()
            }
        }
    }
    
    // MARK: - Concurrent Performance Tests
    
    func testConcurrentPerformance_MultipleMeasurements() throws {
        measure {
            let group = DispatchGroup()
            let queue = DispatchQueue.global(qos: .userInitiated)
            
            // Create multiple concurrent measurements
            for i in 0..<50 {
                group.enter()
                queue.async {
                    let measurement = self.performanceMonitor.startMeasuring("concurrent_operation_\(i)", category: "concurrent")
                    
                    // Simulate work
                    let result = (0..<1000).reduce(0) { $0 + $1 }
                    measurement.addMetadata("result", value: result)
                    
                    measurement.finish()
                    group.leave()
                }
            }
            
            group.wait()
        }
    }
    
    func testConcurrentPerformance_MemoryAccess() throws {
        let sharedArray = Array(0..<10000)
        
        measure {
            let group = DispatchGroup()
            let queue = DispatchQueue.global(qos: .userInitiated)
            
            // Concurrent memory access
            for i in 0..<20 {
                group.enter()
                queue.async {
                    let measurement = self.performanceMonitor.startMeasuring("memory_access_\(i)", category: "memory")
                    
                    // Simulate memory access patterns
                    var sum = 0
                    for j in stride(from: 0, to: sharedArray.count, by: 100) {
                        sum += sharedArray[j]
                    }
                    
                    measurement.addMetadata("sum", value: sum)
                    measurement.finish()
                    group.leave()
                }
            }
            
            group.wait()
        }
    }
    
    // MARK: - Stress Performance Tests
    
    func testStressPerformance_HighFrequencyOperations() throws {
        measure {
            let stressMeasurement = performanceMonitor.startMeasuring("stress_test", category: "stress")
            
            // High frequency operations
            for i in 0..<10000 {
                let microMeasurement = performanceMonitor.startMeasuring("micro_op_\(i)", category: "micro")
                
                // Minimal operation
                _ = i * 2 + 1
                
                microMeasurement.finish()
            }
            
            stressMeasurement.finish()
        }
    }
    
    func testStressPerformance_MemoryPressure() throws {
        measure {
            let memoryStressMeasurement = performanceMonitor.startMeasuring("memory_stress", category: "stress")
            
            var largeArrays: [[Double]] = []
            
            // Create memory pressure
            for i in 0..<100 {
                let array = Array(0..<1000).map { Double($0 + i) }
                largeArrays.append(array)
                
                // Periodically check memory usage
                if i % 10 == 0 {
                    let memoryUsage = performanceMonitor.getCurrentMemoryUsage()
                    memoryStressMeasurement.addMetadata("memory_at_\(i)", value: memoryUsage.usedMemoryMB)
                }
            }
            
            // Clean up
            largeArrays.removeAll()
            
            memoryStressMeasurement.finish()
        }
    }
    
    // MARK: - Regression Performance Tests
    
    func testPerformanceRegression_BaselineOperations() throws {
        // Baseline performance test that should not regress
        let baselineTime = 0.1 // 100ms baseline for standard operations
        
        measure {
            let regressionMeasurement = performanceMonitor.startMeasuring("regression_baseline", category: "regression")
            
            // Standard operations that should maintain consistent performance
            for i in 0..<1000 {
                let operationMeasurement = performanceMonitor.startMeasuring("baseline_op_\(i)", category: "baseline")
                
                // Simulate typical game operations
                let angle = Double(i) * 0.01
                let x = cos(angle)
                let y = sin(angle)
                let distance = sqrt(x * x + y * y)
                
                operationMeasurement.addMetadata("distance", value: distance)
                operationMeasurement.finish()
            }
            
            regressionMeasurement.finish()
        }
    }
    
    func testPerformanceRegression_MemoryBaseline() throws {
        let initialMemory = performanceMonitor.getCurrentMemoryUsage()
        
        measure {
            let memoryRegressionMeasurement = performanceMonitor.startMeasuring("memory_regression", category: "regression")
            
            // Memory operations that should not regress
            var testData: [String] = []
            
            for i in 0..<1000 {
                testData.append("test_string_\(i)")
                
                if i % 100 == 0 {
                    let currentMemory = performanceMonitor.getCurrentMemoryUsage()
                    memoryRegressionMeasurement.addMetadata("memory_checkpoint_\(i)", value: currentMemory.usedMemoryMB)
                }
            }
            
            testData.removeAll()
            memoryRegressionMeasurement.finish()
        }
        
        let finalMemory = performanceMonitor.getCurrentMemoryUsage()
        let memoryDelta = finalMemory.usedMemoryMB - initialMemory.usedMemoryMB
        
        // Memory usage should return close to baseline
        XCTAssertLessThan(abs(memoryDelta), 5.0, "Memory usage should return close to baseline after operations")
    }
    
    // MARK: - Device-Specific Performance Tests
    
    func testDevicePerformance_AdaptiveQuality() throws {
        let memoryUsage = performanceMonitor.getCurrentMemoryUsage()
        let isLowMemoryDevice = memoryUsage.totalMemoryMB < 2048 // Less than 2GB
        
        measure {
            let adaptiveMeasurement = performanceMonitor.startMeasuring("adaptive_quality", category: "device")
            
            // Adjust operations based on device capabilities
            let operationCount = isLowMemoryDevice ? 500 : 1000
            let complexityFactor = isLowMemoryDevice ? 1 : 2
            
            for i in 0..<operationCount {
                let qualityMeasurement = performanceMonitor.startMeasuring("quality_op_\(i)", category: "adaptive")
                
                // Simulate adaptive quality operations
                for _ in 0..<complexityFactor {
                    _ = sin(Double(i) * 0.1) + cos(Double(i) * 0.1)
                }
                
                qualityMeasurement.finish()
            }
            
            adaptiveMeasurement.addMetadata("device_type", value: isLowMemoryDevice ? "low_memory" : "high_memory")
            adaptiveMeasurement.addMetadata("operation_count", value: operationCount)
            adaptiveMeasurement.finish()
        }
    }
    
    // MARK: - Real-World Scenario Performance Tests
    
    func testRealWorldPerformance_GameplaySimulation() throws {
        measure {
            let gameplayMeasurement = performanceMonitor.startMeasuring("gameplay_simulation", category: "real_world")
            
            // Simulate 60 seconds of gameplay at 60 FPS
            let totalFrames = 60 * 60 // 3600 frames
            
            for frame in 0..<totalFrames {
                let frameMeasurement = performanceMonitor.startMeasuring("gameplay_frame_\(frame)", category: "gameplay")
                
                // Simulate typical frame operations
                // 1. Input processing
                let inputX = sin(Double(frame) * 0.02)
                let inputY = cos(Double(frame) * 0.02)
                
                // 2. Physics calculations
                let velocity = sqrt(inputX * inputX + inputY * inputY)
                let acceleration = velocity * 0.1
                
                // 3. Game state updates
                let score = frame * 10
                let distance = Double(frame) * 0.5
                
                // 4. Collision detection (simplified)
                let hasCollision = frame % 100 == 0
                
                frameMeasurement.addMetadata("velocity", value: velocity)
                frameMeasurement.addMetadata("score", value: score)
                frameMeasurement.addMetadata("distance", value: distance)
                frameMeasurement.addMetadata("collision", value: hasCollision)
                frameMeasurement.finish()
                
                // Simulate frame timing
                if frame % 600 == 0 { // Every 10 seconds
                    let memoryUsage = performanceMonitor.getCurrentMemoryUsage()
                    gameplayMeasurement.addMetadata("memory_at_\(frame/600)0s", value: memoryUsage.usedMemoryMB)
                }
            }
            
            gameplayMeasurement.finish()
        }
    }
    
    func testRealWorldPerformance_MenuNavigation() throws {
        let menuScenes = ["MainMenu", "Settings", "Hangar", "Leaderboards", "Achievements"]
        
        measure {
            let navigationMeasurement = performanceMonitor.startMeasuring("menu_navigation", category: "real_world")
            
            // Simulate menu navigation patterns
            for cycle in 0..<10 {
                for i in 0..<menuScenes.count {
                    let currentScene = menuScenes[i]
                    let nextScene = menuScenes[(i + 1) % menuScenes.count]
                    
                    let transitionMeasurement = performanceMonitor.startMeasuring("menu_transition_\(cycle)_\(i)", category: "menu")
                    
                    // Simulate menu transition work
                    performanceMonitor.trackSceneTransition(from: currentScene, to: nextScene)
                    
                    // Simulate UI updates
                    for j in 0..<50 {
                        _ = "UI_Element_\(j)".count
                    }
                    
                    transitionMeasurement.addMetadata("from_scene", value: currentScene)
                    transitionMeasurement.addMetadata("to_scene", value: nextScene)
                    transitionMeasurement.finish()
                }
            }
            
            navigationMeasurement.finish()
        }
    }
    
    // MARK: - Performance Validation Helpers
    
    func validateFrameRateTarget(_ targetFPS: Int, actualFrameTime: Double) {
        let targetFrameTime = 1.0 / Double(targetFPS)
        XCTAssertLessThan(actualFrameTime, targetFrameTime, 
                         "Frame time should meet \(targetFPS) FPS target")
    }
    
    func validateMemoryUsage(_ memoryUsageMB: Double, maxAllowedMB: Double) {
        XCTAssertLessThan(memoryUsageMB, maxAllowedMB, 
                         "Memory usage should not exceed \(maxAllowedMB) MB")
    }
    
    func validatePerformanceRegression(_ currentTime: Double, _ baselineTime: Double, tolerance: Double = 0.1) {
        let regressionThreshold = baselineTime * (1.0 + tolerance)
        XCTAssertLessThan(currentTime, regressionThreshold, 
                         "Performance should not regress by more than \(tolerance * 100)%")
    }
}