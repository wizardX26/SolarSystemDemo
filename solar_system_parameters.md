# Solar System Simulation Parameters (Metal -- Apple GPU)

## 1. Physical & Visual Parameters

### 1.1 Orbit Radius

  Planet    Orbit Radius (units)
  --------- ----------------------
  Mercury   4
  Venus     7
  Earth     10
  Mars      15
  Jupiter   25
  Saturn    30
  Uranus    38
  Neptune   45

### 1.2 Planet Radius

  Planet    Radius
  --------- --------
  Sun       2.5
  Earth     1.0
  Mercury   0.3
  Venus     0.9
  Mars      0.7
  Jupiter   1.8
  Saturn    1.6
  Uranus    1.3
  Neptune   1.2

### 1.3 Orbit Speed (radians/sec)

  Planet    Orbit Speed
  --------- -------------
  Mercury   1.6
  Venus     1.2
  Earth     1.0
  Mars      0.8
  Jupiter   0.5
  Saturn    0.4
  Uranus    0.3
  Neptune   0.2

### 1.4 Rotation Speed (self-spin)

-   Earth: \~2.0 rad/s\
-   Others: scaled appropriately

### 1.5 Tilt (axis tilt)

-   Earth: 23.5° (0.41 rad)
-   Mars: 25°
-   Uranus: 98°

------------------------------------------------------------------------

## 2. GPU / Metal Parameters

### 2.1 Mesh Requirements

-   Sphere mesh reused for all planets.
-   32×32 subdivisions recommended.
-   Vertex count \~1024--2048.

### 2.2 Planet Uniforms

    struct PlanetUniforms {
        var modelMatrix: float4x4
        var normalMatrix: float3x3
        var color: SIMD3<Float>
    }

### 2.3 Camera Uniforms

    struct CameraUniforms {
        var viewMatrix: float4x4
        var projectionMatrix: float4x4
    }

### 2.4 Light Data

    struct Light {
        var position: SIMD3<Float>
        var color: SIMD3<Float>
        var intensity: Float
    }

### 2.5 Pipeline Setup

-   vertex_main
-   fragment_main
-   depth32Float
-   color pixel format from MTKView

------------------------------------------------------------------------

## 3. Planet Model

    class PlanetModel {
        var radius: Float
        var orbitRadius: Float
        var orbitSpeed: Float
        var rotationSpeed: Float
        var tilt: Float

        var orbitAngle: Float = 0
        var rotationAngle: Float = 0
    }

### Update function

    func update(deltaTime: Float) {
        orbitAngle += orbitSpeed * deltaTime
        rotationAngle += rotationSpeed * deltaTime
    }

### Model matrix

    func modelMatrix() -> float4x4 {
        return float4x4(translation: [
            orbitRadius * cos(orbitAngle),
            0,
            orbitRadius * sin(orbitAngle)
        ])
        * float4x4(rotation: tilt, axis: [1,0,0])
        * float4x4(rotationY: rotationAngle)
        * float4x4(scaling: radius)
    }

------------------------------------------------------------------------

## 4. GPU Frame Update Flow

1.  Update each planet model.
2.  Generate modelMatrix + normalMatrix.
3.  Upload uniforms to GPU.
4.  Upload camera uniforms.
5.  Bind mesh.
6.  Draw each planet.

```{=html}
<!-- -->
```
    for planet in planets {
        planet.update(deltaTime)
        var uniforms = PlanetUniforms(...)
        encoder.setVertexBytes(&uniforms, ...)
        mesh.draw(encoder)
    }

------------------------------------------------------------------------

## 5. Ready for Implementation

You can now implement SceneRenderer.swift, PlanetModel.swift, and Metal
shaders using these parameters.
