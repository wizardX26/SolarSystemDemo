//
//  BaseRenderer.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import Metal
import MetalKit
import simd

class BaseRenderer {
    let device: MTLDevice
    let library: MTLLibrary
    
    init(device: MTLDevice) {
        self.device = device
        self.library = device.makeDefaultLibrary()!
    }
    
    // Override trong subclasses
    func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4 = matrix_float4x4(1)) {
        // Default implementation - override in subclasses
    }
    
    func render(encoder: MTLRenderCommandEncoder) {
        // Default implementation - override in subclasses
    }
}
