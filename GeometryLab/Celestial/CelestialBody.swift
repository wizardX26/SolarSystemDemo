//
//  CelestialBody.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import simd
import Metal

class CelestialBody {
    let data: PlanetData
    let renderer: PlanetRenderer
    
    // Animation state
    var orbitAngle: Float = 0  // Current angle in orbit
    var rotationAngle: Float = 0  // Current rotation around axis
    
    init(device: MTLDevice, data: PlanetData) {
        self.data = data
        
        // Create sphere mesh with appropriate radius
        let sphereMesh = Mesh.createSphere(radius: data.radius, segments: 1)
        
        // Initial transform - will be updated in animation
        let initialTransform = Transform(
            position: SIMD3<Float>(data.orbitRadius, 0, 0),
            rotation: SIMD3<Float>(data.tilt, 0, 0),  // Apply tilt to X axis
            scale: SIMD3<Float>(1, 1, 1)
        )
        
        // Use PlanetRenderer with planet color
        self.renderer = PlanetRenderer(device: device, mesh: sphereMesh, transform: initialTransform, color: data.color)
    }
    
    /// Update orbital and rotational motion
    func update(deltaTime: Float) {
        // Update orbit angle (circular orbit in XZ plane)
        orbitAngle += data.orbitSpeed * deltaTime
        if orbitAngle > 2 * Float.pi {
            orbitAngle -= 2 * Float.pi
        }
        
        // Update rotation angle (around Y axis, but with tilt)
        rotationAngle += data.rotationSpeed * deltaTime
        if rotationAngle > 2 * Float.pi {
            rotationAngle -= 2 * Float.pi
        }
        
        // Calculate orbital position (circular orbit)
        let x = data.orbitRadius * cos(orbitAngle)
        let z = data.orbitRadius * sin(orbitAngle)
        let y: Float = 0  // All planets in same plane for simplicity
        
        // Update transform
        var transform = renderer.getTransform()
        transform.position = SIMD3<Float>(x, y, z)
        
        // Rotation: First apply tilt (X axis), then rotation (Y axis)
        // Tilt is applied to X axis, then rotation around Y axis
        transform.rotation = SIMD3<Float>(data.tilt, rotationAngle, 0)
        
        renderer.setTransform(transform)
    }
    
    /// Get current model matrix (for rendering)
    func getModelMatrix() -> matrix_float4x4 {
        return renderer.getTransform().modelMatrix()
    }
    
    /// Update uniforms for rendering
    func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4) {
        renderer.updateUniforms(view: view, proj: proj, model: model)
    }
    
    /// Render the celestial body
    func render(encoder: MTLRenderCommandEncoder) {
        renderer.render(encoder: encoder)
    }
}

