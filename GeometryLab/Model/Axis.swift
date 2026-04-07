//
//  Axis.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import simd

struct Axis {
    let xVertices: [SIMD3<Float>]
    let yVertices: [SIMD3<Float>]
    let zVertices: [SIMD3<Float>]
    
    static func createAxes(size: Float = 33.0) -> Axis {
        // X axis (red) - positive and negative
        let xAxis: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),      // Origin
            SIMD3<Float>(size, 0, 0),   // Positive X
            SIMD3<Float>(0, 0, 0),      // Origin
            SIMD3<Float>(-size, 0, 0)   // Negative X
        ]
        
        // Y axis (green) - positive only
        let yAxis: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),      // Origin
            SIMD3<Float>(0, size, 0)    // Positive Y
        ]
        
        // Z axis (blue) - positive and negative
        let zAxis: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),      // Origin
            SIMD3<Float>(0, 0, size),    // Positive Z
            SIMD3<Float>(0, 0, 0),      // Origin
            SIMD3<Float>(0, 0, -size)   // Negative Z
        ]
        
        return Axis(xVertices: xAxis, yVertices: yAxis, zVertices: zAxis)
    }
}
