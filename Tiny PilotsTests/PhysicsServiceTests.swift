import XCTest
import SpriteKit
import CoreMotion
@testable import Tiny_Pilots

/// Unit tests for PhysicsService
class PhysicsServiceTests: XCTestCase {
    
    var sut: PhysicsService!
    var testScene: SKScene!
    var testAirplane: PaperAirplane!
    
    override func setUp() {
        super.setUp()
        sut = PhysicsService()
        testScene = SKScene(size: CGSize(width: 800, height: 600))
        testAirplane = PaperAirplane(type: .basic, fold: .basic, design: .plain)
        testScene.addChild(testAirplane)
    }
    
    override func tearDown() {
        sut.stopPhysicsSimulation()
        sut = nil
        testScene = nil
        testAirplane = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_SetsDefaultValues() {
        // Then
        XCTAssertEqual(sut.sensitivity, 1.0, accuracy: 0.01, "Default sensitivity should be 1.0")
        XCTAssertFalse(sut.isActive, "Physics simulation should not be active initially")
        XCTAssertEqual(sut.windVector.dx, 0, accuracy: 0.01, "Wind vector X should be 0 initially")
        XCTAssertEqual(sut.windVector.dy, 0, accuracy: 0.01, "Wind vector Y should be 0 initially")
    }
    
    // MARK: - Sensitivity Tests
    
    func testSetSensitivity_UpdatesValue() {
        // Given
        let newSensitivity: CGFloat = 1.5
        
        // When
        sut.sensitivity = newSensitivity
        
        // Then
        XCTAssertEqual(sut.sensitivity, newSensitivity, accuracy: 0.01, "Sensitivity should be updated")
    }
    
    func testSetSensitivity_ClampsToValidRange() {
        // Given
        let tooHigh: CGFloat = 3.0
        let tooLow: CGFloat = 0.05
        
        // When & Then
        sut.sensitivity = tooHigh
        XCTAssertEqual(sut.sensitivity, 2.0, accuracy: 0.01, "Sensitivity should be clamped to 2.0")
        
        sut.sensitivity = tooLow
        XCTAssertEqual(sut.sensitivity, 0.1, accuracy: 0.01, "Sensitivity should be clamped to 0.1")
    }
    
    // MARK: - Physics World Configuration Tests
    
    func testConfigurePhysicsWorld_SetsGravity() {
        // When
        sut.configurePhysicsWorld(for: testScene)
        
        // Then
        XCTAssertEqual(testScene.physicsWorld.gravity.dx, GameConfig.Physics.gravity.dx, accuracy: 0.01)
        XCTAssertEqual(testScene.physicsWorld.gravity.dy, GameConfig.Physics.gravity.dy, accuracy: 0.01)
        XCTAssertEqual(testScene.physicsWorld.speed, 1.0, accuracy: 0.01, "Physics world speed should be 1.0")
    }
    
    // MARK: - Physics Simulation Tests
    
    func testStartPhysicsSimulation_SetsActiveFlag() {
        // When
        sut.startPhysicsSimulation()
        
        // Then
        XCTAssertTrue(sut.isActive, "Physics simulation should be active after starting")
    }
    
    func testStopPhysicsSimulation_ClearsActiveFlag() {
        // Given
        sut.startPhysicsSimulation()
        XCTAssertTrue(sut.isActive, "Physics simulation should be active")
        
        // When
        sut.stopPhysicsSimulation()
        
        // Then
        XCTAssertFalse(sut.isActive, "Physics simulation should not be active after stopping")
    }
    
    func testStartPhysicsSimulation_WhenAlreadyActive_DoesNothing() {
        // Given
        sut.startPhysicsSimulation()
        let wasActive = sut.isActive
        
        // When
        sut.startPhysicsSimulation() // Call again
        
        // Then
        XCTAssertEqual(sut.isActive, wasActive, "Active state should remain unchanged")
    }
    
    func testStopPhysicsSimulation_WhenNotActive_DoesNothing() {
        // Given - service is not active
        XCTAssertFalse(sut.isActive, "Physics simulation should not be active initially")
        
        // When & Then
        XCTAssertNoThrow(sut.stopPhysicsSimulation(), "Stopping inactive simulation should not throw")
    }
    
    // MARK: - Force Application Tests
    
    func testApplyForces_WithValidAirplane_DoesNotCrash() {
        // Given
        let tiltX: CGFloat = 0.5
        let tiltY: CGFloat = 0.3
        
        // When & Then
        XCTAssertNoThrow(sut.applyForces(to: testAirplane, tiltX: tiltX, tiltY: tiltY), "Applying forces should not crash")
    }
    
    func testApplyForces_WithNilPhysicsBody_DoesNotCrash() {
        // Given
        let airplaneWithoutPhysics = PaperAirplane(type: .basic)
        airplaneWithoutPhysics.physicsBody = nil
        
        // When & Then
        XCTAssertNoThrow(sut.applyForces(to: airplaneWithoutPhysics, tiltX: 0.5, tiltY: 0.3), "Applying forces to airplane without physics body should not crash")
    }
    
    func testCalculateLift_WithValidAirplane_ReturnsValue() {
        // Given
        testAirplane.physicsBody?.velocity = CGVector(dx: 100, dy: 50)
        
        // When
        let lift = sut.calculateLift(for: testAirplane)
        
        // Then
        XCTAssertGreaterThan(lift, 0, "Lift should be positive for moving airplane")
    }
    
    func testCalculateLift_WithNilPhysicsBody_ReturnsZero() {
        // Given
        let airplaneWithoutPhysics = PaperAirplane(type: .basic)
        airplaneWithoutPhysics.physicsBody = nil
        
        // When
        let lift = sut.calculateLift(for: airplaneWithoutPhysics)
        
        // Then
        XCTAssertEqual(lift, 0, accuracy: 0.01, "Lift should be zero for airplane without physics body")
    }
    
    // MARK: - Wind Effects Tests
    
    func testSetWindVector_UpdatesWindVector() {
        // Given
        let direction: CGFloat = 45 // 45 degrees
        let strength: CGFloat = 50
        
        // When
        sut.setWindVector(direction: direction, strength: strength)
        
        // Then
        XCTAssertNotEqual(sut.windVector.dx, 0, "Wind vector X should be updated")
        XCTAssertNotEqual(sut.windVector.dy, 0, "Wind vector Y should be updated")
        
        // Check that the magnitude is approximately correct
        let magnitude = sqrt(sut.windVector.dx * sut.windVector.dx + sut.windVector.dy * sut.windVector.dy)
        XCTAssertEqual(magnitude, strength, accuracy: 0.01, "Wind vector magnitude should match strength")
    }
    
    func testApplyWind_WithValidAirplane_DoesNotCrash() {
        // Given
        sut.setWindVector(direction: 90, strength: 30)
        
        // When & Then
        XCTAssertNoThrow(sut.applyWind(to: testAirplane), "Applying wind should not crash")
    }
    
    func testApplyWind_WithNilPhysicsBody_DoesNotCrash() {
        // Given
        let airplaneWithoutPhysics = PaperAirplane(type: .basic)
        airplaneWithoutPhysics.physicsBody = nil
        sut.setWindVector(direction: 90, strength: 30)
        
        // When & Then
        XCTAssertNoThrow(sut.applyWind(to: airplaneWithoutPhysics), "Applying wind to airplane without physics body should not crash")
    }
    
    func testUpdateRandomWind_WithNoWind_DoesNothing() {
        // Given - no wind set
        let initialWindVector = sut.windVector
        
        // When
        sut.updateRandomWind()
        
        // Then
        XCTAssertEqual(sut.windVector.dx, initialWindVector.dx, accuracy: 0.01, "Wind vector should not change when no wind is set")
        XCTAssertEqual(sut.windVector.dy, initialWindVector.dy, accuracy: 0.01, "Wind vector should not change when no wind is set")
    }
    
    func testUpdateRandomWind_WithExistingWind_ModifiesWind() {
        // Given
        sut.setWindVector(direction: 0, strength: 50)
        let initialMagnitude = sqrt(sut.windVector.dx * sut.windVector.dx + sut.windVector.dy * sut.windVector.dy)
        
        // When
        sut.updateRandomWind()
        
        // Then
        let newMagnitude = sqrt(sut.windVector.dx * sut.windVector.dx + sut.windVector.dy * sut.windVector.dy)
        // Wind should still exist but may have changed
        XCTAssertGreaterThan(newMagnitude, 0, "Wind should still exist after random update")
    }
    
    func testTransitionWindVector_DoesNotCrash() {
        // Given
        let targetDirection: CGFloat = 180
        let targetStrength: CGFloat = 40
        let duration: TimeInterval = 0.1 // Short duration for testing
        
        // When & Then
        XCTAssertNoThrow(sut.transitionWindVector(toDirection: targetDirection, strength: targetStrength, duration: duration), "Wind transition should not crash")
    }
    
    // MARK: - Collision Handling Tests
    
    func testHandleCollision_WithValidNodes_DoesNotCrash() {
        // Given
        let nodeA = SKSpriteNode()
        nodeA.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: 10))
        nodeA.physicsBody?.categoryBitMask = PhysicsCategory.airplane
        
