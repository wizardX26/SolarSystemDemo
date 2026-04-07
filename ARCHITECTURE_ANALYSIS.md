# Phân Tích Kiến Trúc và Kế Hoạch Implementation

## 1. So Sánh Kiến Trúc

### Kiến Trúc Hiện Tại (Modular Architecture)
```
GeometryLab/
├── Core/                    # Core infrastructure
│   ├── BaseRenderer.swift   # Base class cho tất cả renderers
│   ├── GPUDevice.swift      # Singleton quản lý Metal device
│   └── MetalView.swift      # Custom MTKView với delegate
├── Renderer/                # Renderer implementations
│   ├── TriangleRenderer.swift
│   ├── GridRenderer.swift
│   └── AxisRenderer.swift
├── Model/                   # Data models
│   ├── Triangle.swift
│   ├── Axis.swift
│   └── Mesh.swift
├── Math/                    # Math utilities
│   ├── Matrix.swift
│   ├── Transform.swift
│   └── GeometryUtils.swift
├── Scenes/                  # Scene management
│   ├── SceneRenderer.swift
│   └── Nodes/
│       ├── MeshNode.swift
│       ├── AxisNode.swift
│       └── GridNode.swift
└── Shader/                  # Shader files
    ├── Types/
    ├── Primitive/
    └── Utils/
```

### Tài Liệu Hướng Dẫn (Monolithic Approach)
```
3D_triangle/
├── ViewController.swift     # Quản lý tất cả (grid, axis, triangle)
├── TriangleRenderer.swift   # Standalone renderer
├── ShaderTypes.h           # Shared types
└── Shader.metal            # Tất cả shaders trong 1 file
```

## 2. Điểm Khác Biệt Chính

### Ưu Điểm Kiến Trúc Hiện Tại:
1. **Separation of Concerns**: Mỗi layer có trách nhiệm rõ ràng
2. **Reusability**: BaseRenderer có thể tái sử dụng
3. **Maintainability**: Dễ bảo trì và mở rộng
4. **Testability**: Dễ test từng component riêng biệt
5. **Scalability**: Dễ thêm features mới

### Logic Cần Áp Dụng Từ Tài Liệu:
1. **Triangle Geometry**: Tạo triangular pyramid với góc 30 độ
2. **Grid Generation**: Tạo grid 3D với spacing
3. **Axis Rendering**: Render 3 trục X, Y, Z
4. **Camera System**: Spherical coordinates với pan/pinch
5. **Shader Functions**: Vertex và fragment shaders
6. **Matrix Operations**: View, projection, model matrices

## 3. Kế Hoạch Implementation

### Phase 1: Core Infrastructure
- [x] GPUDevice: Singleton quản lý MTLDevice, MTLCommandQueue
- [x] BaseRenderer: Base class với common methods
- [x] MetalView: Custom MTKView với delegate pattern

### Phase 2: Math Utilities
- [x] Matrix.swift: Matrix operations (view, projection, model)
- [x] Transform.swift: Transform utilities
- [x] GeometryUtils.swift: Geometry calculations

### Phase 3: Model Layer
- [x] Triangle.swift: Triangle geometry data
- [x] Axis.swift: Axis geometry data
- [x] Mesh.swift: Generic mesh structure

### Phase 4: Shader Layer
- [x] Triangle.metal: Triangle vertex/fragment shaders
- [x] Grid.metal: Grid vertex/fragment shaders
- [x] Axis.metal: Axis vertex/fragment shaders
- [x] Import ShaderTypes.h trong tất cả shaders

### Phase 5: Renderer Layer
- [x] TriangleRenderer: Kế thừa BaseRenderer
- [x] GridRenderer: Kế thừa BaseRenderer
- [x] AxisRenderer: Kế thừa BaseRenderer

### Phase 6: Scene Layer
- [x] SceneRenderer: Orchestrate tất cả renderers
- [x] Nodes: MeshNode, AxisNode, GridNode

