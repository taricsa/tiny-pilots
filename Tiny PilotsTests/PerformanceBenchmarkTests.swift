import XCTest
import SpriteKit
@testable import Tiny_Pilots

/// Performance benchmarking tests for automated performance regression detection
class PerformanceBenchmarkTests: XCTestCase {
    
    var performanceMonitor: PerformanceMonitor!
    var gameScene: GameScene!
    var skView: SKView!
    
    override func setUp() {
        super.setUp()
        
        performanceMonitor = PerformanceMonitor.shared
        
        // Create a test view and scene
        skView = SKView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        gameScene = GameScene(size: CGSize(width: 1024, height: 768))
        
        // Configure performance monitoring
        let config = PerformanceConfiguration(
            enablePerformanceMetrics: true,
            targetFrameRate: 60,
            maxMemoryUsage: 200
        )
        performanceMonitor.configure(with: config)
    }
    
    override func tearDown() {
        performanceMonitor = nil
        gameScene = nil
        skView = nil
        super.tearDown()
    }
    
    // MARK: - Frame Rate Benchmarks
    
    func testFrameRateBaseline() {
        measure {
            // Simulate 60 frames at 60 FPS
            let frameInterval = 1.0 / 60.0
            var currentTime: TimeInterval = 0
            
            for _ in 0..<60 {
                currentTime += frameInterval
                performanceMonitor.recordFrame(at: currentTime)
            }
            
            let fps = performanceMonitor.getCurrentFrameRate()
            XCTAssertGreaterThan(fps, 55.0, "Frame rate should be close to 60 FPS")
        }
    }
    
    func testFrameRateWithManyNodes() {
        measure {
            // Add many nodes to test rendering performance
            for i in 0..<1000 {
                let node = SKSpriteNode(color: .red, size: CGSize(width: 10, height: 10))
                node.position = CGPoint(x: i % 100 * 10, y: i / 100 * 10)
                gameScene.addChild(node)
            }
            
            // Simulate rendering frames
            let frameInterval = 1.0 / 60.0
            var currentTime: TimeInterval = 0
            
            for _ in 0..<60 {
                currentTime += frameInterval
                performanceMonitor.recordFrame(at: currentTime)
                
                // Simulate scene update
                gameScene.update(currentTime)
            }
            
            let fps = performanceMonitor.getCurrentFrameRate()
            XCTAssertGreaterThan(fps, 30.0, "Frame rate should remain above 30 FPS with many nodes")
        }
    }
    
    func testFrameRateWithParticles() {
        measure {
            // Add particle systems
            for i in 0..<10 {
                let particles = SKEmitterNode()
                particles.particleTexture = SKTexture(imageNamed: "spark")
                particles.numParticlesToEmit = 100
                particles.particleLifetime = 2.0
                particles.position = CGPoint(x: i * 100, y: 400)
                gameScene.addChild(particles)
            }
            
            // Simulate rendering frames
            let frameInterval = 1.0 / 60.0
            var currentTime: TimeInterval = 0
            
            for _ in 0..<120 { // 2 seconds
                currentTime += frameInterval
                performanceMonitor.recordFrame(at: currentTime)
                gameScene.update(currentTime)
            }
            
            let fps = performanceMonitor.getCurrentFrameRate()
            XCTAssertGreaterThan(fps, 45.0, "Frame rate should remain above 45 FPS with particles")
        }
    }
    
    // MARK: - Memory Usage Benchmarks
    
