//
//  Transform.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import simd

struct Transform {
    var position: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var rotation: SIMD3<Float> = SIMD3<Float>(0, 0, 0)  // Euler angles (X, Y, Z) in radians
    var scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1)
    
    /// Calculate model matrix: Translation * Rotation * Scale
    func modelMatrix() -> matrix_float4x4 {
        // Scale matrix
        let scaleMatrix = matrix_float4x4(scale: scale)
        
        // Rotation matrices for each axis (applied in Z, Y, X order)
        let rotX = matrix_float4x4(rotationX: rotation.x)
        let rotY = matrix_float4x4(rotationY: rotation.y)
        let rotZ = matrix_float4x4(rotationZ: rotation.z)
        
        // Combine rotations: Z * Y * X (Euler angles)
        let rotationMatrix = rotZ * rotY * rotX
        
        // Translation matrix
        let translationMatrix = matrix_float4x4(translation: position)
        
        // Combine: Translation * Rotation * Scale
        return translationMatrix * rotationMatrix * scaleMatrix
    }
    
    // MARK: - Helper Methods
    
    /// Translate by delta
    mutating func translate(_ delta: SIMD3<Float>) {
        position += delta
    }
    
    /// Rotate by delta (in radians)
    mutating func rotate(_ delta: SIMD3<Float>) {
        rotation += delta
    }
    
    /// Scale by factor (uniform scaling)
    mutating func scaleBy(_ factor: Float) {
        scale *= factor
    }
    
    /// Scale by factor (non-uniform scaling)
    mutating func scaleBy(_ factor: SIMD3<Float>) {
        scale *= factor
    }
    
    /// Reset to identity transform
    mutating func reset() {
        position = SIMD3<Float>(0, 0, 0)
        rotation = SIMD3<Float>(0, 0, 0)
        scale = SIMD3<Float>(1, 1, 1)
    }
    
    /// Create identity transform
    static func identity() -> Transform {
        return Transform()
    }
}