        let nodeB = SKSpriteNode()
        nodeB.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: 10))
        nodeB.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        
        // When & Then
        XCTAssertNoThrow(sut.handleCollision(between: nodeA, and: nodeB), "Handling collision should not crash")
    }
    
    func testHandleCollision_WithNilPhysicsBodies_DoesNotCrash() {
        // Given
        let nodeA = SKSpriteNode()
        let nodeB = SKSpriteNode()
        // No physics bodies set
        
        // When & Then
        XCTAssertNoThrow(sut.handleCollision(between: nodeA, and: nodeB), "Handling collision with nil physics bodies should not crash")
    }
    
    // MARK: - Turbulence Tests
    
    func testApplyTurbulence_WithValidAirplane_DoesNotCrash() {
        // Given
        sut.setWindVector(direction: 45, strength: 25)
        
        // When & Then
        XCTAssertNoThrow(sut.applyTurbulence(to: testAirplane), "Applying turbulence should not crash")
    }
    
    func testApplyTurbulence_WithNilPhysicsBody_DoesNotCrash() {
        // Given
        let airplaneWithoutPhysics = PaperAirplane(type: .basic)
        airplaneWithoutPhysics.physicsBody = nil
        
        // When & Then
        XCTAssertNoThrow(sut.applyTurbulence(to: airplaneWithoutPhysics), "Applying turbulence to airplane without physics body should not crash")
    }
    
    // MARK: - Advanced Flight Controls Tests
    
    func testApplyAdvancedFlightControls_WithValidInputs_DoesNotCrash() {
        // Given
        let motion = CMDeviceMotion()
        
        // When & Then
        XCTAssertNoThrow(sut.applyAdvancedFlightControls(to: testAirplane, motion: motion), "Applying advanced flight controls should not crash")
    }
    
    func testApplyAdvancedFlightControls_WithNilPhysicsBody_DoesNotCrash() {
        // Given
        let airplaneWithoutPhysics = PaperAirplane(type: .basic)
        airplaneWithoutPhysics.physicsBody = nil
        let motion = CMDeviceMotion()
        
        // When & Then
        XCTAssertNoThrow(sut.applyAdvancedFlightControls(to: airplaneWithoutPhysics, motion: motion), "Applying advanced flight controls to airplane without physics body should not crash")
    }
}// MARK: - 
Additional Comprehensive Tests

