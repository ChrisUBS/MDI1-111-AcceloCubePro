import SwiftUI
import SceneKit

struct OrientationCubeView: UIViewRepresentable {
    @ObservedObject var vm: MotionVM

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        v.scene = SCNScene()
        v.backgroundColor = .clear
        v.allowsCameraControl = false

        // Cube
        let cube = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.06)
        let m = SCNMaterial()
        m.diffuse.contents = UIColor.systemOrange
        cube.materials = [m]

        let node = SCNNode(geometry: cube)
        context.coordinator.node = node
        v.scene?.rootNode.addChildNode(node)

        // Light
        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .omni
        light.position = SCNVector3(2, 2, 4)
        v.scene?.rootNode.addChildNode(light)

        // Camera
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.position = SCNVector3(0, 0, 5)
        v.scene?.rootNode.addChildNode(cam)

        return v
    }

    func updateUIView(_ v: SCNView, context: Context) {
        let q = SCNQuaternion(Float(vm.qx), Float(vm.qy), Float(vm.qz), Float(vm.qw))
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.05
        context.coordinator.node?.orientation = q
        SCNTransaction.commit()
    }

    func makeCoordinator() -> Coord { Coord() }

    final class Coord { var node: SCNNode? }
}
