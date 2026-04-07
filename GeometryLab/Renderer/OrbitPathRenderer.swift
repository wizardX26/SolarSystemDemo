//
//  OrbitPathRenderer.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import Metal
import simd

/// Renders orbital paths as circles
class OrbitPathRenderer: BaseRenderer {
    var orbitPaths: [OrbitPath] = []
    var orbitVertexBuffers: [MTLBuffer] = []
    var orbitUniformBuffer: MTLBuffer!
    var orbitPipelineState: MTLRenderPipelineState!
    
    struct OrbitPath {
        let semiMajorAxis: Float  // a (longer radius)
        let semiMinorAxis: Float  // b (shorter radius, for elliptical)
        let vertexCount: Int
    }
    
    init(device: MTLDevice, orbitRadii: [Float]) {
        super.init(device: device)
        
        // Create orbit paths for each radius (as elliptical with eccentricity)
        for radius in orbitRadii {
            if radius > 0 {  // Skip Sun (radius = 0)
                // Create elliptical orbit: semiMajorAxis = radius, semiMinorAxis slightly smaller for oval shape
                let eccentricity: Float = 0.1  // Small eccentricity to make it oval
                let semiMajorAxis = radius
                let semiMinorAxis = radius * sqrt(1.0 - eccentricity * eccentricity)
                let path = OrbitPath(semiMajorAxis: semiMajorAxis, 
                                    semiMinorAxis: semiMinorAxis, 
                                    vertexCount: 128)  // More vertices for smooth oval
                orbitPaths.append(path)
            }
        }
        
        setupBuffers()
        setupPipeline()
    }
    
    private func setupBuffers() {
        // Create vertex buffers for each orbit path
        for path in orbitPaths {
            var vertices: [SIMD3<Float>] = []
            
            // Generate elliptical vertices in XZ plane
            for i in 0..<path.vertexCount {
                let angle = Float(i) * 2.0 * Float.pi / Float(path.vertexCount)
                // Elliptical coordinates
                let x = path.semiMajorAxis * cos(angle)
                let z = path.semiMinorAxis * sin(angle)
                vertices.append(SIMD3<Float>(x, 0, z))
            }
            
            // Add first vertex again at the end to close the loop (for continuous line)
            if let firstVertex = vertices.first {
                vertices.append(firstVertex)
            }
            
            // Create buffer for this orbit path
            let buffer = device.makeBuffer(bytes: vertices,
                                          length: MemoryLayout<SIMD3<Float>>.stride * vertices.count,
                                          options: [])
            orbitVertexBuffers.append(buffer!)
        }
    }
    
    private func setupPipeline() {
        // Vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = Int(BufferIndexVertices.rawValue)
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // Pipeline state - Try orbit path shaders first, fallback to grid shaders
        let descriptor = MTLRenderPipelineDescriptor()
        var vertexFunction = library.makeFunction(name: "orbit_path_vertex_main")
        var fragmentFunction = library.makeFunction(name: "orbit_path_fragment_main")
        
        // Fallback to grid shaders if orbit path shaders not found (file might not be compiled yet)
        if vertexFunction == nil || fragmentFunction == nil {
            vertexFunction = library.makeFunction(name: "grid_vertex_main")
            fragmentFunction = library.makeFunction(name: "grid_fragment_main")
        }
        
        guard let vFunc = vertexFunction, let fFunc = fragmentFunction else {
            fatalError("Failed to find orbit path or grid shader functions")
        }
        descriptor.vertexFunction = vFunc
        descriptor.fragmentFunction = fFunc
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            orbitPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            print("OrbitPathRenderer: Pipeline state created successfully, \(orbitPaths.count) orbit paths")
        } catch {
            fatalError("Failed to create orbit path pipeline state: \(error)")
        }
    }
    
    override func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4) {
        // Use axisColor field to store gray color for orbit paths
        var u = Uniforms(
            model: model,
            view: view,
            proj: proj,
            isAxis: 0,  // Not axis
            axisColor: SIMD4<Float>(0.5, 0.5, 0.5, 1.0)  // Gray color for orbit paths
        )
        
        if orbitUniformBuffer == nil {
            orbitUniformBuffer = device.makeBuffer(bytes: &u,
                                                  length: MemoryLayout<Uniforms>.stride,
                                                  options: [])
        } else {
            let contents = orbitUniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
            contents.pointee = u
        }
    }
    
    override func render(encoder: MTLRenderCommandEncoder) {
        guard orbitUniformBuffer != nil else {
            print("OrbitPathRenderer: Uniform buffer is nil, skipping render")
            return
        }
        
        encoder.setRenderPipelineState(orbitPipelineState)
        encoder.setVertexBuffer(orbitUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(orbitUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        
        // Draw each orbit path as a continuous line (line strip for smooth connection)
        for (index, buffer) in orbitVertexBuffers.enumerated() {
            encoder.setVertexBuffer(buffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
            // Use vertexCount + 1 because we added the first vertex at the end to close the loop
            encoder.drawPrimitives(type: .lineStrip,
                                  vertexStart: 0,
                                  vertexCount: orbitPaths[index].vertexCount + 1)
        }
    }
}