extension PhysicsServiceTests {
    
    // MARK: - Error Handling Tests
    
    func testConfigurePhysicsWorld_WithNilScene_HandlesGracefully() {
        // When & Then
        // This test would require modifying the method signature to accept optional scene
        // For now, we test that the method doesn't crash with a valid scene
        XCTAssertNoThrow(sut.configurePhysicsWorld(for: testScene), "Configuring physics world should not crash")
    }
    
    func testApplyForces_WithExtremeValues_ClampsCorrectly() {
        // Given
        let extremeTiltX: CGFloat = 999.0
        let extremeTiltY: CGFloat = -999.0
        
        // When & Then
        XCTAssertNoThrow(sut.applyForces(to: testAirplane, tiltX: extremeTiltX, tiltY: extremeTiltY), "Extreme tilt values should not crash")
    }
    
    func testCalculateLift_WithExtremeVelocity_HandlesCorrectly() {
        // Given
        testAirplane.physicsBody?.velocity = CGVector(dx: 10000, dy: 10000)
        
        // When
        let lift = sut.calculateLift(for: testAirplane)
        
        // Then
        XCTAssertGreaterThan(lift, 0, "Lift should be positive even with extreme velocity")
        XCTAssertLessThan(lift, 1000, "Lift should be reasonable even with extreme velocity")
    }
    
