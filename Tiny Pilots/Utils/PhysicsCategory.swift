import SpriteKit

/// Physics category bitmasks for collision detection
struct PhysicsCategory {
    static let none: UInt32 = 0
    static let all: UInt32 = UInt32.max
    static let airplane: UInt32 = 0x1 << 0      // 1
    static let obstacle: UInt32 = 0x1 << 1      // 2
    static let collectible: UInt32 = 0x1 << 2   // 4
    static let ground: UInt32 = 0x1 << 3        // 8
    static let boundary: UInt32 = 0x1 << 4      // 16
} 