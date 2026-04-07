//
//  PlanetData.swift
//  GeometryLab
//
//  Created by wizard.os25 on 5/12/25.
//

import Foundation
import simd

struct PlanetData {
    let name: String
    let radius: Float
    let orbitRadius: Float
    let orbitSpeed: Float  // radians per second
    let rotationSpeed: Float  // radians per second
    let tilt: Float  // axis tilt in radians
    let color: SIMD4<Float>  // RGBA color
    
    static let sun = PlanetData(
        name: "Sun",
        radius: 2.5,
        orbitRadius: 0,  // Sun doesn't orbit
        orbitSpeed: 0,
        rotationSpeed: 0.1,
        tilt: 0,
        color: SIMD4<Float>(1.0, 0.9, 0.0, 1.0)  // Yellow
    )
    
    static let mercury = PlanetData(
        name: "Mercury",
        radius: 0.3,
        orbitRadius: 4,
        orbitSpeed: 1.6,
        rotationSpeed: 0.4,
        tilt: 0,
        color: SIMD4<Float>(0.7, 0.6, 0.5, 1.0)  // Gray-brown
    )
    
    static let venus = PlanetData(
        name: "Venus",
        radius: 0.9,
        orbitRadius: 7,
        orbitSpeed: 1.2,
        rotationSpeed: -0.3,  // Retrograde rotation
        tilt: 0,
        color: SIMD4<Float>(1.0, 0.8, 0.4, 1.0)  // Yellow-orange
    )
    
    static let earth = PlanetData(
        name: "Earth",
        radius: 1.0,
        orbitRadius: 10,
        orbitSpeed: 1.0,
        rotationSpeed: 2.0,
        tilt: 23.5 * .pi / 180,  // 23.5 degrees
        color: SIMD4<Float>(0.2, 0.4, 0.9, 1.0)  // Blue
    )
    
    static let mars = PlanetData(
        name: "Mars",
        radius: 0.7,
        orbitRadius: 15,
        orbitSpeed: 0.8,
        rotationSpeed: 1.8,
        tilt: 25 * .pi / 180,  // 25 degrees
        color: SIMD4<Float>(0.8, 0.3, 0.2, 1.0)  // Red
    )
    
    static let jupiter = PlanetData(
        name: "Jupiter",
        radius: 1.8,
        orbitRadius: 25,
        orbitSpeed: 0.5,
        rotationSpeed: 2.5,
        tilt: 3.1 * .pi / 180,  // ~3 degrees
        color: SIMD4<Float>(0.9, 0.7, 0.5, 1.0)  // Brown-orange
    )
    
    static let saturn = PlanetData(
        name: "Saturn",
        radius: 1.6,
        orbitRadius: 30,
        orbitSpeed: 0.4,
        rotationSpeed: 2.2,
        tilt: 26.7 * .pi / 180,  // ~27 degrees
        color: SIMD4<Float>(0.9, 0.8, 0.6, 1.0)  // Yellow-tan
    )
    
    static let uranus = PlanetData(
        name: "Uranus",
        radius: 1.3,
        orbitRadius: 38,
        orbitSpeed: 0.3,
        rotationSpeed: 1.4,
        tilt: 98 * .pi / 180,  // 98 degrees (almost sideways)
        color: SIMD4<Float>(0.4, 0.7, 0.9, 1.0)  // Cyan-blue
    )
    
    static let neptune = PlanetData(
        name: "Neptune",
        radius: 1.2,
        orbitRadius: 45,
        orbitSpeed: 0.2,
        rotationSpeed: 1.6,
        tilt: 28.3 * .pi / 180,  // ~28 degrees
        color: SIMD4<Float>(0.2, 0.4, 0.9, 1.0)  // Deep blue
    )
    
    static let allPlanets: [PlanetData] = [
        sun, mercury, venus, earth, mars, jupiter, saturn, uranus, neptune
    ]
}