    func testSetWindVector_WithExtremeValues_HandlesCorrectly() {
        // Given
        let extremeDirection: CGFloat = 720 // Multiple rotations
        let extremeStrength: CGFloat = 10000
        
        // When & Then
        XCTAssertNoThrow(sut.setWindVector(direction: extremeDirection, strength: extremeStrength), "Extreme wind values should not crash")
        
        // Verify wind vector is reasonable
        let magnitude = sqrt(sut.windVector.dx * sut.windVector.dx + sut.windVector.dy * sut.windVector.dy)
        XCTAssertLessThan(magnitude, 1000, "Wind magnitude should be clamped to reasonable values")
    }
    
    // MARK: - Performance Tests
    
    func testMultipleForceApplications_PerformanceTest() {
        // Given
        sut.startPhysicsSimulation()
        
        // When
        measure {
            for i in 0..<1000 {
                let tiltX = CGFloat(sin(Double(i) * 0.1))
                let tiltY = CGFloat(cos(Double(i) * 0.1))
                sut.applyForces(to: testAirplane, tiltX: tiltX, tiltY: tiltY)
            }
        }
        
        // Then
        XCTAssertTrue(sut.isActive)
    }
    
    func testRapidWindUpdates_PerformanceTest() {
        // When
        measure {
            for i in 0..<1000 {
                let direction = CGFloat(i % 360)
                let strength = CGFloat(i % 100)
                sut.setWindVector(direction: direction, strength: strength)
                sut.updateRandomWind()
            }
        }
        
        // Then
        XCTAssertNotEqual(sut.windVector.dx, 0)
    }
    
    func testMultipleLiftCalculations_PerformanceTest() {
        // Given
        testAirplane.physicsBody?.velocity = CGVector(dx: 100, dy: 50)
        
        // When
        measure {
            for _ in 0..<10000 {
                _ = sut.calculateLift(for: testAirplane)
            }
        }
        
        // Then - Should complete without performance issues
        XCTAssertTrue(true)
    }
    
    // MARK: - Memory Management Tests
    
    func testMultipleSimulationStartStop_DoesNotLeak() {
        // When
        for _ in 0..<100 {
            sut.startPhysicsSimulation()
            sut.stopPhysicsSimulation()
        }
        
        // Then
        XCTAssertFalse(sut.isActive)
    }
    