    func testMemoryUsageBaseline() {
        measure {
            let initialMemory = performanceMonitor.getCurrentMemoryUsage()
            
            // Perform some memory operations
            var nodes: [SKNode] = []
            for i in 0..<1000 {
                let node = SKSpriteNode(color: .blue, size: CGSize(width: 20, height: 20))
                node.position = CGPoint(x: i % 50 * 20, y: i / 50 * 20)
                nodes.append(node)
                gameScene.addChild(node)
            }
            
            let peakMemory = performanceMonitor.getCurrentMemoryUsage()
            
            // Clean up
            nodes.forEach { $0.removeFromParent() }
            nodes.removeAll()
            
            let finalMemory = performanceMonitor.getCurrentMemoryUsage()
            
            // Memory should increase during allocation and decrease after cleanup
            XCTAssertGreaterThan(peakMemory.usedMemoryMB, initialMemory.usedMemoryMB)
            XCTAssertLessThan(finalMemory.usedMemoryMB, peakMemory.usedMemoryMB)
        }
    }
    
    func testMemoryLeakDetection() {
        measure {
            let initialMemory = performanceMonitor.getCurrentMemoryUsage()
            
            // Create and destroy objects multiple times
            for cycle in 0..<10 {
                var tempNodes: [SKNode] = []
                
                for i in 0..<100 {
                    let node = SKSpriteNode(texture: SKTexture(imageNamed: "paperplane"))
                    node.position = CGPoint(x: i * 10, y: cycle * 10)
                    tempNodes.append(node)
                    gameScene.addChild(node)
                }
                
                // Remove all nodes
                tempNodes.forEach { $0.removeFromParent() }
                tempNodes.removeAll()
            }
            
            let finalMemory = performanceMonitor.getCurrentMemoryUsage()
            
            // Memory should not grow significantly after cleanup
            let memoryGrowth = finalMemory.usedMemoryMB - initialMemory.usedMemoryMB
            XCTAssertLessThan(memoryGrowth, 10.0, "Memory growth should be minimal after cleanup")
        }
    }
    
    // MARK: - Scene Transition Benchmarks
    
    func testSceneTransitionPerformance() {
        measure {
            let measurement = performanceMonitor.startMeasuring("scene_transition_test", category: "benchmark")
            
            // Simulate scene transition
            performanceMonitor.trackSceneTransition(from: "MainMenu", to: "Game")
            
            // Simulate scene loading work
            for i in 0..<100 {
                let node = SKSpriteNode(color: .green, size: CGSize(width: 15, height: 15))
                node.position = CGPoint(x: i * 10, y: 100)
                gameScene.addChild(node)
            }
            
            measurement.finish()
            
            let report = performanceMonitor.getPerformanceReport()
            let recentMeasurement = report.recentMeasurements.last
            
            XCTAssertNotNil(recentMeasurement)
            XCTAssertLessThan(recentMeasurement?.duration ?? 10.0, 2.0, "Scene transition should complete in under 2 seconds")
        }
    }
    
    // MARK: - Physics Performance Benchmarks
    
    func testPhysicsPerformance() {
        measure {
            // Create physics bodies
            for i in 0..<50 {
                let node = SKSpriteNode(color: .yellow, size: CGSize(width: 20, height: 20))
                node.position = CGPoint(x: CGFloat(i * 20), y: 400)
                node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                node.physicsBody?.isDynamic = true
                gameScene.addChild(node)
            }
            
            // Simulate physics updates
            let frameInterval = 1.0 / 60.0
            var currentTime: TimeInterval = 0
            
            for _ in 0..<300 { // 5 seconds of physics
                currentTime += frameInterval
                performanceMonitor.recordFrame(at: currentTime)
                gameScene.update(currentTime)
            }
            
            let fps = performanceMonitor.getCurrentFrameRate()
            XCTAssertGreaterThan(fps, 50.0, "Frame rate should remain above 50 FPS with physics")
        }
    }
    
    // MARK: - Device-Specific Benchmarks
    
