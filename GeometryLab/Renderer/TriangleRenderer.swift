//
//  TriangleRenderer.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import Metal
import simd

class TriangleRenderer: BaseRenderer {
    var triangleVertexBuffer: MTLBuffer!
    var triangleIndexBuffer: MTLBuffer!
    var triangleEdgeIndexBuffer: MTLBuffer!
    var triangleUniformBuffer: MTLBuffer!
    var trianglePipelineState: MTLRenderPipelineState!
    var triangleEdgePipelineState: MTLRenderPipelineState!
    
    private let triangle: Triangle
    private var drawCallCount = 0
    
    override init(device: MTLDevice) {
        self.triangle = Triangle.createTriangularPyramid()
        super.init(device: device)
        setupBuffers()
        setupPipeline()
    }
    
    private func setupBuffers() {
        // Vertex buffer
        triangleVertexBuffer = device.makeBuffer(bytes: triangle.vertices,
                                                 length: MemoryLayout<SIMD3<Float>>.stride * triangle.vertices.count,
                                                 options: [])
        
        // Index buffer for faces
        triangleIndexBuffer = device.makeBuffer(bytes: triangle.indices,
                                               length: MemoryLayout<UInt16>.stride * triangle.indices.count,
                                               options: [])
        
        // Index buffer for edges
        triangleEdgeIndexBuffer = device.makeBuffer(bytes: triangle.edgeIndices,
                                                    length: MemoryLayout<UInt16>.stride * triangle.edgeIndices.count,
                                                    options: [])
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
        
        // Pipeline state for filled triangle
        let descriptor = MTLRenderPipelineDescriptor()
        guard let vertexFunction = library.makeFunction(name: "triangle_vertex_main"),
              let fragmentFunction = library.makeFunction(name: "triangle_fragment_main") else {
            fatalError("Failed to find triangle shader functions")
        }
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            trianglePipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            print("TriangleRenderer: Pipeline state created successfully")
        } catch {
            fatalError("Failed to create triangle pipeline state: \(error)")
        }
        
        // Pipeline state for triangle edges
        let edgeDescriptor = MTLRenderPipelineDescriptor()
        edgeDescriptor.vertexFunction = library.makeFunction(name: "triangle_vertex_main")
        edgeDescriptor.fragmentFunction = library.makeFunction(name: "triangle_edge_fragment_main")
        edgeDescriptor.vertexDescriptor = vertexDescriptor
        edgeDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        edgeDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            triangleEdgePipelineState = try device.makeRenderPipelineState(descriptor: edgeDescriptor)
        } catch {
            fatalError("Failed to create triangle edge pipeline state: \(error)")
        }
    }
    
    override func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4) {
        var u = Uniforms(
            model: model,
            view: view,
            proj: proj,
            isAxis: 0,
            axisColor: SIMD4<Float>(0, 0, 0, 1)  // Not used for triangle
        )
        
        if triangleUniformBuffer == nil {
            triangleUniformBuffer = device.makeBuffer(bytes: &u,
                                                      length: MemoryLayout<Uniforms>.stride,
                                                      options: [])
        } else {
            let contents = triangleUniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
            contents.pointee = u
        }
    }
    
    override func render(encoder: MTLRenderCommandEncoder) {
        guard triangleUniformBuffer != nil else {
            print("TriangleRenderer: Uniform buffer is nil, skipping render")
            return
        }
        
        // Debug: Print draw call (only once)
        drawCallCount += 1
        if drawCallCount == 1 {
            print("TriangleRenderer: Drawing triangle with \(triangle.vertices.count) vertices, \(triangle.indices.count) indices")
        }
        
        // Draw filled triangle (red)
        encoder.setRenderPipelineState(trianglePipelineState)
        encoder.setVertexBuffer(triangleVertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.setVertexBuffer(triangleUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(triangleUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: triangle.indices.count,
                                      indexType: .uint16,
                                      indexBuffer: triangleIndexBuffer,
                                      indexBufferOffset: 0)
        
        // Draw triangle edges (white)
        encoder.setRenderPipelineState(triangleEdgePipelineState)
        encoder.setVertexBuffer(triangleVertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.setVertexBuffer(triangleUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(triangleUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        
        encoder.drawIndexedPrimitives(type: .line,
                                      indexCount: triangle.edgeIndices.count,
                                      indexType: .uint16,
                                      indexBuffer: triangleEdgeIndexBuffer,
                                      indexBufferOffset: 0)
    }
}
