//
//  Triangle.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import simd

struct Triangle {
    // Triangular pyramid (tetrahedron) vertices
    // 4 vertices: 1 apex + 3 base vertices
    let vertices: [SIMD3<Float>]
    let indices: [UInt16]
    let edgeIndices: [UInt16]
    
    static func createTriangularPyramid(apexAngle: Float = Float.pi / 6.0, // 30 degrees
                                       baseRadius: Float = 1.5,
                                       baseY: Float = 0.0) -> Triangle {
        // 3 base vertices forming equilateral triangle
        var baseVertices: [SIMD3<Float>] = []
        for i in 0..<3 {
            let angle = Float(i) * 2.0 * Float.pi / 3.0
            let x = baseRadius * cos(angle)
            let z = baseRadius * sin(angle)
            baseVertices.append(SIMD3<Float>(x, baseY, z))
        }
        
        // Calculate apex height to ensure apex angle
        let baseEdgeLength = baseRadius * sqrt(3.0)
        let halfEdge = baseEdgeLength / 2.0
        let height = halfEdge / tan(apexAngle / 2.0)
        
        // Apex at center of base, elevated
        let apex = SIMD3<Float>(0, height, 0)
        
        // All vertices: apex + 3 base vertices
        let allVertices = [apex] + baseVertices
        
        // 3 triangular faces (sides of pyramid)
        let faceIndices: [UInt16] = [
            0, 1, 2,  // Face 1: apex + base 0 + base 1
            0, 2, 3,  // Face 2: apex + base 1 + base 2
            0, 3, 1   // Face 3: apex + base 2 + base 0
        ]
        
        // Edge indices for wireframe
        let edges: [UInt16] = [
            // 3 edges from apex to base vertices
            0, 1,  // apex -> base 1
            0, 2,  // apex -> base 2
            0, 3,  // apex -> base 3
            // 3 edges of base triangle
            1, 2,  // base 1 -> base 2
            2, 3,  // base 2 -> base 3
            3, 1   // base 3 -> base 1
        ]
        
        return Triangle(vertices: allVertices, indices: faceIndices, edgeIndices: edges)
    }
}
