//
//  Axis.metal
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
vertex float4 axis_vertex_main(VertexIn v [[stage_in]],
                               constant Uniforms& u [[buffer(BufferIndexUniforms)]]) {
    // Apply transformations: Model → View → Projection
    return u.proj * u.view * u.model * float4(v.position, 1.0);
}

// Fragment shader for axis (uses color from uniforms: X=red, Y=green, Z=blue)
fragment float4 axis_fragment_main(constant Uniforms& u [[buffer(BufferIndexUniforms)]]) {
    return u.axisColor;  // Use color from uniforms
}


