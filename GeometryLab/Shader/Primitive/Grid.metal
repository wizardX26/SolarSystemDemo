//
//  Grid.metal
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
vertex float4 grid_vertex_main(VertexIn v [[stage_in]],
                                constant Uniforms& u [[buffer(BufferIndexUniforms)]]) {
    // Apply transformations: Model → View → Projection
    return u.proj * u.view * u.model * float4(v.position, 1.0);
}

// Fragment shader for grid (green color, darker)
// Also supports gray color for orbit paths via axisColor
fragment float4 grid_fragment_main(constant Uniforms& u [[buffer(BufferIndexUniforms)]]) {
    if (u.isAxis == 1) {
        return float4(0.0, 1.0, 0.0, 1.0);  // Bright green for axis
    } else {
        // Check if axisColor is gray (for orbit paths) - if R, G, B are all around 0.5
        const float grayThreshold = 0.1;
        if (abs(u.axisColor.r - 0.5) < grayThreshold && 
            abs(u.axisColor.g - 0.5) < grayThreshold && 
            abs(u.axisColor.b - 0.5) < grayThreshold) {
            return u.axisColor;  // Use gray color from uniforms (for orbit paths)
        }
        return float4(0.0, 0.7, 0.0, 1.0);   // Darker green for grid
    }
}


