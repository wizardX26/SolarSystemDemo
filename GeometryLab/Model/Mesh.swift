//
//  Mesh.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import simd

struct Mesh {
    let vertices: [SIMD3<Float>]
    let indices: [UInt16]?
    let edgeIndices: [UInt16]?  // For wireframe rendering
    
    init(vertices: [SIMD3<Float>], indices: [UInt16]? = nil, edgeIndices: [UInt16]? = nil) {
        self.vertices = vertices
        self.indices = indices
        self.edgeIndices = edgeIndices
    }
    
    // MARK: - Factory Methods
    
    /// Create triangular pyramid (tetrahedron)
    static func createTriangularPyramid(apexAngle: Float = Float.pi / 6.0,
                                       baseRadius: Float = 1.5,
                                       baseY: Float = 0.0) -> Mesh {
        // 3 base vertices forming equilateral triangle
        var baseVertices: [SIMD3<Float>] = []
        for i in 0..<3 {
            let angle = Float(i) * 2.0 * Float.pi / 3.0
            let x = baseRadius * cos(angle)
            let z = baseRadius * sin(angle)
            baseVertices.append(SIMD3<Float>(x, baseY, z))
        }
        
        // Calculate apex height
        let baseEdgeLength = baseRadius * sqrt(3.0)
        let halfEdge = baseEdgeLength / 2.0
        let height = halfEdge / tan(apexAngle / 2.0)
        
        // Apex at center of base, elevated
        let apex = SIMD3<Float>(0, height, 0)
        
        // All vertices: apex + 3 base vertices
        let allVertices = [apex] + baseVertices
        
        // Face indices
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
        
        return Mesh(vertices: allVertices, indices: faceIndices, edgeIndices: edges)
    }
    
    /// Create a quad (rectangle)
    static func createQuad(size: Float = 2.0) -> Mesh {
        let halfSize = size / 2.0
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(-halfSize, 0, -halfSize),  // Bottom-left
            SIMD3<Float>(halfSize, 0, -halfSize),   // Bottom-right
            SIMD3<Float>(halfSize, 0, halfSize),     // Top-right
            SIMD3<Float>(-halfSize, 0, halfSize)     // Top-left
        ]
        
        let indices: [UInt16] = [
            0, 1, 2,  // First triangle
            0, 2, 3   // Second triangle
        ]
        
        let edges: [UInt16] = [
            0, 1, 1, 2, 2, 3, 3, 0  // Perimeter
        ]
        
        return Mesh(vertices: vertices, indices: indices, edgeIndices: edges)
    }
    
    /// Create a cube
    static func createCube(size: Float = 2.0) -> Mesh {
        let halfSize = size / 2.0
        let vertices: [SIMD3<Float>] = [
            // Front face
            SIMD3<Float>(-halfSize, -halfSize, halfSize),
            SIMD3<Float>(halfSize, -halfSize, halfSize),
            SIMD3<Float>(halfSize, halfSize, halfSize),
            SIMD3<Float>(-halfSize, halfSize, halfSize),
            // Back face
            SIMD3<Float>(-halfSize, -halfSize, -halfSize),
            SIMD3<Float>(halfSize, -halfSize, -halfSize),
            SIMD3<Float>(halfSize, halfSize, -halfSize),
            SIMD3<Float>(-halfSize, halfSize, -halfSize)
        ]
        
        let indices: [UInt16] = [
            // Front
            0, 1, 2,  0, 2, 3,
            // Back
            4, 6, 5,  4, 7, 6,
            // Top
            3, 2, 6,  3, 6, 7,
            // Bottom
            0, 5, 1,  0, 4, 5,
            // Right
            1, 5, 6,  1, 6, 2,
            // Left
            0, 3, 7,  0, 7, 4
        ]
        
        let edges: [UInt16] = [
            // Front face
            0, 1, 1, 2, 2, 3, 3, 0,
            // Back face
            4, 5, 5, 6, 6, 7, 7, 4,
            // Connecting edges
            0, 4, 1, 5, 2, 6, 3, 7
        ]
        
        return Mesh(vertices: vertices, indices: indices, edgeIndices: edges)
    }
    
    /// Create a sphere (approximated with icosahedron subdivision)
    static func createSphere(radius: Float = 1.0, segments: Int = 1) -> Mesh {
        // Start with icosahedron
        let sqrt5: Float = sqrt(5.0)
        let one: Float = 1.0
        let two: Float = 2.0
        let t = (one + sqrt5) / two
        let tSquared = t * t
        let denominator: Float = sqrt(one + tSquared)
        let s = radius / denominator
        
        // Pre-calculate values to avoid complex expressions
        let ts = t * s
        let negS = -s
        let negTs = -ts
        let zero: Float = 0.0
        
        var vertices: [SIMD3<Float>] = []
        vertices.append(SIMD3<Float>(negS, ts, zero))
        vertices.append(SIMD3<Float>(s, ts, zero))
        vertices.append(SIMD3<Float>(negS, negTs, zero))
        vertices.append(SIMD3<Float>(s, negTs, zero))
        vertices.append(SIMD3<Float>(zero, negS, ts))
        vertices.append(SIMD3<Float>(zero, s, ts))
        vertices.append(SIMD3<Float>(zero, negS, negTs))
        vertices.append(SIMD3<Float>(zero, s, negTs))
        vertices.append(SIMD3<Float>(ts, zero, negS))
        vertices.append(SIMD3<Float>(ts, zero, s))
        vertices.append(SIMD3<Float>(negTs, zero, negS))
        vertices.append(SIMD3<Float>(negTs, zero, s))
        
        // Normalize vertices to sphere
        for i in 0..<vertices.count {
            vertices[i] = normalize(vertices[i]) * radius
        }
        
        let indices: [UInt16] = [
            0, 11, 5,  0, 5, 1,  0, 1, 7,  0, 7, 10,  0, 10, 11,
            1, 5, 9,  5, 11, 4,  11, 10, 2,  10, 7, 6,  7, 1, 8,
            3, 9, 4,  3, 4, 2,  3, 2, 6,  3, 6, 8,  3, 8, 9,
            4, 9, 5,  2, 4, 11,  6, 2, 10,  8, 6, 7,  9, 8, 1
        ]
        
        // For simplicity, use same indices for edges (can be improved)
        return Mesh(vertices: vertices, indices: indices, edgeIndices: nil)
    }
}
