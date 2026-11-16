//  WHAT: The template of `GraphScene.swift`: the SCNView that shows the stage, with the built-in camera control, and
//        the tap that picks a node.

extension Template {
    static let graphScene = ##"""
    import SceneKit
    import SwiftUI

    /// The graph's 3D scene: an SCNView with the built-in camera control (one finger turns it, two move it, a pinch
    /// zooms), no backdrop of its own, and a tap that picks the node under it, or none. The selected node is centred
    /// as it changes; `fit` changing fits the whole graph in view.
    struct GraphScene {
        let shape: GraphShape
        let open: String?
        let selected: String?
        /// Fits the whole graph in view each time it changes.
        let fit: Int
        let tap: @MainActor (String?) -> Void

        /// What keeps the stage and answers the view: it changes the scene only where the values changed.
        @MainActor
        final class Coordinator: NSObject {
            private struct Shown: Equatable {
                let open: String?
                let selected: String?
            }

            private struct Paint: Equatable {
                let dark: Bool
                let accent: GraphTone
            }

            let stage = GraphStage()
            private var tap: @MainActor (String?) -> Void = { _ in }
            private var shape: GraphShape?
            private var shown: Shown?
            private var painted: Paint?
            private var focused: String?
            private var fit = 0
            private weak var view: SCNView?

            func make() -> SCNView {
                let view = SCNView(frame: .zero)
                view.scene = stage.scene
                view.pointOfView = stage.camera
                view.backgroundColor = .clear
                view.antialiasingMode = .multisampling4X
                view.allowsCameraControl = true
                view.autoenablesDefaultLighting = false
                #if canImport(UIKit)
                let picker = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
                for other in view.gestureRecognizers ?? [] {
                    if let double = other as? UITapGestureRecognizer, double.numberOfTapsRequired == 2 { picker.require(toFail: double) }
                }
                #else
                let picker = NSClickGestureRecognizer(target: self, action: #selector(tapped(_:)))
                #endif
                view.addGestureRecognizer(picker)
                self.view = view
                return view
            }

            func update(_ scene: GraphScene, view: SCNView, environment: EnvironmentValues) {
                tap = scene.tap
                #if canImport(UIKit)
                for spinner in view.subviews where spinner is UIActivityIndicatorView { spinner.removeFromSuperview() }
                #endif
                let paint = Paint(dark: environment.colorScheme == .dark, accent: GraphTone(GraphLook.accent.resolve(in: environment)))
                if paint != painted {
                    painted = paint
                    stage.paint(dark: paint.dark, accent: paint.accent)
                }
                let first = shape == nil
                if shape != scene.shape {
                    shape = scene.shape
                    stage.build(scene.shape)
                    focused = nil
                }
                let now = Shown(open: scene.open, selected: scene.selected)
                if now != shown {
                    shown = now
                    stage.show(open: scene.open, selected: scene.selected, animated: !first)
                }
                if let selected = scene.selected, selected != focused, let eye = view.pointOfView {
                    focused = selected
                    if let target = stage.focus(on: selected, eye: eye, animated: !first) {
                        view.defaultCameraController.target = SCNVector3(target)
                    }
                } else if scene.selected == nil {
                    focused = nil
                }
                if scene.fit != fit, let eye = view.pointOfView {
                    fit = scene.fit
                    view.defaultCameraController.target = SCNVector3(stage.fit(eye: eye))
                }
            }

            #if canImport(UIKit)
            @objc func tapped(_ recognizer: UITapGestureRecognizer) {
                guard recognizer.state == .ended, let view else { return }
                pick(at: recognizer.location(in: view), in: view)
            }
            #else
            @objc func tapped(_ recognizer: NSClickGestureRecognizer) {
                guard recognizer.state == .ended, let view else { return }
                pick(at: recognizer.location(in: view), in: view)
            }
            #endif

            /// The node under a tap, the nearest that shows, or none.
            private func pick(at point: CGPoint, in view: SCNView) {
                let hits = view.hitTest(point, options: [
                    SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue,
                    SCNHitTestOption.sortResults: true,
                ])
                if let id = stage.node(at: hits) {
                    GraphHaptic.light()
                    tap(id)
                } else {
                    tap(nil)
                }
            }
        }
    }

    #if canImport(UIKit)
    extension GraphScene: UIViewRepresentable {
        func makeCoordinator() -> Coordinator { Coordinator() }
        func makeUIView(context: Context) -> SCNView { context.coordinator.make() }
        func updateUIView(_ view: SCNView, context: Context) {
            context.coordinator.update(self, view: view, environment: context.environment)
        }
    }
    #else
    extension GraphScene: NSViewRepresentable {
        func makeCoordinator() -> Coordinator { Coordinator() }
        func makeNSView(context: Context) -> SCNView { context.coordinator.make() }
        func updateNSView(_ view: SCNView, context: Context) {
            context.coordinator.update(self, view: view, environment: context.environment)
        }
    }
    #endif

    #Preview {
        GraphScene(shape: GraphShape(nodes: GraphSample.nodes, edges: [GraphEdgeItem]()), open: GraphSample.nodes[0].id,
                   selected: GraphSample.nodes[0].id, fit: 0, tap: { _ in })
            .ignoresSafeArea()
    }
    """##
}
