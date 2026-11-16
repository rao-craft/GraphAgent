//  WHAT: The template of `GraphStage.swift`: the SceneKit scene behind the graph (its camera and lights, a lumpy clay
//        sphere for every node and a thin cylinder for every link) and how it shows the open hub, the selected node,
//        the theme and the app's accent.

extension Template {
    static let graphStage = ##"""
    import QuartzCore
    import SceneKit
    import SwiftUI
    import simd
    #if canImport(UIKit)
    import UIKit
    #else
    import AppKit
    #endif

    /// The scene behind the graph: its camera and lights, a body for every node and a cylinder for every link, and how
    /// they show the open hub, the selected node and the theme. Made once a scene view and changed in place.
    @MainActor
    final class GraphStage {
        let scene = SCNScene()
        /// The camera, {{cameraDistance}} back, looking at the centre.
        let camera = SCNNode()

        private let root = SCNNode()
        private let ambient = SCNNode()
        private let key = SCNNode()
        private let fill = SCNNode()
        private let strings = SCNMaterial()
        private var bodies: [String: SCNNode] = [:]
        private var materials: [String: SCNMaterial] = [:]
        private var places: [String: SIMD3<Float>] = [:]
        private var links: [(link: GraphShape.Link, node: SCNNode)] = []
        private var shape = GraphShape(dots: [], links: [])
        private var dark = false
        private var accent = GraphTone(red: 0.68, green: 0.56, blue: 0.38)
        private var open: String?
        private var selected: String?

        /// What every node's body is named: this and the node's id.
        static let prefix = "graph.node:"

        init() {
            scene.background.contents = GraphTone.clear.platform

            let lens = SCNCamera()
            lens.fieldOfView = {{fieldOfView}}
            lens.projectionDirection = .vertical
            lens.zNear = 0.1
            lens.zFar = 500
            lens.wantsHDR = true
            lens.bloomIntensity = 0.08
            lens.bloomBlurRadius = 6
            lens.bloomThreshold = 0.95
            lens.wantsExposureAdaptation = false
            camera.camera = lens
            camera.simdPosition = SIMD3<Float>(0, 0, {{cameraDistance}})
            camera.simdLook(at: .zero)
            scene.rootNode.addChildNode(camera)

            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambient.light = ambientLight
            let keyLight = SCNLight()
            keyLight.type = .directional
            keyLight.castsShadow = true
            keyLight.shadowRadius = 8
            keyLight.shadowSampleCount = 4
            keyLight.shadowMode = .forward
            key.light = keyLight
            key.simdPosition = SIMD3<Float>(5, 30, 15)
            key.simdLook(at: .zero)
            let fillLight = SCNLight()
            fillLight.type = .directional
            fill.light = fillLight
            fill.simdPosition = SIMD3<Float>(-10, -12, 20)
            fill.simdLook(at: .zero)
            for light in [ambient, key, fill] { scene.rootNode.addChildNode(light) }

            strings.lightingModel = .physicallyBased
            strings.metalness.contents = 0.0
            strings.roughness.contents = 0.8
            strings.isDoubleSided = true
            strings.emission.contents = GraphTone(white: 0).platform
            scene.rootNode.addChildNode(root)
            paint(dark: false, accent: accent)
        }

        // MARK: Theme

        /// The lights and the tones for the theme and the app's accent; the bodies take them at once.
        func paint(dark: Bool, accent: GraphTone) {
            self.dark = dark
            self.accent = accent
            ambient.light?.color = GraphTone(white: dark ? 0.18 : 0.75).platform
            ambient.light?.intensity = dark ? 400 : 900
            key.light?.color = (dark ? GraphTone(red: 0.75, green: 0.72, blue: 0.68) : GraphTone(white: 1)).platform
            key.light?.intensity = dark ? 500 : 800
            key.light?.shadowColor = GraphTone(white: 0, alpha: dark ? 0.35 : 0.10).platform
            fill.light?.color = (dark ? GraphTone(red: 0.22, green: 0.20, blue: 0.28) : GraphTone(red: 0.85, green: 0.85, blue: 0.92)).platform
            fill.light?.intensity = dark ? 200 : 300
            strings.diffuse.contents = stringTone.platform
            show(open: open, selected: selected, animated: false)
        }

