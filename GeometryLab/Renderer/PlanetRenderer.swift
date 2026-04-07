//
//  PlanetRenderer.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import Metal
import simd

/// Specialized renderer for planets with color support
class PlanetRenderer: BaseRenderer {
    var mesh: Mesh
    var transform: Transform
    var color: SIMD4<Float>
    
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    
    init(device: MTLDevice, mesh: Mesh, transform: Transform = Transform(), color: SIMD4<Float>) {
        self.mesh = mesh
        self.transform = transform
        self.color = color
        super.init(device: device)
        setupBuffers()
        setupPipeline()
    }
    
    private func setupBuffers() {
        // Vertex buffer
        vertexBuffer = device.makeBuffer(bytes: mesh.vertices,
                                        length: MemoryLayout<SIMD3<Float>>.stride * mesh.vertices.count,
                                        options: [])
        
        // Index buffer for faces (if available)
        if let indices = mesh.indices, !indices.isEmpty {
            indexBuffer = device.makeBuffer(bytes: indices,
                                           length: MemoryLayout<UInt16>.stride * indices.count,
                                           options: [])
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
        
        // Pipeline state for planet
        let descriptor = MTLRenderPipelineDescriptor()
        guard let vertexFunction = library.makeFunction(name: "planet_vertex_main"),
              let fragmentFunction = library.makeFunction(name: "planet_fragment_main") else {
            fatalError("Failed to find planet shader functions")
        }
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Failed to create planet pipeline state: \(error)")
        }
    }
    
    override func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4) {
        // Use transform's model matrix
        let modelMatrix = transform.modelMatrix() * model
        
        var u = Uniforms(
            model: modelMatrix,
            view: view,
            proj: proj,
            isAxis: 0,
            axisColor: color  // Store planet color in axisColor field
        )
        
        if uniformBuffer == nil {
            uniformBuffer = device.makeBuffer(bytes: &u,
                                             length: MemoryLayout<Uniforms>.stride,
                                             options: [])
        } else {
            let contents = uniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
            contents.pointee = u
        }
    }
    
    override func render(encoder: MTLRenderCommandEncoder) {
        guard uniformBuffer != nil else { return }
        
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        
        // Draw filled planet
        if let indexBuffer = indexBuffer, let indices = mesh.indices, !indices.isEmpty {
            encoder.drawIndexedPrimitives(type: .triangle,
                                         indexCount: indices.count,
                                         indexType: .uint16,
                                         indexBuffer: indexBuffer,
                                         indexBufferOffset: 0)
        }
    }
    
    func setTransform(_ transform: Transform) {
        self.transform = transform
    }
    
    func getTransform() -> Transform {
        return transform
    }
}

