//
//  TiltData.swift
//  Tiny Pilots
//
//  Created by Kiro on 7/17/25.
//

import Foundation

/// Represents tilt input data from device motion
struct TiltData: Codable, Equatable {
    /// Horizontal tilt value (-1.0 to 1.0)
    let x: Double
    
    /// Vertical tilt value (-1.0 to 1.0)
    let y: Double
    
    /// Roll tilt value (-1.0 to 1.0)
    let z: Double
    
    /// Initialize tilt data
    /// - Parameters:
    ///   - x: Horizontal tilt value
    ///   - y: Vertical tilt value
    ///   - z: Roll tilt value
    init(x: Double, y: Double, z: Double = 0.0) {
        self.x = max(-1.0, min(1.0, x)) // Clamp to valid range
        self.y = max(-1.0, min(1.0, y)) // Clamp to valid range
        self.z = max(-1.0, min(1.0, z)) // Clamp to valid range
    }
    
    /// Zero tilt data (no tilt)
    static let zero = TiltData(x: 0.0, y: 0.0, z: 0.0)
    
    /// Check if tilt data represents significant movement
    var hasSignificantMovement: Bool {
        let threshold: Double = 0.1
        return abs(x) > threshold || abs(y) > threshold || abs(z) > threshold
    }
    
    /// Get the magnitude of the tilt vector
    var magnitude: Double {
        return sqrt(x * x + y * y + z * z)
    }
    
    /// Apply sensitivity multiplier to tilt data
    /// - Parameter sensitivity: Sensitivity multiplier (0.0 to 2.0)
    /// - Returns: New TiltData with adjusted values
    func withSensitivity(_ sensitivity: Double) -> TiltData {
        let clampedSensitivity = max(0.0, min(2.0, sensitivity))
        return TiltData(
            x: x * clampedSensitivity,
            y: y * clampedSensitivity,
            z: z * clampedSensitivity
        )
    }
}

// MARK: - CustomStringConvertible

extension TiltData: CustomStringConvertible {
    var description: String {
        return "TiltData(x: \(String(format: "%.3f", x)), y: \(String(format: "%.3f", y)), z: \(String(format: "%.3f", z)))"
    }
}