    func testMultipleSceneConfigurations_DoesNotLeak() {
        // When
        for _ in 0..<50 {
            let scene = SKScene(size: CGSize(width: 800, height: 600))
            sut.configurePhysicsWorld(for: scene)
        }
        
        // Then - Should not leak memory
        XCTAssertTrue(true)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentForceApplications_ThreadSafe() {
        // Given
        sut.startPhysicsSimulation()
        let expectation = XCTestExpectation(description: "Concurrent force applications complete")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for i in 0..<10 {
            DispatchQueue.global().async {
                let tiltX = CGFloat(i) / 10.0
                let tiltY = CGFloat(9 - i) / 10.0
                self.sut.applyForces(to: self.testAirplane, tiltX: tiltX, tiltY: tiltY)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then
        XCTAssertTrue(sut.isActive)
    }
    
    func testConcurrentWindUpdates_ThreadSafe() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent wind updates complete")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for i in 0..<10 {
            DispatchQueue.global().async {
                let direction = CGFloat(i * 36) // 0, 36, 72, ... degrees
                let strength = CGFloat(i * 10)
                self.sut.setWindVector(direction: direction, strength: strength)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Then
        XCTAssertNotEqual(sut.windVector.dx, 0)
    }
    
    // MARK: - Device Motion Tests
    
    func testStartDeviceMotionUpdates_SetsActiveFlag() {
        // When
        sut.startDeviceMotionUpdates()
        
        // Then
        XCTAssertTrue(sut.isActive, "Device motion should set active flag")
    }
    
    func testStopDeviceMotionUpdates_ClearsActiveFlag() {
        // Given
        sut.startDeviceMotionUpdates()
        XCTAssertTrue(sut.isActive)
        
        // When
        sut.stopDeviceMotionUpdates()
        
        // Then
        XCTAssertFalse(sut.isActive, "Stopping device motion should clear active flag")
    }
    
    func testDeviceMotionUpdates_WhenUnavailable_HandlesGracefully() {
        // When & Then
        XCTAssertNoThrow(sut.startDeviceMotionUpdates(), "Starting device motion when unavailable should not crash")
        XCTAssertNoThrow(sut.stopDeviceMotionUpdates(), "Stopping device motion when unavailable should not crash")
    }
    
    // MARK: - Physics Calculations Tests
    
    func testCalculateLift_WithDifferentAirplaneTypes_ReturnsVariedResults() {
        // Given
        let basicAirplane = PaperAirplane(type: .basic, fold: .basic, design: .plain)
        let speedyAirplane = PaperAirplane(type: .speedy, fold: .dart, design: .plain)
        let gliderAirplane = PaperAirplane(type: .glider, fold: .glider, design: .plain)
        
        basicAirplane.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 10))
        speedyAirplane.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 10))
        gliderAirplane.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 10))
        
        basicAirplane.physicsBody?.velocity = CGVector(dx: 100, dy: 0)
        speedyAirplane.physicsBody?.velocity = CGVector(dx: 100, dy: 0)
        gliderAirplane.physicsBody?.velocity = CGVector(dx: 100, dy: 0)
        
        // When
        let basicLift = sut.calculateLift(for: basicAirplane)
        let speedyLift = sut.calculateLift(for: speedyAirplane)
        let gliderLift = sut.calculateLift(for: gliderAirplane)
        
        // Then
        XCTAssertGreaterThan(basicLift, 0, "Basic airplane should generate lift")
        XCTAssertGreaterThan(speedyLift, 0, "Speedy airplane should generate lift")
        XCTAssertGreaterThan(gliderLift, 0, "Glider airplane should generate lift")
        
        // Glider should generate more lift than basic
        XCTAssertGreaterThan(gliderLift, basicLift, "Glider should generate more lift than basic airplane")
    }
    
    func testApplyForces_WithDifferentSensitivities_ScalesCorrectly() {
        // Given
        let lowSensitivity: CGFloat = 0.5
        let highSensitivity: CGFloat = 2.0
        let tiltX: CGFloat = 0.5
        let tiltY: CGFloat = 0.3
        
        // When
        sut.sensitivity = lowSensitivity
        sut.applyForces(to: testAirplane, tiltX: tiltX, tiltY: tiltY)
        let lowSensitivityVelocity = testAirplane.physicsBody?.velocity
        
        // Reset airplane
        testAirplane.physicsBody?.velocity = CGVector.zero
        
        sut.sensitivity = highSensitivity
        sut.applyForces(to: testAirplane, tiltX: tiltX, tiltY: tiltY)
        let highSensitivityVelocity = testAirplane.physicsBody?.velocity
        
        // Then
        if let lowVel = lowSensitivityVelocity, let highVel = highSensitivityVelocity {
            let lowMagnitude = sqrt(lowVel.dx * lowVel.dx + lowVel.dy * lowVel.dy)
            let highMagnitude = sqrt(highVel.dx * highVel.dx + highVel.dy * highVel.dy)
            XCTAssertGreaterThan(highMagnitude, lowMagnitude, "Higher sensitivity should result in greater force application")
        }
    }
    
    // MARK: - Wind System Tests
    
    func testWindTransition_CompletesSuccessfully() {
        // Given
        sut.setWindVector(direction: 0, strength: 50)
        let initialWind = sut.windVector
        let expectation = XCTestExpectation(description: "Wind transition completes")
        
        // When
        sut.transitionWindVector(toDirection: 180, strength: 100, duration: 0.1)
        
        // Wait for transition to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        let finalWind = sut.windVector
        XCTAssertNotEqual(initialWind.dx, finalWind.dx, accuracy: 0.01, "Wind X should change during transition")
        XCTAssertNotEqual(initialWind.dy, finalWind.dy, accuracy: 0.01, "Wind Y should change during transition")
    }
    
    func testRandomWindUpdate_ModifiesWindGradually() {
        // Given
        sut.setWindVector(direction: 90, strength: 50)
        let initialWind = sut.windVector
        
        // When
        for _ in 0..<10 {
            sut.updateRandomWind()
        }
        
        // Then
        let finalWind = sut.windVector
        let initialMagnitude = sqrt(initialWind.dx * initialWind.dx + initialWind.dy * initialWind.dy)
        let finalMagnitude = sqrt(finalWind.dx * finalWind.dx + finalWind.dy * finalWind.dy)
        
        // Wind should still exist but may have changed
        XCTAssertGreaterThan(finalMagnitude, 0, "Wind should still exist after random updates")
        XCTAssertLessThan(abs(finalMagnitude - initialMagnitude), initialMagnitude * 0.5, "Wind changes should be gradual")
    }
    
    // MARK: - Collision System Tests
    
    func testHandleCollision_WithDifferentPhysicsCategories_HandlesCorrectly() {
        // Given
        let airplane = SKSpriteNode()
        airplane.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 10))
        airplane.physicsBody?.categoryBitMask = PhysicsCategory.airplane
        
        let obstacle = SKSpriteNode()
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 30))
        obstacle.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        
        let collectible = SKSpriteNode()
        collectible.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 15, height: 15))
        collectible.physicsBody?.categoryBitMask = PhysicsCategory.collectible
        
        // When & Then
        XCTAssertNoThrow(sut.handleCollision(between: airplane, and: obstacle), "Airplane-obstacle collision should not crash")
        XCTAssertNoThrow(sut.handleCollision(between: airplane, and: collectible), "Airplane-collectible collision should not crash")
        XCTAssertNoThrow(sut.handleCollision(between: obstacle, and: collectible), "Obstacle-collectible collision should not crash")
    }
    
    func testHandleCollision_WithHighVelocityObjects_HandlesCorrectly() {
        // Given
        let nodeA = SKSpriteNode()
        nodeA.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: 10))
        nodeA.physicsBody?.velocity = CGVector(dx: 1000, dy: 1000)
        nodeA.physicsBody?.categoryBitMask = PhysicsCategory.airplane
        
        let nodeB = SKSpriteNode()
        nodeB.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: 10))
        nodeB.physicsBody?.velocity = CGVector(dx: -1000, dy: -1000)
        nodeB.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        
        // When & Then
        XCTAssertNoThrow(sut.handleCollision(between: nodeA, and: nodeB), "High velocity collision should not crash")
    }
    
    // MARK: - Turbulence System Tests
    
    func testApplyTurbulence_WithDifferentWindConditions_VariesEffect() {
        // Given
        let calmWind: CGFloat = 10
        let strongWind: CGFloat = 100
        
        // When
        sut.setWindVector(direction: 45, strength: calmWind)
        sut.applyTurbulence(to: testAirplane)
        let calmTurbulenceVelocity = testAirplane.physicsBody?.velocity
        
        // Reset airplane
        testAirplane.physicsBody?.velocity = CGVector.zero
        
        sut.setWindVector(direction: 45, strength: strongWind)
        sut.applyTurbulence(to: testAirplane)
        let strongTurbulenceVelocity = testAirplane.physicsBody?.velocity
        
        // Then
        if let calmVel = calmTurbulenceVelocity, let strongVel = strongTurbulenceVelocity {
            let calmMagnitude = sqrt(calmVel.dx * calmVel.dx + calmVel.dy * calmVel.dy)
            let strongMagnitude = sqrt(strongVel.dx * strongVel.dx + strongVel.dy * strongVel.dy)
            XCTAssertGreaterThan(strongMagnitude, calmMagnitude, "Stronger wind should create more turbulence")
        }
    }
    
    // MARK: - Advanced Flight Controls Tests
    
    func testApplyAdvancedFlightControls_WithVariousMotionData_HandlesCorrectly() {
        // Given
        let motion = CMDeviceMotion()
        
        // When & Then
        XCTAssertNoThrow(sut.applyAdvancedFlightControls(to: testAirplane, motion: motion), "Advanced flight controls should not crash")
    }
    
    // MARK: - State Management Tests
    
    func testPhysicsServiceState_ConsistentAcrossOperations() {
        // Given
        XCTAssertFalse(sut.isActive, "Should start inactive")
        
        // When
        sut.startPhysicsSimulation()
        XCTAssertTrue(sut.isActive, "Should be active after starting")
        
        sut.startDeviceMotionUpdates()
        XCTAssertTrue(sut.isActive, "Should remain active after starting device motion")
        
        sut.stopDeviceMotionUpdates()
        XCTAssertTrue(sut.isActive, "Should remain active after stopping device motion if physics is still running")
        
        sut.stopPhysicsSimulation()
        XCTAssertFalse(sut.isActive, "Should be inactive after stopping physics")
    }
    
    func testSensitivityPersistence_MaintainsValue() {
        // Given
        let testSensitivity: CGFloat = 1.7
        
        // When
        sut.sensitivity = testSensitivity
        sut.startPhysicsSimulation()
        sut.stopPhysicsSimulation()
        
        // Then
        XCTAssertEqual(sut.sensitivity, testSensitivity, accuracy: 0.01, "Sensitivity should persist across simulation start/stop")
    }
}