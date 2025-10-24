import SwiftUI
import ARKit
import SceneKit

/// SwiftUI wrapper for ARSCNView, exposing a composite expression intensity (0...1)
/// and a friendly label describing the expression.
struct ARFaceMeshView: UIViewRepresentable {
    @Binding var intensity: CGFloat
    @Binding var label: String

    private static var lastSnapshotView: ARSCNView?

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.delegate = context.coordinator
        view.automaticallyUpdatesLighting = true
        view.showsStatistics = false

        // Add a line-rendered face mesh node
        if let device = view.device, let geo = ARSCNFaceGeometry(device: device) {
            let node = SCNNode(geometry: geo)
            node.geometry?.firstMaterial?.fillMode = .lines
            context.coordinator.faceNode = node
            view.scene.rootNode.addChildNode(node)
        }

        // Simulator guard
        #if targetEnvironment(simulator)
        label = "AR not available in Simulator"
        ARFaceMeshView.lastSnapshotView = view
        return view
        #else
        guard ARFaceTrackingConfiguration.isSupported else {
            label = "Face tracking not supported on this device"
            return view
        }
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        view.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        ARFaceMeshView.lastSnapshotView = view
        return view
        #endif
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(intensity: $intensity, label: $label)
    }

    // Scene snapshot for capture
    static func snapshot() async -> UIImage? {
        await MainActor.run {
            guard let v = ARFaceMeshView.lastSnapshotView else { return nil }
            return v.snapshot()
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSCNViewDelegate {
        var faceNode: SCNNode?
        @Binding var intensity: CGFloat
        @Binding var label: String

        init(intensity: Binding<CGFloat>, label: Binding<String>) {
            _intensity = intensity
            _label = label
        }

        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            faceNode ?? SCNNode()
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let geom = node.geometry as? ARSCNFaceGeometry else { return }

            // Update wireframe geometry
            geom.update(from: faceAnchor.geometry)

            // BlendShapes come back as NSNumber, use doubleValue to avoid Decimal->CGFloat issues
            let smileLeft   = faceAnchor.blendShapes[.mouthSmileLeft]?.doubleValue ?? 0.0
            let smileRight  = faceAnchor.blendShapes[.mouthSmileRight]?.doubleValue ?? 0.0
            let cheekPuff   = faceAnchor.blendShapes[.cheekPuff]?.doubleValue ?? 0.0
            let tongueOut   = faceAnchor.blendShapes[.tongueOut]?.doubleValue ?? 0.0
            let browInnerUp = faceAnchor.blendShapes[.browInnerUp]?.doubleValue ?? 0.0

            // Composite intensity (tweak weights as you like)
            let smile = (smileLeft + smileRight) / 2.0
            let composite = min(1.0, max(0.0, 0.6 * smile + 0.3 * cheekPuff + 0.1 * browInnerUp))

            DispatchQueue.main.async {
                self.intensity = CGFloat(composite)

                if tongueOut > 0.2 {
                    self.label = "Tongue out 😛"
                } else if cheekPuff > 0.2 {
                    self.label = "Cheeks puffed 😯"
                } else if smile > 0.6 {
                    self.label = "Smiling 😄"
                } else if browInnerUp > 0.2 {
                    self.label = "Surprised 😮"
                } else {
                    self.label = "Neutral 🙂"
                }
            }
        }
    }
}

