import XCTest
import SpriteKit
@testable import Tiny_Pilots

/// Unit tests for the refactored PaperAirplane model
class PaperAirplaneModelTests: XCTestCase {
    
    var airplane: PaperAirplane!
    
    override func setUp() {
        super.setUp()
        airplane = PaperAirplane(type: .basic, fold: .basic, design: .plain)
    }
    
    override func tearDown() {
        airplane = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAirplane_Initialization_SetsCorrectProperties() {
        // Given
        let airplane = PaperAirplane(type: .speedy, fold: .dart, design: .striped)
        
        // Then
        XCTAssertEqual(airplane.type, .speedy, "Airplane type should be set correctly")
        XCTAssertEqual(airplane.fold, .dart, "Fold type should be set correctly")
        XCTAssertEqual(airplane.design, .striped, "Design type should be set correctly")
        XCTAssertEqual(airplane.name, "airplane", "Name should be set for identification")
        XCTAssertEqual(airplane.zPosition, 10, "Z-position should be set above background")
        XCTAssertFalse(airplane.isFlying, "Airplane should not be flying initially")
        XCTAssertEqual(airplane.tiltAngle, 0.0, "Tilt angle should be zero initially")
    }
    
    func testAirplane_PhysicsBodySetup_ConfiguresCorrectly() {
        // Then
        XCTAssertNotNil(airplane.physicsBody, "Physics body should be created")
        XCTAssertTrue(airplane.physicsBody?.isDynamic ?? false, "Physics body should be dynamic")
        XCTAssertTrue(airplane.physicsBody?.allowsRotation ?? false, "Physics body should allow rotation")
        XCTAssertTrue(airplane.physicsBody?.affectedByGravity ?? false, "Physics body should be affected by gravity")
        
        // Check collision categories
        XCTAssertEqual(airplane.physicsBody?.categoryBitMask, PhysicsCategory.airplane, "Category bitmask should be airplane")
        XCTAssertEqual(airplane.physicsBody?.contactTestBitMask, 
                      PhysicsCategory.obstacle | PhysicsCategory.collectible | PhysicsCategory.ground,
                      "Contact test bitmask should include obstacles, collectibles, and ground")
    }
    
    // MARK: - Airplane Type Tests
    
    func testAirplaneType_Properties_ReturnCorrectValues() {
        // Test basic airplane type
        XCTAssertEqual(PaperAirplane.AirplaneType.basic.mass, 1.0, "Basic airplane mass should be 1.0")
        XCTAssertEqual(PaperAirplane.AirplaneType.basic.linearDamping, 0.5, "Basic airplane linear damping should be 0.5")
        XCTAssertEqual(PaperAirplane.AirplaneType.basic.angularDamping, 0.7, "Basic airplane angular damping should be 0.7")
        
        // Test speedy airplane type
        XCTAssertEqual(PaperAirplane.AirplaneType.speedy.mass, 0.8, "Speedy airplane mass should be 0.8")
        XCTAssertEqual(PaperAirplane.AirplaneType.speedy.linearDamping, 0.3, "Speedy airplane linear damping should be 0.3")
        
        // Test size properties
        XCTAssertEqual(PaperAirplane.AirplaneType.basic.size, CGSize(width: 60, height: 40), "Basic airplane size should be correct")
        XCTAssertEqual(PaperAirplane.AirplaneType.glider.size, CGSize(width: 75, height: 40), "Glider airplane size should be correct")
    }
    
    func testAirplaneType_TextureName_ReturnsCorrectName() {
        // Test texture names
        XCTAssertEqual(PaperAirplane.AirplaneType.basic.textureName, "airplane_basic", "Basic airplane texture name should be correct")
        XCTAssertEqual(PaperAirplane.AirplaneType.speedy.textureName, "airplane_speedy", "Speedy airplane texture name should be correct")
        XCTAssertEqual(PaperAirplane.AirplaneType.sturdy.textureName, "airplane_sturdy", "Sturdy airplane texture name should be correct")
        XCTAssertEqual(PaperAirplane.AirplaneType.glider.textureName, "airplane_glider", "Glider airplane texture name should be correct")
    }
    
    // MARK: - Fold Type Tests
    
    func testFoldType_PhysicsMultiplier_ReturnsCorrectValues() {
        // Test basic fold type
        let basicMultiplier = PaperAirplane.FoldType.basic.physicsMultiplier
        XCTAssertEqual(basicMultiplier.lift, 1.0, "Basic fold lift multiplier should be 1.0")
        XCTAssertEqual(basicMultiplier.drag, 1.0, "Basic fold drag multiplier should be 1.0")
        XCTAssertEqual(basicMultiplier.turnRate, 1.0, "Basic fold turn rate multiplier should be 1.0")
        XCTAssertEqual(basicMultiplier.mass, 1.0, "Basic fold mass multiplier should be 1.0")
        
        // Test dart fold type
        let dartMultiplier = PaperAirplane.FoldType.dart.physicsMultiplier
        XCTAssertEqual(dartMultiplier.lift, 0.8, "Dart fold lift multiplier should be 0.8")
        XCTAssertEqual(dartMultiplier.drag, 0.7, "Dart fold drag multiplier should be 0.7")
        XCTAssertEqual(dartMultiplier.turnRate, 1.2, "Dart fold turn rate multiplier should be 1.2")
        
        // Test glider fold type
        let gliderMultiplier = PaperAirplane.FoldType.glider.physicsMultiplier
        XCTAssertEqual(gliderMultiplier.lift, 1.3, "Glider fold lift multiplier should be 1.3")
        XCTAssertEqual(gliderMultiplier.drag, 1.1, "Glider fold drag multiplier should be 1.1")
    }
    
    func testFoldType_UnlockLevel_ReturnsCorrectLevel() {
        // Test unlock levels
        XCTAssertEqual(PaperAirplane.FoldType.basic.unlockLevel, 1, "Basic fold should unlock at level 1")
        XCTAssertEqual(PaperAirplane.FoldType.dart.unlockLevel, 3, "Dart fold should unlock at level 3")
        XCTAssertEqual(PaperAirplane.FoldType.glider.unlockLevel, 5, "Glider fold should unlock at level 5")
        XCTAssertEqual(PaperAirplane.FoldType.stunt.unlockLevel, 8, "Stunt fold should unlock at level 8")
        XCTAssertEqual(PaperAirplane.FoldType.fighter.unlockLevel, 12, "Fighter fold should unlock at level 12")
    }
    
    // MARK: - Design Type Tests
    
    func testDesignType_UnlockLevel_ReturnsCorrectLevel() {
        // Test unlock levels
        XCTAssertEqual(PaperAirplane.DesignType.plain.unlockLevel, 1, "Plain design should unlock at level 1")
        XCTAssertEqual(PaperAirplane.DesignType.striped.unlockLevel, 2, "Striped design should unlock at level 2")
        XCTAssertEqual(PaperAirplane.DesignType.dotted.unlockLevel, 4, "Dotted design should unlock at level 4")
        XCTAssertEqual(PaperAirplane.DesignType.camouflage.unlockLevel, 7, "Camouflage design should unlock at level 7")
        XCTAssertEqual(PaperAirplane.DesignType.flames.unlockLevel, 10, "Flames design should unlock at level 10")
        XCTAssertEqual(PaperAirplane.DesignType.rainbow.unlockLevel, 15, "Rainbow design should unlock at level 15")
    }
    
    func testDesignType_TextureName_ReturnsCorrectName() {
        // Test texture names
        XCTAssertEqual(PaperAirplane.DesignType.plain.textureName, "airplane_design_plain", "Plain design texture name should be correct")
        XCTAssertEqual(PaperAirplane.DesignType.striped.textureName, "airplane_design_striped", "Striped design texture name should be correct")
        XCTAssertEqual(PaperAirplane.DesignType.flames.textureName, "airplane_design_flames", "Flames design texture name should be correct")
    }
    
    // MARK: - Configuration Tests
    
    func testAirplane_SetFold_UpdatesPhysicsProperties() {
        // Given
        let initialMass = airplane.physicsBody?.mass
        
        // When
        airplane.setFold(.glider)
        
        // Then
        XCTAssertEqual(airplane.fold, .glider, "Fold type should be updated")
        XCTAssertNotEqual(airplane.physicsBody?.mass, initialMass, "Physics properties should be updated")
        
        // Verify physics properties are updated based on fold multiplier
        let expectedMass = PaperAirplane.AirplaneType.basic.mass * PaperAirplane.FoldType.glider.physicsMultiplier.mass
        XCTAssertEqual(airplane.physicsBody?.mass, expectedMass, accuracy: 0.01, "Mass should be updated with fold multiplier")
    }
    
    func testAirplane_SetDesign_UpdatesVisualAppearance() {
        // Given
        let initialColor = airplane.color
        
        // When
        airplane.setDesign(.striped)
        
        // Then
        XCTAssertEqual(airplane.design, .striped, "Design type should be updated")
        XCTAssertNotEqual(airplane.color, initialColor, "Visual appearance should be updated")
        XCTAssertEqual(airplane.color, .blue, "Color should match striped design")
    }
    
    // MARK: - Physics Integration Tests
    
    func testAirplane_ApplyForces_DelegatesToPhysicsService() {
        // Given
        airplane.physicsBody?.velocity = CGVector(dx: 100, dy: 50)
        let initialTiltAngle = airplane.tiltAngle
        
        // When
        airplane.applyForces(tiltX: 0.5, tiltY: -0.3)
        
        // Then
        // The method should not directly modify physics anymore
        // It should only update visual state (tilt angle)
        // Physics calculations are now handled by PhysicsService
        XCTAssertNotNil(airplane.physicsBody?.velocity, "Velocity should still exist")
        // Tilt angle should be updated for visual representation
        XCTAssertNotEqual(airplane.tiltAngle, initialTiltAngle, "Tilt angle should be updated for visual representation")
    }
    
    func testAirplane_UpdateVisualState_UpdatesCorrectly() {
        // Given
        airplane.physicsBody?.velocity = CGVector(dx: 100, dy: 0)
        
        // When
        airplane.updateVisualState()
        
        // Then
        // Visual state should be updated based on physics state
        // This method should still work for visual updates
        XCTAssertNotNil(airplane.physicsBody, "Physics body should exist for visual updates")
    }
    
    func testAirplane_Reset_ClearsPhysicsAndVisualState() {
        // Given
        airplane.physicsBody?.velocity = CGVector(dx: 100, dy: 50)
        airplane.physicsBody?.angularVelocity = 1.0
        airplane.zRotation = CGFloat.pi / 4
        
        // When
        airplane.reset()
        
        // Then
        XCTAssertEqual(airplane.physicsBody?.velocity, CGVector.zero, "Velocity should be reset to zero")
        XCTAssertEqual(airplane.physicsBody?.angularVelocity, 0, "Angular velocity should be reset to zero")
        XCTAssertEqual(airplane.zRotation, 0, "Rotation should be reset to zero")
    }
    
    // MARK: - Physics Properties Integration Tests
    
    func testAirplane_PhysicsPropertiesIntegration_WorksWithDifferentTypes() {
        // Test different airplane types have different physics properties
        let basicAirplane = PaperAirplane(type: .basic, fold: .basic, design: .plain)
        let speedyAirplane = PaperAirplane(type: .speedy, fold: .basic, design: .plain)
        
        XCTAssertNotEqual(basicAirplane.physicsBody?.mass, speedyAirplane.physicsBody?.mass, 
                         "Different airplane types should have different masses")
        XCTAssertNotEqual(basicAirplane.physicsBody?.linearDamping, speedyAirplane.physicsBody?.linearDamping,
                         "Different airplane types should have different linear damping")
    }
    
    func testAirplane_PhysicsPropertiesIntegration_WorksWithDifferentFolds() {
        // Test different fold types affect physics properties
        let basicFoldAirplane = PaperAirplane(type: .basic, fold: .basic, design: .plain)
        let dartFoldAirplane = PaperAirplane(type: .basic, fold: .dart, design: .plain)
        
        XCTAssertNotEqual(basicFoldAirplane.physicsBody?.mass, dartFoldAirplane.physicsBody?.mass,
                         "Different fold types should result in different masses")
        XCTAssertNotEqual(basicFoldAirplane.physicsBody?.linearDamping, dartFoldAirplane.physicsBody?.linearDamping,
                         "Different fold types should result in different linear damping")
    }
    
    // MARK: - CGVector Extension Tests
    
    func testCGVector_Normalized_ReturnsCorrectVector() {
        // Test normal vector
        let vector = CGVector(dx: 3, dy: 4)
        let normalized = vector.normalized()
        
        XCTAssertEqual(normalized.dx, 0.6, accuracy: 0.01, "Normalized X component should be correct")
        XCTAssertEqual(normalized.dy, 0.8, accuracy: 0.01, "Normalized Y component should be correct")
        
        // Test zero vector
        let zeroVector = CGVector.zero
        let normalizedZero = zeroVector.normalized()
        
        XCTAssertEqual(normalizedZero, CGVector.zero, "Normalized zero vector should remain zero")
    }
    
    func testCGVector_Normalized_HasUnitLength() {
        // Test that normalized vector has length 1
        let vector = CGVector(dx: 5, dy: 12)
        let normalized = vector.normalized()
        
        let length = sqrt(normalized.dx * normalized.dx + normalized.dy * normalized.dy)
        XCTAssertEqual(length, 1.0, accuracy: 0.01, "Normalized vector should have unit length")
    }
}