        /// The open hub, its leaves out and the selected node, in the accent: darker in light, lighter in dark.
        private var groupTone: GraphTone { dark ? accent.shifted(20, 20, 20) : accent.shifted(-40, -40, -36) }
        /// The glow of the selected node, the open hub and its leaves.
        private var glowTone: GraphTone { dark ? accent.shifted(0, 0, 0, alpha: 0.85) : accent.shifted(-20, -20, -20, alpha: 0.70) }
        /// The links.
        private var stringTone: GraphTone { dark ? accent.shifted(-19, -14, -11) : accent.shifted(-16, -14, -14) }
        /// What every other body glows: almost nothing.
        private var restGlow: GraphTone { dark ? GraphTone(red: 0.06, green: 0.05, blue: 0.08) : GraphTone(red: 0.01, green: 0.01, blue: 0.03) }

        /// A body out of the group: near white in light, mid grey in dark; a leaf a little darker.
        private func rest(hub: Bool) -> GraphTone {
            let white = dark ? (hub ? 0.52 : 0.40) : (hub ? 0.97 : 0.93)
            return dark ? GraphTone(red: white, green: white * 0.97, blue: white * 0.93) : GraphTone(red: white, green: white, blue: min(white * 1.01, 1))
        }

        // MARK: Building

        /// A body for every node of `shape` and a cylinder for every link, where the layout puts them.
        func build(_ shape: GraphShape) {
            self.shape = shape
            for child in root.childNodes { child.removeFromParentNode() }
            bodies = [:]
            materials = [:]
            links = []
            //@if layout.force
            places = GraphLayout.positions(shape, keeping: places)
            //@else
            places = GraphLayout.positions(shape)
            //@endif
            for dot in shape.dots {
                guard let place = places[dot.id] else { continue }
                //@if bodySeed
                var seed = Seed(dot.id + "/{{bodySeed}}")
                //@else
                var seed = Seed(dot.id)
                //@endif
                let material = body(hub: dot.isHub)
                let node = SCNNode()
                node.name = Self.prefix + dot.id
                node.simdPosition = place
                if dot.isHub {
                    lumps(node, radius: Float({{hubRadius}} + {{hubRadiusStep}} * Double(dot.level)), seed: &seed, material: material)
                    let hover = CABasicAnimation(keyPath: "position.y")
                    hover.fromValue = place.y - 0.06
                    hover.toValue = place.y + 0.06
                    hover.duration = Double(seed.within(3.5, 5.5))
                    hover.autoreverses = true
                    hover.repeatCount = .infinity
                    hover.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    node.addAnimation(hover, forKey: "hover")
                } else {
                    //@if leafSpread
                    let radius = Float({{leafRadius}}) + seed.within(-{{leafRadiusSpread}}, {{leafRadiusSpread}})
                    leaf(node, radius: radius, seed: &seed, material: material)
                    //@else
                    let sphere = SCNSphere(radius: {{leafRadius}})
                    sphere.segmentCount = 14
                    sphere.firstMaterial = material
                    node.addChildNode(SCNNode(geometry: sphere))
                    //@endif
                    node.opacity = 0
                    node.simdScale = SIMD3<Float>(repeating: 0.01)
                }
                root.addChildNode(node)
                bodies[dot.id] = node
                materials[dot.id] = material
            }
            for link in shape.links {
                guard let start = places[link.from], let end = places[link.to] else { continue }
                let node = cylinder(from: start, to: end)
                node.opacity = 0
                root.addChildNode(node)
                links.append((link, node))
            }
            show(open: open, selected: selected, animated: false)
        }

