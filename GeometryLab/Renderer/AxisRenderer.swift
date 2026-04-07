//
//  AxisRenderer.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import Metal
import simd

class AxisRenderer: BaseRenderer {
    var axisXVertexBuffer: MTLBuffer!
    var axisYVertexBuffer: MTLBuffer!
    var axisZVertexBuffer: MTLBuffer!
    var axisUniformBuffer: MTLBuffer!
    var axisPipelineState: MTLRenderPipelineState!
    
    private let axis: Axis
    
    init(device: MTLDevice, size: Float = 33.0) {
        self.axis = Axis.createAxes(size: size)
        super.init(device: device)
        setupBuffers()
        setupPipeline()
    }
    
    private func setupBuffers() {
        axisXVertexBuffer = device.makeBuffer(bytes: axis.xVertices,
                                              length: MemoryLayout<SIMD3<Float>>.stride * axis.xVertices.count,
                                              options: [])
        
        axisYVertexBuffer = device.makeBuffer(bytes: axis.yVertices,
                                              length: MemoryLayout<SIMD3<Float>>.stride * axis.yVertices.count,
                                              options: [])
        
        axisZVertexBuffer = device.makeBuffer(bytes: axis.zVertices,
                                              length: MemoryLayout<SIMD3<Float>>.stride * axis.zVertices.count,
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
        
        // Pipeline state
        let descriptor = MTLRenderPipelineDescriptor()
        guard let vertexFunction = library.makeFunction(name: "axis_vertex_main"),
              let fragmentFunction = library.makeFunction(name: "axis_fragment_main") else {
            fatalError("Failed to find axis shader functions")
        }
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            axisPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            print("AxisRenderer: Pipeline state created successfully")
        } catch {
            fatalError("Failed to create axis pipeline state: \(error)")
        }
    }
    
    // Store base uniforms (without color)
    private var baseUniforms: Uniforms?
    
    override func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4) {
        var u = Uniforms(
            model: model,
            view: view,
            proj: proj,
            isAxis: 1,  // Axis, not grid
            axisColor: SIMD4<Float>(0, 0, 0, 1)  // Will be set per axis in render
        )
        
        baseUniforms = u
        
        if axisUniformBuffer == nil {
            axisUniformBuffer = device.makeBuffer(bytes: &u,
                                                 length: MemoryLayout<Uniforms>.stride,
                                                 options: [])
        }
    }
    
    private func updateUniformBufferWithColor(_ color: SIMD4<Float>) {
        guard var u = baseUniforms else { return }
        u.axisColor = color
        
        let contents = axisUniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
        contents.pointee = u
    }
    
    private static var hasLoggedAxisPositions = false
    
    override func render(encoder: MTLRenderCommandEncoder) {
        guard axisUniformBuffer != nil, baseUniforms != nil else {
            print("AxisRenderer: Uniform buffer or base uniforms is nil, skipping render")
            return
        }
        
        // Log axis positions (only once)
        if !AxisRenderer.hasLoggedAxisPositions {
            print("\n=== VỊ TRÍ CÁC TRỤC (AXES) ===")
            print("Origin (gốc tọa độ): (0, 0, 0)")
            print("\nX Axis (màu đỏ):")
            print("  - Từ: (-\(axis.xVertices[3].x), 0, 0) đến (+\(axis.xVertices[1].x), 0, 0)")
            print("  - Độ dài: \(axis.xVertices[1].x * 2) units")
            print("\nY Axis (màu xanh lá):")
            print("  - Từ: (0, 0, 0) đến (0, \(axis.yVertices[1].y), 0)")
            print("  - Độ dài: \(axis.yVertices[1].y) units (chỉ positive)")
            print("\nZ Axis (màu xanh dương):")
            print("  - Từ: (0, 0, -\(abs(axis.zVertices[3].z))) đến (0, 0, +\(axis.zVertices[1].z))")
            print("  - Độ dài: \(axis.zVertices[1].z * 2) units")
            print("================================\n")
            AxisRenderer.hasLoggedAxisPositions = true
        }
        
        encoder.setRenderPipelineState(axisPipelineState)
        
        // Draw X axis (red)
        updateUniformBufferWithColor(SIMD4<Float>(1.0, 0.0, 0.0, 1.0))  // Red
        encoder.setVertexBuffer(axisUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(axisUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setVertexBuffer(axisXVertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.drawPrimitives(type: .line,
                               vertexStart: 0,
                               vertexCount: axis.xVertices.count)
        
        // Draw Y axis (green)
        updateUniformBufferWithColor(SIMD4<Float>(0.0, 1.0, 0.0, 1.0))  // Green
        encoder.setVertexBuffer(axisUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(axisUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setVertexBuffer(axisYVertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.drawPrimitives(type: .line,
                               vertexStart: 0,
                               vertexCount: axis.yVertices.count)
        
        // Draw Z axis (blue)
        updateUniformBufferWithColor(SIMD4<Float>(0.0, 0.0, 1.0, 1.0))  // Blue
        encoder.setVertexBuffer(axisUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setFragmentBuffer(axisUniformBuffer, offset: 0, index: Int(BufferIndexUniforms.rawValue))
        encoder.setVertexBuffer(axisZVertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
        encoder.drawPrimitives(type: .line,
                               vertexStart: 0,
                               vertexCount: axis.zVertices.count)
    }
}
