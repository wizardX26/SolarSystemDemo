//
//  SceneRenderer.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import Metal
import QuartzCore
import simd

class SceneRenderer {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var depthStencilState: MTLDepthStencilState!
    
    // Solar System
    var celestialBodies: [CelestialBody] = []
    
    // Orbit paths renderer (replaces grid)
    let orbitPathRenderer: OrbitPathRenderer
    
    // Camera state - Optimized for solar system view
    var cameraRotationY: Float = Float.pi / 4.0  // Yaw - 45 degrees
    var cameraRotationX: Float = Float.pi / 6.0  // Pitch - 30 degrees (looking down)
    var cameraDistance: Float = 60.0   // Distance - far enough to see all planets (Neptune at 45)
    
    // Debug flags
    private var hasPrintedCameraInfo = false
    private var hasWarnedViewSize = false
    private var renderCallCount = 0
    
    // View properties
    var viewSize: CGSize = .zero {
        didSet {
            // Debug: Print view size when it changes
            if viewSize.width > 0 && viewSize.height > 0 {
                print("SceneRenderer: View size set to \(viewSize)")
            }
        }
    }
    
    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = GPUDevice.shared.commandQueue
        
        // Create solar system first to get orbit radii
        // Create all celestial bodies from PlanetData
        var bodies: [CelestialBody] = []
        for planetData in PlanetData.allPlanets {
            let body = CelestialBody(device: device, data: planetData)
            bodies.append(body)
        }
        self.celestialBodies = bodies
        print("Solar System: Created \(celestialBodies.count) celestial bodies")
        
        // Create orbit path renderer with planet orbit radii
        let orbitRadii = celestialBodies.compactMap { body -> Float? in
            body.data.orbitRadius > 0 ? body.data.orbitRadius : nil
        }
        self.orbitPathRenderer = OrbitPathRenderer(device: device, orbitRadii: orbitRadii)
        