        /// A hub's body: a sphere, and two or three smaller ones half in it, the same for the same id every time.
        private func lumps(_ node: SCNNode, radius: Float, seed: inout Seed, material: SCNMaterial) {
            let core = SCNSphere(radius: CGFloat(radius))
            core.segmentCount = 24
            core.firstMaterial = material
            node.addChildNode(SCNNode(geometry: core))
            for _ in 0..<(seed.next() < 0.5 ? 2 : 3) {
                let lump = SCNSphere(radius: CGFloat(radius * seed.within(0.35, 0.65)))
                lump.segmentCount = 16
                lump.firstMaterial = material
                let child = SCNNode(geometry: lump)
                let out = radius * seed.within(0.4, 0.85)
                let turn = seed.within(0, 2 * Float.pi)
                let tilt = seed.within(0.4, 2.7)
                child.simdPosition = SIMD3<Float>(out * sin(tilt) * cos(turn), out * cos(tilt), out * sin(tilt) * sin(turn))
                node.addChildNode(child)
            }
        }

        //@if leafSpread
        /// A leaf's body: a sphere, and about every other leaf a smaller one half in it, the same for the same id every
        /// time.
        private func leaf(_ node: SCNNode, radius: Float, seed: inout Seed, material: SCNMaterial) {
            let core = SCNSphere(radius: CGFloat(radius))
            core.segmentCount = 14
            core.firstMaterial = material
            node.addChildNode(SCNNode(geometry: core))
            guard seed.next() < 0.5 else { return }
            let lump = SCNSphere(radius: CGFloat(radius * seed.within(0.4, 0.65)))
            lump.segmentCount = 12
            lump.firstMaterial = material
            let child = SCNNode(geometry: lump)
            let out = radius * seed.within(0.3, 0.7)
            let turn = seed.within(0, 2 * Float.pi)
            child.simdPosition = SIMD3<Float>(out * cos(turn), out * seed.within(-0.3, 0.3), out * sin(turn))
            node.addChildNode(child)
        }

        //@endif
        /// A link: a cylinder from one node's centre to the other's.
        private func cylinder(from start: SIMD3<Float>, to end: SIMD3<Float>) -> SCNNode {
            let span = end - start
            let length = simd_length(span)
            let tube = SCNCylinder(radius: {{edgeRadius}}, height: CGFloat(length))
            tube.radialSegmentCount = 12
            tube.firstMaterial = strings
            let node = SCNNode(geometry: tube)
            node.simdPosition = (start + end) / 2
            if length > 0.000_1 {
                node.simdOrientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: span / length)
            }
            return node
        }

        /// A body's surface: matte clay, its normals stirred by slow noise.
        private func body(hub: Bool) -> SCNMaterial {
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.metalness.contents = 0.0
            material.roughness.contents = hub ? 0.62 : 0.72
            material.diffuse.contents = rest(hub: hub).platform
            material.emission.contents = restGlow.platform
            material.shaderModifiers = [.surface: Self.clay]
            return material
        }

        // MARK: Showing

        /// The open hub's leaves out and the links to them, the group in the accent, and the selected node pulsing.
        func show(open: String?, selected: String?, animated: Bool = true) {
            self.open = open
            self.selected = selected
            let out = shape.leavesOut(open: open, selected: selected)
            let glowing = shape.glowing(open: open, selected: selected)

            SCNTransaction.begin()
            SCNTransaction.animationDuration = animated ? 0.45 : 0
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            for dot in shape.dots {
                guard let node = bodies[dot.id], let material = materials[dot.id] else { continue }
                let shown = dot.isHub || out.contains(dot.id)
                node.opacity = shown ? 1 : 0
                node.simdScale = SIMD3<Float>(repeating: shown ? 1 : 0.01)
                let tinted = dot.isHub ? dot.id == open : shown
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0
                material.diffuse.contents = (tinted ? groupTone : rest(hub: dot.isHub)).platform
                SCNTransaction.commit()
            }
            for (link, node) in links {
                let drawn = shape.drawn(link, open: open, out: out)
                node.opacity = drawn ? 1 : 0
                if drawn, !node.animationKeys.contains("swell") {
                    let swell = CABasicAnimation(keyPath: "scale")
                    swell.fromValue = NSValue(scnVector3: SCNVector3(SIMD3<Float>(0.92, 1, 0.92)))
                    swell.toValue = NSValue(scnVector3: SCNVector3(SIMD3<Float>(1.15, 1, 1.15)))
                    swell.duration = 1
                    swell.autoreverses = true
                    swell.repeatCount = .infinity
                    swell.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    node.addAnimation(swell, forKey: "swell")
                } else if !drawn {
                    node.removeAnimation(forKey: "swell")
                }
            }
            SCNTransaction.commit()

            SCNTransaction.begin()
            SCNTransaction.animationDuration = animated ? 0.35 : 0
            for dot in shape.dots {
                guard let node = bodies[dot.id], let material = materials[dot.id] else { continue }
                material.emission.contents = (glowing.contains(dot.id) ? glowTone : restGlow).platform
                if dot.id == selected {
                    if !node.animationKeys.contains("pulse") {
                        let pulse = CABasicAnimation(keyPath: "scale")
                        pulse.fromValue = NSValue(scnVector3: SCNVector3(SIMD3<Float>(repeating: 1)))
                        pulse.toValue = NSValue(scnVector3: SCNVector3(SIMD3<Float>(repeating: {{pulseScale}})))
                        pulse.duration = {{pulseDuration}}
                        pulse.autoreverses = true
                        pulse.repeatCount = .infinity
                        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                        node.addAnimation(pulse, forKey: "pulse")
                    }
                } else {
                    node.removeAnimation(forKey: "pulse")
                }
            }
            SCNTransaction.commit()
        }

