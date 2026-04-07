//
//  GeometryUtils.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import simd

struct GeometryUtils {
    // Calculate camera position from spherical coordinates
    static func cameraPosition(rotationY: Float, rotationX: Float, distance: Float) -> SIMD3<Float> {
        let eyeX = distance * cos(rotationX) * sin(rotationY)
        let eyeY = distance * sin(rotationX)
        let eyeZ = distance * cos(rotationX) * cos(rotationY)
        return SIMD3<Float>(eyeX, eyeY, eyeZ)
    }
    
    // Clamp pitch angle
    static func clampPitch(_ pitch: Float) -> Float {
        return max(-Float.pi / 2 + 0.1, min(Float.pi / 2 - 0.1, pitch))
    }
    
    // Clamp camera distance (allow zoom in much closer)
    static func clampDistance(_ distance: Float, min: Float = 0.5, max: Float = 100.0) -> Float {
        return Swift.max(min, Swift.min(max, distance))
    }
}
