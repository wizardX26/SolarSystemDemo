//
//  GPUDevice.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import Metal
import simd

typealias Acceleration = SIMD3<Float>

class GPUDevice {
    static let shared = GPUDevice()
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let library: MTLLibrary
    
    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.library = device.makeDefaultLibrary()!
    }
}
