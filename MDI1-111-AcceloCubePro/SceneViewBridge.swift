//
//  SceneViewBridge.swift
//  AcceloCubePro
//
//  Created by Christian Bonilla on 17/11/25.
//

import SwiftUI
import SceneKit

struct SceneViewBridge: UIViewRepresentable {
    @Binding var quat: simd_quatf
    @Binding var position: SIMD3<Float>
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = SCNScene()
        view.backgroundColor = .clear
        view.allowsCameraControl = false
        
        // Cube
        let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemOrange
        cube.materials = [material]
        
        let node = SCNNode(geometry: cube)
        context.coordinator.node = node
        view.scene?.rootNode.addChildNode(node)
        
        // Floor grid
        let floor = SCNFloor()
        floor.firstMaterial?.diffuse.contents = UIColor.systemGray6
        view.scene?.rootNode.addChildNode(SCNNode(geometry: floor))
        
        // Light
        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .omni
        light.position = SCNVector3(2, 2, 5)
        view.scene?.rootNode.addChildNode(light)
        
        // Camera
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.position = SCNVector3(0, 0.2, 1.5)
        view.scene?.rootNode.addChildNode(cam)
        
        return view
    }
    
    func updateUIView(_ view: SCNView, context: Context) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.05
        
        if let node = context.coordinator.node {
            node.orientation = SCNQuaternion(quat.imag.x, quat.imag.y, quat.imag.z, quat.real)
            node.position = SCNVector3(position.x, position.y, position.z)
        }
        
        SCNTransaction.commit()
    }
    
    func makeCoordinator() -> Coord { Coord() }
    
    final class Coord { var node: SCNNode? }
}