### Phase 7: ViewController
- [x] Setup MetalView
- [x] Gesture handling (pan, pinch)
- [x] Camera management
- [x] Delegate methods

## 4. Chi Tiết Implementation

### 4.1. GPUDevice (Singleton Pattern)
```swift
class GPUDevice {
    static let shared = GPUDevice()
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let library: MTLLibrary
    
    private init() {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!
        library = device.makeDefaultLibrary()!
    }
}
```

### 4.2. BaseRenderer (Base Class)
```swift
class BaseRenderer {
    let device: MTLDevice
    let library: MTLLibrary
    
    init(device: MTLDevice) {
        self.device = device
        self.library = device.makeDefaultLibrary()!
    }
    
    func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4)
    func render(encoder: MTLRenderCommandEncoder)
}
```

### 4.3. TriangleRenderer (Kế Thừa BaseRenderer)
- Setup triangular pyramid geometry
- Create vertex/index buffers
- Setup pipeline states (filled + wireframe)
- Render triangle với viền trắng

### 4.4. GridRenderer (Kế Thừa BaseRenderer)
- Generate grid vertices
- Create vertex buffer
- Setup pipeline state
- Render grid lines

### 4.5. AxisRenderer (Kế Thừa BaseRenderer)
- Generate axis vertices (X, Y, Z)
- Create vertex buffers
- Setup pipeline state
- Render axes với màu khác nhau

### 4.6. SceneRenderer (Orchestrator)
- Quản lý tất cả renderers
- Update uniforms cho tất cả
- Render theo thứ tự: Grid → Axis → Triangle

### 4.7. MetalView (Custom MTKView)
- Setup MTKView properties
- Implement MTKViewDelegate
- Handle drawable size changes

### 4.8. ViewController
- Setup MetalView
- Setup SceneRenderer
- Handle gestures (pan, pinch)
- Manage camera state
- Update uniforms khi cần

## 5. Data Flow

```
ViewController
    ↓
MetalView (MTKViewDelegate)
    ↓
SceneRenderer
    ↓
├── GridRenderer
├── AxisRenderer
└── TriangleRenderer
    ↓
GPUDevice.shared
    ↓
MTLDevice → MTLCommandQueue → MTLRenderCommandEncoder
```

## 6. Shader Organization

### ShaderTypes.h (Shared)
- BufferIndex enum
- Uniforms struct

### Triangle.metal
- vertex_main: Transform vertices
- triangle_fragment_main: Red color
- triangle_edge_fragment_main: White color

### Grid.metal
- vertex_main: Transform vertices
- fragment_main: Green color (dựa trên isAxis flag)

### Axis.metal
- vertex_main: Transform vertices
- fragment_main: Green color (dựa trên isAxis flag)

## 7. Camera System

### Spherical Coordinates
- `cameraRotationY`: Yaw (quay quanh trục Y)
- `cameraRotationX`: Pitch (quay lên/xuống)
- `cameraDistance`: Khoảng cách từ camera đến origin

### Gesture Handling
- **Pan**: Update cameraRotationY và cameraRotationX
- **Pinch**: Update cameraDistance

### Matrix Calculation
- View matrix: Từ spherical coordinates
- Projection matrix: Perspective với FOV 60 độ

## 8. Implementation Order

1. **Core Layer** → Foundation cho tất cả
2. **Math Layer** → Utilities cần thiết
3. **Model Layer** → Data structures
4. **Shader Layer** → GPU code
5. **Renderer Layer** → Render logic
6. **Scene Layer** → Orchestration
7. **ViewController** → UI và interaction

## 9. Best Practices

1. **Error Handling**: Sử dụng `try?` hoặc `guard` cho Metal operations
2. **Memory Management**: Reuse buffers khi có thể
3. **Performance**: Update uniforms chỉ khi cần
4. **Code Organization**: Mỗi file có single responsibility
5. **Naming**: Consistent naming convention

## 10. Testing Strategy

1. Test từng renderer riêng biệt
2. Test camera system
3. Test gesture handling
4. Test shader compilation
5. Test trên device thật (không phải simulator)



