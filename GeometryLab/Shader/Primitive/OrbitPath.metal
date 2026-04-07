//
//  OrbitPath.metal
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
// Reuse grid vertex shader logic
vertex float4 orbit_path_vertex_main(VertexIn v [[stage_in]],
                                     constant Uniforms& u [[buffer(BufferIndexUniforms)]]) {
    // Apply transformations: Model → View → Projection
    return u.proj * u.view * u.model * float4(v.position, 1.0);
}

// Fragment shader for orbit path (gray color)
// Uses axisColor from uniforms to get gray color
fragment float4 orbit_path_fragment_main(constant Uniforms& u [[buffer(BufferIndexUniforms)]]) {
    // Return gray color from axisColor field
    return u.axisColor;  // Gray (0.5, 0.5, 0.5, 1.0)
}

