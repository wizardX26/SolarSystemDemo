//
//  Triangle.metal
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

#include <metal_stdlib>
using namespace metal;

#import "../Types/ShaderTypes.h"

// Vertex input structure
struct VertexIn {
    float3 position [[attribute(0)]];
};

// Vertex shader: Transform vertex from world space to clip space
vertex float4 triangle_vertex_main(VertexIn v [[stage_in]],
                                   constant Uniforms& u [[buffer(BufferIndexUniforms)]]) {
    // Apply transformations: Model → View → Projection
    return u.proj * u.view * u.model * float4(v.position, 1.0);
}

// Fragment shader for triangle (red color)
fragment float4 triangle_fragment_main() {
    return float4(1.0, 0.0, 0.0, 1.0);  // RGBA: Red
}

// Fragment shader for triangle edges (white color)
fragment float4 triangle_edge_fragment_main() {
    return float4(1.0, 1.0, 1.0, 1.0);  // RGBA: White
}