        // MARK: Camera

        //@if layout.force
        /// Moves `eye` (the view's point of view) along its line of sight until the node with `id` is centred, as far
        /// from the graph's middle (the plane through its centre, facing the camera) as a hub's or a leaf's focus: a
        /// node nearer the camera than the middle looks larger. Returns where the node stands, for the camera control
        /// to turn about.
        //@else
        /// Moves `eye` (the view's point of view) along its line of sight until the node with `id` is centred, as far
        /// from it as a hub's or a leaf's focus. Returns where the node stands, for the camera control to turn about.
        //@endif
        @discardableResult
        func focus(on id: String, eye: SCNNode, animated: Bool = true) -> SIMD3<Float>? {
            guard let dot = shape.dot(id), let target = places[id] else { return nil }
            let distance: Float = dot.isHub ? {{hubFocus}} : {{leafFocus}}
            SCNTransaction.begin()
            SCNTransaction.animationDuration = animated ? 0.6 : 0
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            //@if layout.force
            eye.simdWorldPosition = target - eye.simdWorldFront * (distance + simd_dot(target, eye.simdWorldFront))
            //@else
            eye.simdWorldPosition = target - eye.simdWorldFront * distance
            //@endif
            SCNTransaction.commit()
            return target
        }

        /// Moves `eye` back along its line of sight until every node stands in the frame, never nearer than the
        /// camera's own {{cameraDistance}}. Returns the centre, for the camera control to turn about.
        @discardableResult
        func fit(eye: SCNNode, animated: Bool = true) -> SIMD3<Float> {
            let furthest = places.values.map { simd_length($0) }.max() ?? 0
            let half = Float(eye.camera?.fieldOfView ?? {{fieldOfView}}) / 2 * Float.pi / 180
            let distance = max({{cameraDistance}}, (furthest + 1.5) / tan(half))
            SCNTransaction.begin()
            SCNTransaction.animationDuration = animated ? 0.55 : 0
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            eye.simdWorldPosition = -eye.simdWorldFront * distance
            SCNTransaction.commit()
            return .zero
        }

        /// The id of the node a tap landed on: the nearest body that shows.
        func node(at hits: [SCNHitTestResult]) -> String? {
            for hit in hits {
                var node: SCNNode? = hit.node
                while let current = node {
                    if let name = current.name, name.hasPrefix(Self.prefix) {
                        if current.opacity > 0.1 { return String(name.dropFirst(Self.prefix.count)) }
                        break
                    }
                    node = current.parent
                }
            }
            return nil
        }

        // MARK: Pieces

        /// A short run of numbers fixed by a node's id, so a hub's lumps and its hover are the same every launch.
        private struct Seed {
            private var state: UInt64

            init(_ text: String) {
                var hash: UInt64 = 0xcbf2_9ce4_8422_2325
                for byte in text.utf8 { hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01b3 }
                state = hash == 0 ? 0x9e37_79b9_7f4a_7c15 : hash
            }