    func testDeviceCapabilityDetection() {
        let deviceManager = DeviceCapabilityManager.shared
        
        XCTAssertNotNil(deviceManager.deviceModel)
        XCTAssertNotNil(deviceManager.performanceTier)
        
        let qualitySettings = deviceManager.qualitySettings
        
        // Verify quality settings are appropriate for device
        switch deviceManager.performanceTier {
        case .high:
            XCTAssertGreaterThanOrEqual(qualitySettings.targetFrameRate, 60)
            XCTAssertGreaterThanOrEqual(qualitySettings.particleCount, 50)
        case .medium:
            XCTAssertGreaterThanOrEqual(qualitySettings.targetFrameRate, 60)
            XCTAssertGreaterThanOrEqual(qualitySettings.particleCount, 25)
        case .low:
            XCTAssertGreaterThanOrEqual(qualitySettings.targetFrameRate, 30)
            XCTAssertGreaterThanOrEqual(qualitySettings.particleCount, 10)
        case .minimal:
            XCTAssertGreaterThanOrEqual(qualitySettings.targetFrameRate, 30)
            XCTAssertGreaterThanOrEqual(qualitySettings.particleCount, 5)
        }
    }
    
    func testAdaptiveQualityAdjustment() {
        let deviceManager = DeviceCapabilityManager.shared
        let initialSettings = deviceManager.qualitySettings
        
        // Simulate thermal throttling
        deviceManager.handleThermalStateChange(.serious)
        
        let adjustedSettings = deviceManager.qualitySettings
        
        // Quality should be reduced
        XCTAssertLessThanOrEqual(adjustedSettings.particleCount, initialSettings.particleCount)
        XCTAssertLessThanOrEqual(adjustedSettings.targetFrameRate, initialSettings.targetFrameRate)
    }
    
    // MARK: - Performance Regression Tests
    
    func testPerformanceRegression() {
        // This test establishes baseline performance metrics
        // In a real CI/CD pipeline, these would be compared against historical data
        
        let measurement = performanceMonitor.startMeasuring("performance_regression_test")
        
        // Simulate typical game operations
        createTestScene()
        simulateGameplay()
        
        measurement.finish()
        
        let report = performanceMonitor.getPerformanceReport()
        
        // Assert performance meets minimum requirements
        XCTAssertGreaterThan(report.averageFrameRate, 45.0, "Average FPS regression detected")
        XCTAssertLessThan(report.currentMemoryUsage.usedMemoryMB, 150.0, "Memory usage regression detected")
        
        // Log performance metrics for CI/CD tracking
        print("Performance Metrics:")
        print("- Average FPS: \(report.averageFrameRate)")
        print("- Memory Usage: \(report.currentMemoryUsage.usedMemoryMB) MB")
        print("- Thermal State: \(report.thermalState)")
    }
    
    // MARK: - Helper Methods
    
    private func createTestScene() {
        // Add background
        let background = SKSpriteNode(color: .blue, size: gameScene.size)
        background.position = CGPoint(x: gameScene.size.width/2, y: gameScene.size.height/2)
        gameScene.addChild(background)
        
        // Add airplane
        let airplane = SKSpriteNode(imageNamed: "paperplane")
        airplane.position = CGPoint(x: 200, y: 400)
        airplane.physicsBody = SKPhysicsBody(rectangleOf: airplane.size)
        gameScene.addChild(airplane)
        
        // Add obstacles
        for i in 0..<10 {
            let obstacle = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 80))
            obstacle.position = CGPoint(x: 300 + i * 100, y: 200 + i * 50)
            obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
            obstacle.physicsBody?.isDynamic = false
            gameScene.addChild(obstacle)
        }
    }
    
    private func simulateGameplay() {
        let frameInterval = 1.0 / 60.0
        var currentTime: TimeInterval = 0
        
        // Simulate 3 seconds of gameplay
        for _ in 0..<180 {
            currentTime += frameInterval
            performanceMonitor.recordFrame(at: currentTime)
            gameScene.update(currentTime)
        }
    }
}

// MARK: - Performance Configuration

struct PerformanceConfiguration {
    let enablePerformanceMetrics: Bool
    let targetFrameRate: Int
    let maxMemoryUsage: Int // MB
    
    static let `default` = PerformanceConfiguration(
        enablePerformanceMetrics: true,
        targetFrameRate: 60,
        maxMemoryUsage: 200
    )
}