//
//  ViewController.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    @IBOutlet weak var mtkView: MetalView!
    
    var sceneRenderer: SceneRenderer!
    
    // UI Controls
    var rotationSlider1: UISlider!
    var rotationSlider2: UISlider!
    var scaleSlider1: UISlider!
    var scaleSlider2: UISlider!
    
    // Animation
    var displayLink: CADisplayLink?
    var lastTimestamp: CFTimeInterval = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        setupGestures()
        setupUI()
        startAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let metalView = mtkView {
            metalView.frame = view.bounds
            // Update view size after layout (handles rotation)
            if sceneRenderer != nil {
                sceneRenderer.setViewSize(metalView.bounds.size)
            }
        }
    }
    
    // MARK: - Rotation Support
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Support all orientations except upside down on iPhone
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.portrait, .landscapeLeft, .landscapeRight]
        } else {
            // iPad supports all orientations
            return .all
        }
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Update view size when orientation changes
        coordinator.animate(alongsideTransition: { _ in
            if let metalView = self.mtkView, self.sceneRenderer != nil {
                self.sceneRenderer.setViewSize(metalView.bounds.size)
            }
        }, completion: { _ in
            // Ensure final size is set after rotation completes
            if let metalView = self.mtkView, self.sceneRenderer != nil {
                self.sceneRenderer.setViewSize(metalView.bounds.size)
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Ensure view size is set after view appears
        if let metalView = mtkView, sceneRenderer != nil {
            sceneRenderer.setViewSize(metalView.bounds.size)
            
            // Kiểm tra khả năng hiển thị sau khi view đã xuất hiện
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.sceneRenderer.verifyRenderingCapability()
            }
        }
    }
    
    private func setupMetal() {
        let device = GPUDevice.shared.device
        sceneRenderer = SceneRenderer(device: device)
        
        if let metalView = mtkView {
            print("ViewController: MetalView found, type: \(type(of: metalView))")
            metalView.sceneRenderer = sceneRenderer
            print("ViewController: SceneRenderer assigned to MetalView")
            // Set initial view size if bounds are available
            let initialSize = metalView.bounds.size
            print("ViewController: MetalView initial size: \(initialSize)")
            if initialSize.width > 0 && initialSize.height > 0 {
                sceneRenderer.setViewSize(initialSize)
            } else {
                print("ViewController: Warning - MetalView size is zero, will set later")
            }
        } else {
            print("ViewController: ERROR - mtkView is nil! Check storyboard connection.")
        }
    }
    
    private func setupGestures() {
        guard let metalView = mtkView else { return }
        
        // Pan gesture for camera rotation
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        metalView.addGestureRecognizer(panGesture)
        
        // Pinch gesture for camera zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        metalView.addGestureRecognizer(pinchGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let metalView = mtkView else { return }
        
        let translation = gesture.translation(in: metalView)
        let sensitivity: Float = 0.01
        
        let deltaY = Float(translation.x) * sensitivity
        let deltaX = Float(translation.y) * sensitivity
        
        sceneRenderer?.updateCameraRotation(deltaY: deltaY, deltaX: deltaX)
        
        gesture.setTranslation(.zero, in: metalView)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            let scale = Float(gesture.scale)
            let delta = 1.0 / scale
            sceneRenderer?.updateCameraDistance(delta: delta)
            gesture.scale = 1.0
        }
    }
    
    // MARK: - UI Setup (Removed - Solar System doesn't need sliders for now)
    
    private func setupUI() {
        // UI removed for solar system - can be added later if needed
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
        lastTimestamp = CACurrentMediaTime()
    }
    
    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateAnimation() {
        let currentTime = CACurrentMediaTime()
        let deltaTime = Float(currentTime - lastTimestamp)
        lastTimestamp = currentTime
        
        // Cap delta time to prevent large jumps
        let clampedDeltaTime = min(deltaTime, 0.1)
        
        sceneRenderer?.updateAnimation(deltaTime: clampedDeltaTime)
    }
}

