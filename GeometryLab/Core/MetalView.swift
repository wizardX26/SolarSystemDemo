//
//  MetalView.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import Metal
import MetalKit
import simd

final class MetalView: MTKView {
    var sceneRenderer: SceneRenderer?
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device ?? GPUDevice.shared.device)
        setupView()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        device = GPUDevice.shared.device
        print("MetalView: Initialized from storyboard, device: \(device?.name ?? "nil")")
        setupView()
        print("MetalView: Setup completed, delegate set: \(delegate != nil)")
    }
    
    private func setupView() {
        delegate = self
        clearColor = MTLClearColorMake(0.1, 0.1, 0.12, 1.0)
        colorPixelFormat = .bgra8Unorm
        depthStencilPixelFormat = .depth32Float
        preferredFramesPerSecond = 60
        isUserInteractionEnabled = true
        enableSetNeedsDisplay = false  // Enable automatic rendering
        autoResizeDrawable = true
    }
}

extension MetalView: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // This is called automatically when the view size changes (including rotation)
        print("MetalView: Drawable size will change to \(size)")
        sceneRenderer?.setViewSize(size)
        
        // Also update based on bounds in case there's any discrepancy
        DispatchQueue.main.async {
            if let renderer = self.sceneRenderer {
                renderer.setViewSize(view.bounds.size)
            }
        }
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let sceneRenderer = sceneRenderer else {
            // Debug: Log why rendering is skipped
            if view.currentDrawable == nil {
                print("MetalView: draw() skipped - no currentDrawable")
            } else if view.currentRenderPassDescriptor == nil {
                print("MetalView: draw() skipped - no renderPassDescriptor")
            } else if sceneRenderer == nil {
                print("MetalView: draw() skipped - no sceneRenderer")
            }
            return
        }
        
        // Ensure view size is set
        if sceneRenderer.viewSize.width == 0 || sceneRenderer.viewSize.height == 0 {
            sceneRenderer.setViewSize(view.bounds.size)
        }
        
        // Clear color attachment
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = clearColor
        
        // Clear depth buffer
        descriptor.depthAttachment?.loadAction = .clear
        descriptor.depthAttachment?.clearDepth = 1.0
        
        sceneRenderer.render(descriptor: descriptor, drawable: drawable)
    }
}
