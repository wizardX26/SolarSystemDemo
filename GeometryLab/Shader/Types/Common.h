//
//  Common.h
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

#pragma once

// Noise
float N11(float s);
float N21(float2 p);
float3 hsv2rgb(float h, float s, float v);

// Gereral Mod
float mod(float a, float b);

// Grid
float grid(float2 p);

// Rotation
metal::float2x2 rot(float radian);

float rand(float2 n);
float3 mod(float3 x, float3 y);
float deg2rad(float num);

