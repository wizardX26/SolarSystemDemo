## GeometryLab - Solar System Metal Demo

GeometryLab là demo render 3D Hệ Mặt Trời viết bằng Swift + Metal cho iOS, tập trung vào pipeline render cơ bản, tổ chức scene theo node/renderer, và animation quỹ đạo theo thời gian thực.

<p align="center">
  <img src="GeometryLab/SolarSystemDemo.gif" width="400"/>
</p>
 
### Tổng quan nhanh
- Mô phỏng **9 thiên thể**: Sun + 8 hành tinh (`PlanetData.allPlanets`)
- Render **8 quỹ đạo ellipse** (bỏ Sun), mỗi quỹ đạo dùng **128 đỉnh** + 1 đỉnh đóng vòng
- Mục tiêu tốc độ khung hình: **60 FPS** (`MTKView.preferredFramesPerSecond = 60`)
- Camera mặc định: yaw **45°**, pitch **30°**, distance **60**
- Giới hạn zoom: **0.5 -> 100.0**, near plane adaptive từ **0.0001** khi zoom rất gần

### Công nghệ sử dụng
- **Ngôn ngữ**: Swift 5, Metal Shading Language
- **Framework**: UIKit, MetalKit, simd, QuartzCore
- **GPU setup**: `MTLCreateSystemDefaultDevice`, shared `MTLCommandQueue`, default shader library
- **Shader shared types**: `Uniforms` + `BufferIndex` dùng chung Swift/C (`ShaderTypes.h`)

### Render pipeline (theo frame)
- `CADisplayLink` gọi `SceneRenderer.updateAnimation(deltaTime:)` mỗi frame
- Cập nhật orbit + self-rotation cho từng `CelestialBody`
- Tính ma trận `model/view/proj` và ghi vào uniform buffer
- Trong `MetalView.draw(in:)`: clear color + clear depth
- Encode lệnh theo thứ tự: **OrbitPathRenderer -> PlanetRenderer (Sun trước, rồi các hành tinh)**
- Submit `commandBuffer.present(drawable)` và `commit()`

### Kiến trúc mã nguồn hiện tại
- **23 file Swift** (Core, Math, Model, Renderer, Scenes, Celestial)
- **8 file Metal** (5 primitive shaders + 3 utility shaders)
- **6 renderer chính**: `Axis`, `Grid`, `Mesh`, `Triangle`, `Planet`, `OrbitPath`
- Mesh cầu dùng icosahedron base: **12 vertices / 20 faces** trước khi scale theo bán kính hành tinh

### Tương tác
- **Pan**: xoay camera quanh tâm hệ
- **Pinch**: zoom in/out
- Hỗ trợ xoay màn hình (portrait + landscape trên iPhone, full orientations trên iPad)

### Ghi chú
- Dữ liệu hành tinh được scale theo mục tiêu trực quan học tập, không phải tỉ lệ thiên văn tuyệt đối.
- Repo hiện có thêm các renderer/model tổng quát (axis/grid/triangle/mesh) để tái sử dụng cho bài toán hình học 3D khác.