        setupDepthStencil()
    }
    
    private func setupDepthStencil() {
        let depthDesc = MTLDepthStencilDescriptor()
        depthDesc.depthCompareFunction = .less
        depthDesc.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthDesc)
    }
    
    func updateUniforms() {
        guard viewSize.width > 0 && viewSize.height > 0 else {
            print("SceneRenderer: Cannot update uniforms - viewSize is zero")
            return
        }
        
        let aspect = Float(viewSize.width / max(viewSize.height, 1.0))
        
        // Calculate camera position from spherical coordinates
        let eye = GeometryUtils.cameraPosition(rotationY: cameraRotationY,
                                               rotationX: cameraRotationX,
                                               distance: cameraDistance)
        let center = SIMD3<Float>(0, 0, 0)
        let up = SIMD3<Float>(0, 1, 0)
        
        let viewMatrix = matrix_float4x4(eye: eye, center: center, up: up)
        
        // Adjust near plane based on camera distance to prevent clipping when zooming in
        // Near plane should be much smaller when camera is close to avoid clipping
        // When zooming in (distance < 5), use very small near plane
        let adaptiveNear: Float
        if cameraDistance < 5.0 {
            adaptiveNear = 0.0001  // Very small near plane when very close
        } else {
            adaptiveNear = max(0.01, cameraDistance * 0.01)  // 1% of distance, min 0.01
        }
        let adaptiveFar = max(200.0, cameraDistance * 3.0)   // At least 3x distance for far plane
        
        let projMatrix = matrix_float4x4(perspectiveDegrees: 60,
                                         aspect: aspect,
                                         near: adaptiveNear, far: adaptiveFar)
        
        // Debug: Log near/far when zooming in
        if cameraDistance < 2.0 && !hasPrintedCameraInfo {
            print("SceneRenderer: Zoom in detected - distance=\(cameraDistance), near=\(adaptiveNear), far=\(adaptiveFar)")
        }
        let modelMatrix = matrix_float4x4(1)
        
        // Debug: Print camera info (only once)
        if !hasPrintedCameraInfo {
            print("SceneRenderer: Camera eye=\(eye), distance=\(cameraDistance)")
            print("SceneRenderer: Aspect=\(aspect), viewSize=\(viewSize)")
            print("SceneRenderer: Solar System with \(celestialBodies.count) celestial bodies")
            hasPrintedCameraInfo = true
        }
        
        // Update orbit paths
        orbitPathRenderer.updateUniforms(view: viewMatrix, proj: projMatrix, model: modelMatrix)
        
        // Update all celestial bodies
        for body in celestialBodies {
            body.updateUniforms(view: viewMatrix, proj: projMatrix, model: modelMatrix)
        }
    }
    
    func render(descriptor: MTLRenderPassDescriptor, drawable: CAMetalDrawable) {
        // Ensure uniforms are updated
        if viewSize.width > 0 && viewSize.height > 0 {
            updateUniforms()
        } else {
            // Debug: Print if viewSize is still zero
            if !hasWarnedViewSize {
                print("SceneRenderer: Warning - viewSize is zero, cannot render")
                hasWarnedViewSize = true
            }
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            print("SceneRenderer: Failed to create command buffer or encoder")
            return
        }
        
        encoder.setDepthStencilState(depthStencilState)
        
        // Debug: Print render call (only once)
        renderCallCount += 1
        if renderCallCount == 1 {
            print("SceneRenderer: First render call")
        }
        
        // Render order: Orbit Paths → Celestial Bodies
        orbitPathRenderer.render(encoder: encoder)
        
        // Render all celestial bodies (Sun first, then planets)
        for body in celestialBodies {
            body.render(encoder: encoder)
        }
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // Camera control methods
    func updateCameraRotation(deltaY: Float, deltaX: Float) {
        cameraRotationY += deltaY
        cameraRotationX += deltaX
        cameraRotationX = GeometryUtils.clampPitch(cameraRotationX)
        updateUniforms()
    }
    
    func updateCameraDistance(delta: Float) {
        cameraDistance *= delta
        cameraDistance = GeometryUtils.clampDistance(cameraDistance)
        updateUniforms()
    }
    
    func setViewSize(_ size: CGSize) {
        viewSize = size
        updateUniforms()
    }
    
    // MARK: - Solar System Control Methods
    
    /// Get celestial body by name
    func getCelestialBody(name: String) -> CelestialBody? {
        return celestialBodies.first { $0.data.name == name }
    }
    
    /// Get all celestial body names
    func getCelestialBodyNames() -> [String] {
        return celestialBodies.map { $0.data.name }
    }
    
    // MARK: - Animation Methods
    
    /// Update animation (call this every frame)
    func updateAnimation(deltaTime: Float) {
        // Update all celestial bodies (orbital and rotational motion)
        for body in celestialBodies {
            body.update(deltaTime: deltaTime)
        }
        
        // Update uniforms for all objects
        if viewSize.width > 0 && viewSize.height > 0 {
            updateUniforms()
        }
    }
    
    // MARK: - Diagnostic Methods
    
    /// Kiểm tra khả năng hiển thị của tất cả các thành phần đã render
    func verifyRenderingCapability() -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        var isValid = true
        
        print("\n=== KIỂM TRA KHẢ NĂNG HIỂN THỊ ===\n")
        
        // 1. Kiểm tra Device và Command Queue
        if device == nil {
            issues.append("❌ Device is nil")
            isValid = false
        } else {
            print("✅ Device: \(device.name)")
        }
        
        if commandQueue == nil {
            issues.append("❌ Command Queue is nil")
            isValid = false
        } else {
            print("✅ Command Queue: OK")
        }
        
        if depthStencilState == nil {
            issues.append("❌ Depth Stencil State is nil")
            isValid = false
        } else {
            print("✅ Depth Stencil State: OK")
        }
        
        // 2. Kiểm tra View Size
        if viewSize.width <= 0 || viewSize.height <= 0 {
            issues.append("❌ View Size is invalid: \(viewSize)")
            isValid = false
        } else {
            print("✅ View Size: \(viewSize.width) x \(viewSize.height)")
        }
        
        // 3. Kiểm tra Orbit Path Renderer
        print("\n--- Orbit Path Renderer ---")
        let orbitStatus = verifyOrbitPathRenderer()
        if !orbitStatus.isValid {
            issues.append(contentsOf: orbitStatus.issues)
            isValid = false
        }
        
        // 4. Kiểm tra Celestial Bodies
        print("\n--- Celestial Bodies ---")
        print("✅ Number of celestial bodies: \(celestialBodies.count)")
        for body in celestialBodies {
            print("  ✅ \(body.data.name): radius=\(body.data.radius), orbit=\(body.data.orbitRadius)")
        }
        
        // 5. Kiểm tra Camera và Uniforms
        print("\n--- Camera & Uniforms ---")
        let cameraStatus = verifyCameraAndUniforms()
        if !cameraStatus.isValid {
            issues.append(contentsOf: cameraStatus.issues)
            isValid = false
        }
        
        print("\n=== KẾT QUẢ KIỂM TRA ===")
        if isValid {
            print("✅ TẤT CẢ THÀNH PHẦN SẴN SÀNG HIỂN THỊ\n")
        } else {
            print("❌ PHÁT HIỆN \(issues.count) VẤN ĐỀ:\n")
            for issue in issues {
                print("  \(issue)")
            }
            print()
        }
        
        return (isValid, issues)
    }
    
    private func verifyOrbitPathRenderer() -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        var isValid = true
        
        if orbitPathRenderer.orbitVertexBuffers.isEmpty {
            issues.append("❌ Orbit path vertex buffers are empty")
            isValid = false
        } else {
            print("✅ Orbit path vertex buffers: \(orbitPathRenderer.orbitVertexBuffers.count) paths")
        }
        
        if orbitPathRenderer.orbitUniformBuffer == nil {
            issues.append("❌ Orbit path uniform buffer is nil")
            isValid = false
        } else {
            print("✅ Orbit path uniform buffer: OK")
        }
        
        if orbitPathRenderer.orbitPipelineState == nil {
            issues.append("❌ Orbit path pipeline state is nil")
            isValid = false
        } else {
            print("✅ Orbit path pipeline state: OK")
        }
        
        return (isValid, issues)
    }
    
    private func verifyCameraAndUniforms() -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        var isValid = true
        
        print("✅ Camera rotation Y: \(cameraRotationY)")
        print("✅ Camera rotation X: \(cameraRotationX)")
        print("✅ Camera distance: \(cameraDistance)")
        
        let eye = GeometryUtils.cameraPosition(rotationY: cameraRotationY,
                                               rotationX: cameraRotationX,
                                               distance: cameraDistance)
        print("✅ Camera eye position: \(eye)")
        
        if viewSize.width > 0 && viewSize.height > 0 {
            let aspect = Float(viewSize.width / viewSize.height)
            print("✅ Aspect ratio: \(aspect)")
        } else {
            issues.append("❌ Cannot calculate aspect ratio - viewSize is invalid")
            isValid = false
        }
        
        return (isValid, issues)
    }
}
