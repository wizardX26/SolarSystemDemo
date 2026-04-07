//
//  ShaderTypes.h
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

#pragma once
#include <simd/simd.h>

typedef enum BufferIndex {
    BufferIndexVertices = 0,
    BufferIndexUniforms = 1
} BufferIndex;

typedef struct {
    matrix_float4x4 model;
    matrix_float4x4 view;
    matrix_float4x4 proj;
    int isAxis;
    vector_float4 axisColor;  // Color for axis (X=red, Y=green, Z=blue)
} Uniforms;
