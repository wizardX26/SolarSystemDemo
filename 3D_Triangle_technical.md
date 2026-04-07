# Hướng Dẫn Chi Tiết: Xây Dựng Ứng Dụng 3D Triangle với Metal

## Mục Lục
1. [Tổng Quan Dự Án](#tổng-quan-dự-án)
2. [Yêu Cầu Hệ Thống](#yêu-cầu-hệ-thống)
3. [Bước 1: Tạo Project Xcode](#bước-1-tạo-project-xcode)
4. [Bước 2: Cấu Hình Project](#bước-2-cấu-hình-project)
5. [Bước 3: Tạo File ShaderTypes.h](#bước-3-tạo-file-shadertypesh)
6. [Bước 4: Tạo File Shader.metal](#bước-4-tạo-file-shadermetal)
7. [Bước 5: Tạo Bridging Header](#bước-5-tạo-bridging-header)
8. [Bước 6: Tạo TriangleRenderer Class](#bước-6-tạo-trianglerenderer-class)
9. [Bước 7: Tạo ViewController](#bước-7-tạo-viewcontroller)
10. [Bước 8: Cấu Hình AppDelegate](#bước-8-cấu-hình-appdelegate)
11. [Bước 9: Cấu Hình Storyboard](#bước-9-cấu-hình-storyboard)
12. [Giải Thích Chi Tiết Các Thành Phần](#giải-thích-chi-tiết-các-thành-phần)
13. [Troubleshooting](#troubleshooting)

---

## Tổng Quan Dự Án

Ứng dụng này là một ứng dụng iOS sử dụng Metal framework để render một hình tam giác 3D (triangular pyramid/tetrahedron) với các tính năng:

- **Render 3D hình tam giác** màu đỏ với viền trắng
- **Hệ thống lưới 3D** (grid) để định hướng không gian
- **Các trục tọa độ** X, Y, Z với màu sắc khác nhau
- **Camera tương tác**: Pan để quay, Pinch để zoom
- **Depth testing** để hiển thị đúng thứ tự các đối tượng 3D

---

## Yêu Cầu Hệ Thống

- **macOS**: 10.15 trở lên
- **Xcode**: 12.0 trở lên
- **iOS Deployment Target**: 13.0 trở lên
- **Swift**: 5.0 trở lên
- **Thiết bị**: iPhone/iPad hỗ trợ Metal (hầu hết thiết bị từ iPhone 5s trở lên)

---

## Bước 1: Tạo Project Xcode

1. Mở **Xcode**
2. Chọn **File → New → Project**
3. Chọn **iOS → App**
4. Điền thông tin:
   - **Product Name**: `3D_triangle`
   - **Interface**: Storyboard
   - **Language**: Swift
   - **Use Core Data**: Không chọn
5. Chọn thư mục lưu project và nhấn **Create**

---

## Bước 2: Cấu Hình Project

### 2.1. Thêm Metal Framework

1. Chọn project trong Navigator
2. Chọn target **3D_triangle**
3. Vào tab **General**
4. Trong phần **Frameworks, Libraries, and Embedded Content**, nhấn **+**
5. Thêm **Metal.framework** và **MetalKit.framework**
6. Đảm bảo **Embed** được set là **Do Not Embed**

### 2.2. Cấu Hình Build Settings

1. Vào tab **Build Settings**
2. Tìm **Swift Compiler - General**
3. Đảm bảo **Swift Language Version** là **Swift 5**
4. Tìm **iOS Deployment Target** và set là **13.0** hoặc cao hơn

---

## Bước 3: Tạo File ShaderTypes.h

File này định nghĩa các cấu trúc dữ liệu được chia sẻ giữa Swift và Metal shaders.

### 3.1. Tạo File

1. Right-click vào thư mục `3D_triangle` trong Navigator
2. Chọn **New File...**
3. Chọn **iOS → Source → Header File**
4. Đặt tên: `ShaderTypes.h`
5. Nhấn **Create**

### 3.2. Nội Dung File

```c
//
//  ShaderTypes.h
//  3D_triangle
//

#pragma once
#include <simd/simd.h>

// Enum định nghĩa các buffer index
typedef enum BufferIndex {
    BufferIndexVertices = 0,  // Buffer chứa vertex data
    BufferIndexUniforms = 1   // Buffer chứa uniform data (matrices)
} BufferIndex;

// Cấu trúc chứa các ma trận transformation và flags
typedef struct {
    matrix_float4x4 model;  // Model matrix (transform object)
    matrix_float4x4 view;   // View matrix (camera position)
    matrix_float4x4 proj;   // Projection matrix (perspective)
    int isAxis;             // Flag để phân biệt grid và axis
} Uniforms;
```

### 3.3. Giải Thích

- **simd/simd.h**: Thư viện SIMD của Apple cung cấp các kiểu dữ liệu vector và matrix
- **BufferIndex**: Enum định nghĩa vị trí buffer trong shader
- **Uniforms**: Struct chứa các ma trận 4x4 cho phép biến đổi 3D và flag để phân biệt loại đối tượng

---

## Bước 4: Tạo File Shader.metal

File này chứa các shader functions chạy trên GPU.

### 4.1. Tạo File

1. Right-click vào thư mục `3D_triangle`
2. Chọn **New File...**
3. Chọn **iOS → Source → Metal File**
4. Đặt tên: `Shader.metal`
5. Nhấn **Create**

### 4.2. Nội Dung File

```metal
//
//  Shader.metal
//  3D_triangle
//

#include <metal_stdlib>
using namespace metal;

#import "ShaderTypes.h"

// Cấu trúc input cho vertex shader
struct VertexIn {
    float3 position [[attribute(0)]];  // Vị trí vertex (x, y, z)
};

// Vertex Shader: Transform vertex từ world space sang clip space
vertex float4 vertex_main(VertexIn v [[stage_in]],
                          constant Uniforms& u [[buffer(BufferIndexUniforms)]])
{
    // Áp dụng các transformation: Model → View → Projection
    return u.proj * u.view * u.model * float4(v.position, 1.0);
}

// Fragment Shader cho grid và axis
fragment float4 fragment_main(constant Uniforms& u [[buffer(BufferIndexUniforms)]])
{
    if (u.isAxis == 1) {
        return float4(0.0, 1.0, 0.0, 1.0);  // Màu xanh lá cho axis
    } else {
        return float4(0.0, 0.7, 0.0, 1.0);   // Màu xanh lá đậm cho grid
    }
}

// Fragment Shader cho tam giác (màu đỏ)
fragment float4 triangle_fragment_main()
{
    return float4(1.0, 0.0, 0.0, 1.0);  // RGBA: Đỏ
}

// Fragment Shader cho viền tam giác (màu trắng)
fragment float4 triangle_edge_fragment_main()
{
    return float4(1.0, 1.0, 1.0, 1.0);  // RGBA: Trắng
}
```

### 4.3. Giải Thích

- **vertex_main**: 
  - Nhận vertex position và uniform buffer
  - Áp dụng transformation: `proj × view × model × position`
  - Trả về vị trí trong clip space (tọa độ sau projection)

- **fragment_main**: 
  - Xác định màu sắc cho grid và axis dựa trên flag `isAxis`

- **triangle_fragment_main**: 
  - Trả về màu đỏ cho tam giác

- **triangle_edge_fragment_main**: 
  - Trả về màu trắng cho viền tam giác

---

## Bước 5: Tạo Bridging Header

Bridging header cho phép Swift sử dụng các file C/Objective-C.

### 5.1. Tạo File

1. Right-click vào thư mục `3D_triangle`
2. Chọn **New File...**
3. Chọn **iOS → Source → Header File**
4. Đặt tên: `Bridging-Header.h`
5. Nhấn **Create**

### 5.2. Nội Dung File

```c
//
//  Bridging-Header.h
//  3D_triangle
//

#import "ShaderTypes.h"
```

### 5.3. Cấu Hình Build Settings

1. Vào **Build Settings**
2. Tìm **Swift Compiler - General**
3. Tìm **Objective-C Bridging Header**
4. Đặt giá trị: `3D_triangle/Bridging-Header.h`

---

## Bước 6: Tạo TriangleRenderer Class

Class này quản lý việc render hình tam giác 3D.

### 6.1. Tạo File

1. Right-click vào thư mục `3D_triangle`
2. Chọn **New File...**
3. Chọn **iOS → Source → Swift File**
4. Đặt tên: `TriangleRenderer.swift`
5. Nhấn **Create**

### 6.2. Nội Dung File

```swift
//
//  TriangleRenderer.swift
//  3D_triangle
//

import UIKit
import MetalKit

class TriangleRenderer {
    var device: MTLDevice!
    var triangleVertexBuffer: MTLBuffer!
    var triangleIndexBuffer: MTLBuffer!
    var triangleEdgeIndexBuffer: MTLBuffer!
    var triangleUniformBuffer: MTLBuffer!
    var trianglePipelineState: MTLRenderPipelineState!
    var triangleEdgePipelineState: MTLRenderPipelineState!
    
    // Hình hộp tam giác vertices (4 điểm: 1 đỉnh trên + 3 đỉnh đáy)
    var triangleVertices: [SIMD3<Float>] = []
    var triangleIndices: [UInt16] = []
    var triangleEdgeIndices: [UInt16] = []
    
    init(device: MTLDevice) {
        self.device = device
        setupTriangularPrism()
        setupPipeline()
    }
    
    func setupTriangularPrism() {
        // Tạo hình hộp tam giác (triangular pyramid) với góc đỉnh 30 độ ở tất cả các mặt
        let angle30Deg = Float.pi / 6.0  // 30 độ
        let baseRadius: Float = 1.5       // Bán kính mặt đáy
        let baseY: Float = 0.0           // Độ cao mặt đáy
        
        // 3 đỉnh của mặt đáy tam giác đều, cách đều nhau 120 độ
        var baseVertices: [SIMD3<Float>] = []
        for i in 0..<3 {
            let angle = Float(i) * 2.0 * Float.pi / 3.0
            let x = baseRadius * cos(angle)
            let z = baseRadius * sin(angle)
            baseVertices.append(SIMD3<Float>(x, baseY, z))
        }
        
        // Tính toán độ cao đỉnh trên để đảm bảo góc đỉnh = 30 độ
        let baseEdgeLength = baseRadius * sqrt(3.0)
        let halfEdge = baseEdgeLength / 2.0
        let height = halfEdge / tan(angle30Deg / 2.0)  // tan(15°)
        
        // Đỉnh trên (apex) nằm ở trung tâm mặt đáy và cao hơn
        let apex = SIMD3<Float>(0, height, 0)
        
        // Tất cả vertices: đỉnh trên + 3 đỉnh đáy
        triangleVertices = [apex] + baseVertices
        
        // Tạo 3 mặt tam giác (3 mặt bên của hình chóp)
        triangleIndices = [
            0, 1, 2,  // Mặt 1: đỉnh trên + đỉnh đáy 0 + đỉnh đáy 1
            0, 2, 3,  // Mặt 2: đỉnh trên + đỉnh đáy 1 + đỉnh đáy 2
            0, 3, 1   // Mặt 3: đỉnh trên + đỉnh đáy 2 + đỉnh đáy 0
        ]
        
        // Tạo Metal buffers
        triangleVertexBuffer = device.makeBuffer(bytes: triangleVertices,
                                                length: MemoryLayout<SIMD3<Float>>.stride * triangleVertices.count,
                                                options: [])
        
        triangleIndexBuffer = device.makeBuffer(bytes: triangleIndices,
                                               length: MemoryLayout<UInt16>.stride * triangleIndices.count,
                                               options: [])
        
        // Tạo edge indices cho viền đen
        triangleEdgeIndices = [
            // 3 cạnh từ đỉnh (0) đến các đỉnh đáy
            0, 1,  // đỉnh -> đỉnh đáy 1
            0, 2,  // đỉnh -> đỉnh đáy 2
            0, 3,  // đỉnh -> đỉnh đáy 3
            // 3 cạnh của mặt đáy tam giác
            1, 2,  // đỉnh đáy 1 -> đỉnh đáy 2
            2, 3,  // đỉnh đáy 2 -> đỉnh đáy 3
            3, 1   // đỉnh đáy 3 -> đỉnh đáy 1
        ]
        
        triangleEdgeIndexBuffer = device.makeBuffer(bytes: triangleEdgeIndices,
                                                    length: MemoryLayout<UInt16>.stride * triangleEdgeIndices.count,
                                                    options: [])
    }
    
    func setupPipeline() {
        let library = device.makeDefaultLibrary()
        
        // Setup vertex descriptor cho tam giác
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // Pipeline state cho tam giác filled
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library?.makeFunction(name: "vertex_main")
        descriptor.fragmentFunction = library?.makeFunction(name: "triangle_fragment_main")
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        trianglePipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)
        
        // Pipeline state cho viền tam giác
        let edgeDescriptor = MTLRenderPipelineDescriptor()
        edgeDescriptor.vertexFunction = library?.makeFunction(name: "vertex_main")
        edgeDescriptor.fragmentFunction = library?.makeFunction(name: "triangle_edge_fragment_main")
        edgeDescriptor.vertexDescriptor = vertexDescriptor
        edgeDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        edgeDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        triangleEdgePipelineState = try! device.makeRenderPipelineState(descriptor: edgeDescriptor)
    }
    
    func updateUniforms(view: matrix_float4x4, proj: matrix_float4x4, model: matrix_float4x4? = nil) {
        let modelMatrix = model ?? simd_float4x4(1) // Identity matrix
        var u = Uniforms(
            model: modelMatrix,
            view: view,
            proj: proj,
            isAxis: 0
        )
        
        if triangleUniformBuffer == nil {
            triangleUniformBuffer = device.makeBuffer(bytes: &u,
                                                      length: MemoryLayout<Uniforms>.stride,
                                                      options: [])
        } else {
            let contents = triangleUniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
            contents.pointee = u
        }
    }
    
    func render(encoder: MTLRenderCommandEncoder) {
        // Vẽ tam giác đỏ (filled)
        encoder.setRenderPipelineState(trianglePipelineState)
        encoder.setVertexBuffer(triangleVertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(triangleUniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(triangleUniformBuffer, offset: 0, index: 1)
        
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: triangleIndices.count,
                                      indexType: .uint16,
                                      indexBuffer: triangleIndexBuffer,
                                      indexBufferOffset: 0)
        
        // Vẽ viền trắng (wireframe)
        encoder.setRenderPipelineState(triangleEdgePipelineState)
        encoder.setVertexBuffer(triangleVertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(triangleUniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(triangleUniformBuffer, offset: 0, index: 1)
        
        encoder.drawIndexedPrimitives(type: .line,
                                      indexCount: triangleEdgeIndices.count,
                                      indexType: .uint16,
                                      indexBuffer: triangleEdgeIndexBuffer,
                                      indexBufferOffset: 0)
    }
}
```

### 6.3. Giải Thích

- **setupTriangularPrism()**: 
  - Tạo 4 vertices (1 đỉnh trên + 3 đỉnh đáy)
  - Tính toán vị trí dựa trên góc 30 độ
  - Tạo indices cho 3 mặt tam giác
  - Tạo edge indices cho viền

- **setupPipeline()**: 
  - Tạo 2 pipeline states: một cho tam giác filled, một cho viền
  - Cấu hình vertex descriptor để Metal biết cách đọc vertex data

- **updateUniforms()**: 
  - Cập nhật các ma trận transformation vào uniform buffer

- **render()**: 
  - Vẽ tam giác filled trước
  - Sau đó vẽ viền lên trên

---

## Bước 7: Tạo ViewController

ViewController là nơi quản lý toàn bộ rendering và tương tác.

### 7.1. Tạo File

1. Xóa file `ViewController.swift` mặc định (nếu có)
2. Tạo file mới: **New File → Swift File**
3. Đặt tên: `ViewController.swift`

### 7.2. Nội Dung File (Phần 1: Khai Báo và Setup)

```swift
//
//  ViewController.swift
//  3D_triangle
//

import UIKit
import MetalKit

final class ViewController: UIViewController, MTKViewDelegate {
    
    // MARK: - Properties
    
    var metalView: MTKView!
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var depthStencilState: MTLDepthStencilState!
    
    // Triangle renderer
    var triangleRenderer: TriangleRenderer!
    
    // Camera rotation
    var cameraRotationY: Float = 0.0  // Yaw (quay quanh trục Y)
    var cameraRotationX: Float = 0.0  // Pitch (quay lên/xuống)
    var cameraDistance: Float = 8.0    // Khoảng cách từ camera đến gốc tọa độ
    
    // Buffers
    var gridVertexBuffer: MTLBuffer!
    var axisXVertexBuffer: MTLBuffer!
    var axisYVertexBuffer: MTLBuffer!
    var axisZVertexBuffer: MTLBuffer!
    var gridUniformBuffer: MTLBuffer!
    var axisUniformBuffer: MTLBuffer!
    
    // Grid parameters
    let gridSize: Float = 33.0
    let gridSpacing: Float = 0.33
    
    var gridVertices: [SIMD3<Float>] = []
    var axisXVertices: [SIMD3<Float>] = []
    var axisYVertices: [SIMD3<Float>] = []
    var axisZVertices: [SIMD3<Float>] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        generateGridVertices()
        setupMetal()
        setupPipeline()
        setupGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        metalView.frame = view.bounds
        setupBuffers()
    }
    
    // MARK: - Metal Setup
    
    func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()

        metalView = MTKView(frame: view.bounds, device: device)
        metalView.delegate = self
        metalView.clearColor = MTLClearColorMake(0.1, 0.1, 0.12, 1.0)
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.preferredFramesPerSecond = 60
        metalView.isUserInteractionEnabled = true
        view.addSubview(metalView)
        
        triangleRenderer = TriangleRenderer(device: device)
    }
    
    func setupPipeline() {
        let library = device.makeDefaultLibrary()
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library?.makeFunction(name: "vertex_main")
        descriptor.fragmentFunction = library?.makeFunction(name: "fragment_main")
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = .depth32Float

        pipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)

        let depthDesc = MTLDepthStencilDescriptor()
        depthDesc.depthCompareFunction = .less
        depthDesc.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthDesc)
    }
}
```

### 7.3. Nội Dung File (Phần 2: Grid Generation)

```swift
    // MARK: - Grid Generation
    
    func generateGridVertices() {
        gridVertices.removeAll()
        axisXVertices.removeAll()
        axisYVertices.removeAll()
        axisZVertices.removeAll()
        
        // Tạo các đường song song với trục X (theo chiều Z)
        let halfSize = gridSize / 2.0
        var z = -halfSize
        while z <= halfSize {
            gridVertices.append(SIMD3<Float>(-halfSize, 0, z))
            gridVertices.append(SIMD3<Float>(halfSize, 0, z))
            z += gridSpacing
        }
        
        // Tạo các đường song song với trục Z (theo chiều X)
        var x = -halfSize
        while x <= halfSize {
            gridVertices.append(SIMD3<Float>(x, 0, -halfSize))
            gridVertices.append(SIMD3<Float>(x, 0, halfSize))
            x += gridSpacing
        }
        
        // Tạo các trục tọa độ
        // Trục X
        axisXVertices.append(SIMD3<Float>(0, 0, 0))
        axisXVertices.append(SIMD3<Float>(gridSize, 0, 0))
        axisXVertices.append(SIMD3<Float>(0, 0, 0))
        axisXVertices.append(SIMD3<Float>(-gridSize, 0, 0))
        
        // Trục Z
        axisZVertices.append(SIMD3<Float>(0, 0, 0))
        axisZVertices.append(SIMD3<Float>(0, 0, gridSize))
        axisZVertices.append(SIMD3<Float>(0, 0, 0))
        axisZVertices.append(SIMD3<Float>(0, 0, -gridSize))
        
        // Trục Y
        axisYVertices.append(SIMD3<Float>(0, 0, 0))
        axisYVertices.append(SIMD3<Float>(0, gridSize, 0))
    }
    
    func setupBuffers() {
        gridVertexBuffer = device.makeBuffer(bytes: gridVertices,
                                             length: MemoryLayout<SIMD3<Float>>.stride * gridVertices.count,
                                             options: [])
        
        axisXVertexBuffer = device.makeBuffer(bytes: axisXVertices,
                                             length: MemoryLayout<SIMD3<Float>>.stride * axisXVertices.count,
                                             options: [])
        
        axisYVertexBuffer = device.makeBuffer(bytes: axisYVertices,
                                             length: MemoryLayout<SIMD3<Float>>.stride * axisYVertices.count,
                                             options: [])
        
        axisZVertexBuffer = device.makeBuffer(bytes: axisZVertices,
                                             length: MemoryLayout<SIMD3<Float>>.stride * axisZVertices.count,
                                             options: [])
        
        updateUniforms()
    }
```

### 7.4. Nội Dung File (Phần 3: Gestures và Camera)

```swift
    // MARK: - Gestures
    
    func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        metalView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        metalView.addGestureRecognizer(pinchGesture)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: metalView)
        
        let sensitivity: Float = 0.01
        cameraRotationY += Float(translation.x) * sensitivity
        cameraRotationX += Float(translation.y) * sensitivity
        
        // Giới hạn pitch
        cameraRotationX = max(-Float.pi / 2 + 0.1, min(Float.pi / 2 - 0.1, cameraRotationX))
        
        gesture.setTranslation(.zero, in: metalView)
        updateUniforms()
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            let scale = Float(gesture.scale)
            cameraDistance *= (1.0 / scale)
            cameraDistance = max(2.0, min(20.0, cameraDistance))
            
            gesture.scale = 1.0
            updateUniforms()
        }
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        updateUniforms()
    }
```

### 7.5. Nội Dung File (Phần 4: Matrix và Rendering)

```swift
    // MARK: - Matrix Operations
    
    func updateUniforms() {
        let aspect = Float(metalView.bounds.width / max(metalView.bounds.height, 1.0))
        
        // Tính toán vị trí camera dựa trên rotation
        let eyeX = cameraDistance * cos(cameraRotationX) * sin(cameraRotationY)
        let eyeY = cameraDistance * sin(cameraRotationX)
        let eyeZ = cameraDistance * cos(cameraRotationX) * cos(cameraRotationY)
        
        let eye = SIMD3<Float>(eyeX, eyeY, eyeZ)
        let center = SIMD3<Float>(0, 0, 0)
        let up = SIMD3<Float>(0, 1, 0)
        
        let viewMatrix = matrix_float4x4(eye: eye, center: center, up: up)
        let projMatrix = matrix_float4x4(perspectiveDegrees: 60,
                                         aspect: aspect,
                                         near: 0.1, far: 100)
        
        var gridU = Uniforms(
            model: matrix_float4x4(rotationY: 0),
            view: viewMatrix,
            proj: projMatrix,
            isAxis: 0
        )
        
        var axisU = gridU
        axisU.isAxis = 1
        
        if gridUniformBuffer == nil {
            gridUniformBuffer = device.makeBuffer(bytes: &gridU,
                                                  length: MemoryLayout<Uniforms>.stride,
                                                  options: [])
            axisUniformBuffer = device.makeBuffer(bytes: &axisU,
                                                 length: MemoryLayout<Uniforms>.stride,
                                                 options: [])
        } else {
            let gridContents = gridUniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
            gridContents.pointee = gridU
            let axisContents = axisUniformBuffer.contents().bindMemory(to: Uniforms.self, capacity: 1)
            axisContents.pointee = axisU
        }
        
        triangleRenderer.updateUniforms(view: viewMatrix, proj: projMatrix)
    }
    
    func matrix_float4x4(rotationY angle: Float) -> matrix_float4x4 {
        let c = cos(angle)
        let s = sin(angle)
        return simd.matrix_float4x4(
            SIMD4<Float>(c, 0, s, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(-s, 0, c, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    func matrix_float4x4(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> matrix_float4x4 {
        let forward = normalize(center - eye)
        let right = normalize(cross(forward, up))
        let upCorrected = cross(right, forward)
        
        return simd.matrix_float4x4(
            SIMD4<Float>(right.x, upCorrected.x, -forward.x, 0),
            SIMD4<Float>(right.y, upCorrected.y, -forward.y, 0),
            SIMD4<Float>(right.z, upCorrected.z, -forward.z, 0),
            SIMD4<Float>(-dot(right, eye), -dot(upCorrected, eye), dot(forward, eye), 1)
        )
    }
    
    func matrix_float4x4(perspectiveDegrees fov: Float, aspect: Float, near: Float, far: Float) -> matrix_float4x4 {
        let f = 1.0 / tan(fov * .pi / 180.0 / 2.0)
        let range = far - near
        
        return simd.matrix_float4x4(
            SIMD4<Float>(f / aspect, 0, 0, 0),
            SIMD4<Float>(0, f, 0, 0),
            SIMD4<Float>(0, 0, -(far + near) / range, -1),
            SIMD4<Float>(0, 0, -(2 * far * near) / range, 0)
        )
    }
    
    // MARK: - Rendering
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        encoder.setRenderPipelineState(pipelineState)
        encoder.setDepthStencilState(depthStencilState)
        
        // Vẽ grid
        encoder.setVertexBuffer(gridVertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(gridUniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(gridUniformBuffer, offset: 0, index: 1)
        encoder.drawPrimitives(type: .line,
                               vertexStart: 0,
                               vertexCount: gridVertices.count)
        
        // Vẽ các trục
        encoder.setVertexBuffer(axisUniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(axisUniformBuffer, offset: 0, index: 1)
        
        // Trục X
        encoder.setVertexBuffer(axisXVertexBuffer, offset: 0, index: 0)
        for _ in 0..<5 {
            encoder.drawPrimitives(type: .line,
                                   vertexStart: 0,
                                   vertexCount: axisXVertices.count)
        }
        
        // Trục Z
        encoder.setVertexBuffer(axisZVertexBuffer, offset: 0, index: 0)
        for _ in 0..<5 {
            encoder.drawPrimitives(type: .line,
                                   vertexStart: 0,
                                   vertexCount: axisZVertices.count)
        }
        
        // Trục Y
        encoder.setVertexBuffer(axisYVertexBuffer, offset: 0, index: 0)
        for _ in 0..<3 {
            encoder.drawPrimitives(type: .line,
                                   vertexStart: 0,
                                   vertexCount: axisYVertices.count)
        }
        
        // Vẽ tam giác
        triangleRenderer.render(encoder: encoder)
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
```

---

## Bước 8: Cấu Hình AppDelegate

### 8.1. Nội Dung File

```swift
//
//  AppDelegate.swift
//  3D_triangle
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window?.makeKeyAndVisible()
        return true
    }
}
```

---

## Bước 9: Cấu Hình Storyboard

### 9.1. Cấu Hình Main.storyboard

1. Mở `Main.storyboard`
2. Xóa ViewController mặc định (nếu có)
3. Kéo một **View Controller** mới vào storyboard
4. Chọn View Controller, vào **Identity Inspector**
5. Đặt **Class** là `ViewController`
6. Chọn **Is Initial View Controller**

### 9.2. Cấu Hình AppDelegate

1. Mở `AppDelegate.swift`
2. Đảm bảo có property `window`
3. Trong `didFinishLaunchingWithOptions`, thêm:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    window?.rootViewController = storyboard.instantiateInitialViewController()
    window?.makeKeyAndVisible()
    return true
}
```

---

## Giải Thích Chi Tiết Các Thành Phần

### 1. Metal Pipeline

**Render Pipeline** là chuỗi các bước xử lý để render một frame:

1. **Vertex Shader**: Transform vertices từ world space sang clip space
2. **Rasterization**: Chuyển đổi primitives thành fragments (pixels)
3. **Fragment Shader**: Tính toán màu sắc cho mỗi pixel
4. **Depth Testing**: Kiểm tra độ sâu để xác định pixel nào được hiển thị

### 2. Coordinate Systems

- **World Space**: Tọa độ của đối tượng trong thế giới 3D
- **View Space**: Tọa độ sau khi áp dụng view matrix (từ camera)
- **Clip Space**: Tọa độ sau khi áp dụng projection matrix (chuẩn hóa về -1 đến 1)

### 3. Transformation Matrices

- **Model Matrix**: Transform từ object space sang world space
- **View Matrix**: Transform từ world space sang view space (camera)
- **Projection Matrix**: Transform từ view space sang clip space (perspective)

### 4. Camera System

Camera sử dụng **spherical coordinates**:
- `cameraRotationY` (yaw): Quay quanh trục Y
- `cameraRotationX` (pitch): Quay lên/xuống
- `cameraDistance`: Khoảng cách từ camera đến gốc tọa độ

### 5. Depth Testing

Depth testing đảm bảo các đối tượng gần camera được vẽ lên trên các đối tượng xa hơn.

---

## Troubleshooting

### Lỗi: "Shader function not found"

**Nguyên nhân**: Shader function name không khớp giữa Swift và Metal file.

**Giải pháp**: 
- Kiểm tra tên function trong `Shader.metal`
- Đảm bảo tên trong `makeFunction(name:)` khớp chính xác

### Lỗi: "Buffer index out of range"

**Nguyên nhân**: Buffer index không khớp với shader.

**Giải pháp**:
- Kiểm tra `BufferIndex` enum trong `ShaderTypes.h`
- Đảm bảo index trong `setVertexBuffer` khớp với shader

### Lỗi: "Bridging header not found"

**Nguyên nhân**: Đường dẫn bridging header không đúng.

**Giải pháp**:
- Vào Build Settings → Swift Compiler - General
- Đặt **Objective-C Bridging Header** là `3D_triangle/Bridging-Header.h`

### Lỗi: "Metal device not available"

**Nguyên nhân**: Thiết bị không hỗ trợ Metal hoặc simulator.

**Giải pháp**:
- Chạy trên thiết bị thật (không phải simulator)
- Kiểm tra thiết bị hỗ trợ Metal (iPhone 5s trở lên)

### Triangle không hiển thị

**Nguyên nhân**: Có thể do camera quá xa hoặc triangle quá nhỏ.

**Giải pháp**:
- Kiểm tra `cameraDistance` (mặc định 8.0)
- Kiểm tra kích thước triangle trong `setupTriangularPrism()`

### Grid không hiển thị

**Nguyên nhân**: Grid vertices chưa được tạo hoặc buffer chưa được setup.

**Giải pháp**:
- Đảm bảo `generateGridVertices()` được gọi trong `viewDidLoad()`
- Đảm bảo `setupBuffers()` được gọi trong `viewDidLayoutSubviews()`

---

## Tổng Kết

Sau khi hoàn thành tất cả các bước trên, bạn sẽ có một ứng dụng iOS hoàn chỉnh với:

✅ Render 3D hình tam giác với Metal  
✅ Hệ thống grid và trục tọa độ  
✅ Camera tương tác (pan và pinch)  
✅ Depth testing cho rendering chính xác  
✅ Shader pipeline tối ưu  

Ứng dụng này là nền tảng tốt để phát triển các ứng dụng 3D phức tạp hơn với Metal!

---

## Tài Liệu Tham Khảo

- [Apple Metal Documentation](https://developer.apple.com/metal/)
- [Metal Shading Language Specification](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf)
- [SIMD Framework](https://developer.apple.com/documentation/simd)

---

**Chúc bạn thành công!** 🚀
