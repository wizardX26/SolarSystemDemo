//
//  MeshRenderer.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import Metal
import simd

/// Generic renderer for any Mesh geometry
class MeshRenderer: BaseRenderer {
    var mesh: Mesh
    var transform: Transform
    
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer?
    var edgeIndexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    var edgePipelineState: MTLRenderPipelineState?
    
    private var drawCallCount = 0
    
    init(device: MTLDevice, mesh: Mesh, transform: Transform = Transform()) {
        self.mesh = mesh
        self.transform = transform
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
        
        // Edge index buffer for wireframe (if available)
        if let edgeIndices = mesh.edgeIndices, !edgeIndices.isEmpty {
            edgeIndexBuffer = device.makeBuffer(bytes: edgeIndices,
                                               length: MemoryLayout<UInt16>.stride * edgeIndices.count,
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
        
        // Pipeline state for filled mesh
        let descriptor = MTLRenderPipelineDescriptor()
        guard let vertexFunction = library.makeFunction(name: "triangle_vertex_main"),
              let fragmentFunction = library.makeFunction(name: "triangle_fragment_main") else {
            fatalError("Failed to find mesh shader functions")
        }
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            print("MeshRenderer: Pipeline state created successfully for mesh with \(mesh.vertices.count) vertices")
        } catch {
            fatalError("Failed to create mesh pipeline state: \(error)")
        }
        
        // Pipeline state for edges (if edge indices are available)
        if edgeIndexBuffer != nil {
            let edgeDescriptor = MTLRenderPipelineDescriptor()
            edgeDescriptor.vertexFunction = library.makeFunction(name: "triangle_vertex_main")
            edgeDescriptor.fragmentFunction = library.makeFunction(name: "triangle_edge_fragment_main")
            edgeDescriptor.vertexDescriptor = vertexDescriptor
            edgeDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            edgeDescriptor.depthAttachmentPixelFormat = .depth32Float
            
            do {
                edgePipelineState = try device.makeRenderPipelineState(descriptor: edgeDescriptor)
                print("MeshRenderer: Edge pipeline state created successfully")
            } catch {
                fatalError("Failed to create mesh edge pipeline state: \(error)")
            }
        }
    }
    
    override func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4) {
        // Use transform's model matrix instead of identity
        let modelMatrix = transform.modelMatrix() * model
        
        var u = Uniforms(
            model: modelMatrix,
            view: view,
            proj: proj,
            isAxis: 0,
            axisColor: SIMD4<Float>(0, 0, 0, 1)  // Not used for mesh
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
        guard uniformBuffer != nil else {
            print("MeshRenderer: Uniform buffer is nil, skipping render")
            return
        }
        
        // Debug: Print draw call (only once)
        drawCallCount += 1
        if drawCallCount == 1 {
            let indexCount = mesh.indices?.count ?? 0
            let edgeCount = mesh.edgeIndices?.count ?? 0
            print("MeshRenderer: Drawing mesh with \(mesh.vertices.count) vertices, \(indexCount) face indices, \(edgeCount) edge indices")
        }
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        
        // Draw filled mesh (if indices are available)
        if let indexBuffer = indexBuffer, let indices = mesh.indices, !indices.isEmpty {
            encoder.setRenderPipelineState(pipelineState)
            encoder.drawIndexedPrimitives(type: .triangle,
                                         indexCount: indices.count,
                                         indexType: .uint16,
                                         indexBuffer: indexBuffer,
                                         indexBufferOffset: 0)
        } else {
            // Draw as point cloud or lines if no indices
            encoder.setRenderPipelineState(pipelineState)
            encoder.drawPrimitives(type: .point,
                                  vertexStart: 0,
                                  vertexCount: mesh.vertices.count)
        }
        
        // Draw edges (wireframe) if available
        if let edgeIndexBuffer = edgeIndexBuffer,
           let edgePipelineState = edgePipelineState,
           let edgeIndices = mesh.edgeIndices, !edgeIndices.isEmpty {
            encoder.setRenderPipelineState(edgePipelineState)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
            encoder.setVertexBuffer(uniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
            encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
            
            encoder.drawIndexedPrimitives(type: .line,
                                          indexCount: edgeIndices.count,
                                          indexType: .uint16,
                                          indexBuffer: edgeIndexBuffer,
                                          indexBufferOffset: 0)
        }
    }
    
    // MARK: - Transform Helpers
    
    /// Update transform and mark for uniform update
    func setTransform(_ transform: Transform) {
        self.transform = transform
    }
    
    /// Get current transform
    func getTransform() -> Transform {
        return transform
    }
}

