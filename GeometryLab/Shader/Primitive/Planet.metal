//
//  Planet.metal
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
vertex float4 planet_vertex_main(VertexIn v [[stage_in]],
                                 constant Uniforms& u [[buffer(BufferIndexUniforms)]]) {
    // Apply transformations: Model → View → Projection
    return u.proj * u.view * u.model * float4(v.position, 1.0);
}

// Fragment shader for planet (uses color from uniforms)
fragment float4 planet_fragment_main(constant Uniforms& u [[buffer(BufferIndexUniforms)]]) {
    // Use axisColor field to store planet color (reusing existing struct)
    return u.axisColor;  // Planet color
}