            /// The next number, from 0 up to 1.
            mutating func next() -> Float {
                state ^= state << 13
                state ^= state >> 7
                state ^= state << 17
                return Float(state >> 40) / Float(1 << 24)
            }

            mutating func within(_ low: Float, _ high: Float) -> Float { low + (high - low) * next() }
        }

        /// Clay: three octaves of value noise, drifting slowly, tilt the normals and vary the roughness.
        private static let clay = """
            #pragma declaration

            float graphClayHash(float3 p) {
                p = fract(p * float3(0.1031, 0.1030, 0.0973));
                p += dot(p, p.yxz + 33.33);
                return fract((p.x + p.y) * p.z);
            }

            float graphClayNoise(float3 p) {
                float3 cell = floor(p);
                float3 f = fract(p);
                f = f * f * (3.0 - 2.0 * f);
                float near = mix(mix(graphClayHash(cell), graphClayHash(cell + float3(1, 0, 0)), f.x),
                                 mix(graphClayHash(cell + float3(0, 1, 0)), graphClayHash(cell + float3(1, 1, 0)), f.x), f.y);
                float far = mix(mix(graphClayHash(cell + float3(0, 0, 1)), graphClayHash(cell + float3(1, 0, 1)), f.x),
                                mix(graphClayHash(cell + float3(0, 1, 1)), graphClayHash(cell + float3(1, 1, 1)), f.x), f.y);
                return mix(near, far, f.z);
            }

            float graphClayField(float3 p) {
                float sum = 0.0;
                float weight = 0.5;
                for (int octave = 0; octave < 3; octave++) {
                    sum += weight * graphClayNoise(p);
                    p = p * 2.02 + float3(1.7, 9.2, 5.3);
                    weight *= {{clayDetail}};
                }
                return sum / {{clayDetail.total}};
            }

            #pragma body

            float clayTime = scn_frame.time * 0.15;
            float3 clayAt = _surface.position * 1.8 + float3(clayTime, clayTime * 0.7, -clayTime * 0.5);
            float clayHere = graphClayField(clayAt);
            float clayDelta = 0.05;
            float3 claySlope = float3(
                graphClayField(clayAt + float3(clayDelta, 0.0, 0.0)) - graphClayField(clayAt - float3(clayDelta, 0.0, 0.0)),
                graphClayField(clayAt + float3(0.0, clayDelta, 0.0)) - graphClayField(clayAt - float3(0.0, clayDelta, 0.0)),
                graphClayField(clayAt + float3(0.0, 0.0, clayDelta)) - graphClayField(clayAt - float3(0.0, 0.0, clayDelta))
            ) / (2.0 * clayDelta);
            _surface.normal = normalize(_surface.normal - claySlope * 0.55);
            _surface.roughness = mix(0.35, 0.8, clayHere);
            """
    }

    /// A colour as the scene uses it, in sRGB: made from the app's accent so the graph's group takes its hue.
    struct GraphTone: Equatable {
        var red: Double
        var green: Double
        var blue: Double
        var alpha: Double

        init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }

        init(white: Double, alpha: Double = 1) {
            self.init(red: white, green: white, blue: white, alpha: alpha)
        }

        /// A SwiftUI colour as it resolved for the theme.
        init(_ color: Color.Resolved) {
            self.init(red: Double(color.red), green: Double(color.green), blue: Double(color.blue), alpha: Double(color.opacity))
        }

        static let clear = GraphTone(white: 0, alpha: 0)

        /// This tone moved by steps of 1/255 a channel, kept between 0 and 1, at `alpha` when given.
        func shifted(_ red: Double, _ green: Double, _ blue: Double, alpha: Double? = nil) -> GraphTone {
            func step(_ value: Double, _ by: Double) -> Double { min(max(value + by / 255, 0), 1) }
            return GraphTone(red: step(self.red, red), green: step(self.green, green), blue: step(self.blue, blue), alpha: alpha ?? self.alpha)
        }

        #if canImport(UIKit)
        var platform: UIColor { UIColor(red: red, green: green, blue: blue, alpha: alpha) }
        #else
        var platform: NSColor { NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha) }
        #endif
    }
    """##
}
