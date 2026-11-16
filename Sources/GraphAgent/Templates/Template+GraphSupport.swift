//  WHAT: The template of `GraphSupport.swift`: the graph as the scene draws it (each node once, each link once, which
//        leaves are out and which nodes glow), where each node stands, how a node's text reads, and the light tap.

extension Template {
    static let graphSupport = ##"""
    import SwiftUI
    import simd
    #if os(iOS)
    import UIKit
    #endif

    /// The graph as the scene draws it: each node once, in the app's order, and each link between two of them once,
    /// whichever node or edge names it.
    struct GraphShape: Equatable {
        /// A node: a hub when its level is above 0, else a leaf.
        struct Dot: Equatable {
            let id: String
            let level: Int

            var isHub: Bool { level > 0 }
        }

        /// Two nodes joined.
        struct Link: Equatable {
            let from: String
            let to: String

            func touches(_ id: String) -> Bool { from == id || to == id }

            /// The end that is not `id`.
            func other(_ id: String) -> String { from == id ? to : from }
        }

        let dots: [Dot]
        let links: [Link]
        //@if layout.force
        /// The node each node names first (its first neighbour, else the far end of its first edge), by id: the force
        /// layout starts a leaf beside it.
        let firsts: [String: String]
        //@endif
        private let index: [String: Int]
        private let joined: [String: Set<String>]
        //@if hubLeaves.named
        /// The nodes each node names itself, by id: its neighbours and the far end of each edge it starts.
        private let named: [String: Set<String>]
        //@endif

        init(dots: [Dot], links: [Link]) {
            var index: [String: Int] = [:], kept: [Dot] = []
            for dot in dots where index[dot.id] == nil {
                index[dot.id] = kept.count
                kept.append(dot)
            }
            //@if layout.force
            var firsts: [String: String] = [:]
            for link in links where link.from != link.to && firsts[link.from] == nil { firsts[link.from] = link.to }
            //@endif
            var pairs: Set<[String]> = [], joined: [String: Set<String>] = [:], linked: [Link] = []
            for link in links where link.from != link.to && index[link.from] != nil && index[link.to] != nil {
                guard pairs.insert([link.from, link.to].sorted()).inserted else { continue }
                linked.append(link)
                joined[link.from, default: []].insert(link.to)
                joined[link.to, default: []].insert(link.from)
            }
            //@if hubLeaves.named
            var named: [String: Set<String>] = [:]
            for link in links where link.from != link.to && index[link.from] != nil && index[link.to] != nil {
                named[link.from, default: []].insert(link.to)
            }
            //@endif
            self.dots = kept
            self.links = linked
            //@if layout.force
            self.firsts = firsts
            //@endif
            self.index = index
            self.joined = joined
            //@if hubLeaves.named
            self.named = named
            //@endif
        }

        /// The app's nodes and edges: a node named twice counts once, the first time; a link is kept once, and only
        /// between two nodes that are there.
        init<Node: GraphNodeRepresentable, Edge: GraphEdgeRepresentable>(nodes: [Node], edges: [Edge]) {
            let dots = nodes.map { Dot(id: $0.graphNodeID, level: $0.graphNodeLevel) }
            var links = nodes.flatMap { node in node.graphNodeNeighbours.map { Link(from: node.graphNodeID, to: $0) } }
            links += edges.map { Link(from: $0.graphEdgeFrom, to: $0.graphEdgeTo) }
            self.init(dots: dots, links: links)
        }

        /// The node with `id`, if the graph has it.
        func dot(_ id: String) -> Dot? { index[id].map { dots[$0] } }

        /// Whether any node is a hub.
        var hasHubs: Bool { dots.contains { $0.isHub } }

        /// The nodes in the order the bar steps through them: the higher levels first, then by id.
        var ordered: [String] {
            dots.sorted { $0.level != $1.level ? $0.level > $1.level : $0.id < $1.id }.map(\.id)
        }

        /// The hubs, in the stepping order.
        var hubs: [Dot] {
            dots.filter(\.isHub).sorted { $0.level != $1.level ? $0.level > $1.level : $0.id < $1.id }
        }

        //@if hubLeaves.named
        /// The hub a leaf hangs from: the first hub, in the stepping order, that names it; none when no hub does.
        func hub(of id: String) -> String? {
            hubs.first { named[$0.id]?.contains(id) == true }?.id
        }

        /// The leaves `hub` names itself.
        func leaves(of hub: String) -> Set<String> {
            (named[hub] ?? []).filter { dot($0)?.isHub == false }
        }
        //@else
        /// The hub a leaf hangs from: the first hub, in the stepping order, joined to it.
        func hub(of id: String) -> String? {
            let near = joined[id] ?? []
            return hubs.first { near.contains($0.id) }?.id
        }

        /// The leaves joined to `hub`.
        func leaves(of hub: String) -> Set<String> {
            (joined[hub] ?? []).filter { dot($0)?.isHub == false }
        }
        //@endif

        /// The leaves out: the open hub's, every leaf joined to no hub, and the selected leaf; with no hubs, all of them.
        func leavesOut(open: String?, selected: String?) -> Set<String> {
            let all = dots.filter { !$0.isHub }.map(\.id)
            guard hasHubs else { return Set(all) }
            var out = open.map { leaves(of: $0) } ?? []
            for leaf in all where !(joined[leaf] ?? []).contains(where: { dot($0)?.isHub == true }) {
                out.insert(leaf)
            }
            if let selected, dot(selected)?.isHub == false { out.insert(selected) }
            return out
        }

        /// Whether a link is drawn: between the open hub and a leaf that is out; with no hubs, between two leaves.
        func drawn(_ link: Link, open: String?, out: Set<String>) -> Bool {
            guard hasHubs else { return out.contains(link.from) && out.contains(link.to) }
            guard let open, link.touches(open) else { return false }
            return out.contains(link.other(open))
        }

        /// The nodes in the accent: the selected node, the open hub and its leaves.
        func glowing(open: String?, selected: String?) -> Set<String> {
            var glowing = open.map { leaves(of: $0).union([$0]) } ?? []
            if let selected { glowing.insert(selected) }
            return glowing
        }
    }

    //@if layout.force
    /// Where each node stands: pushed from every other node (a hub from another hub harder) and pulled along its links
    /// toward the nodes it joins, all drawn gently to the centre, step by step until they settle; nothing further than
    /// 12 from the centre, and the whole centred. The hubs start round a band, the higher a level the further out; a
    /// leaf beside the node it names first, when that one is placed before it; anything else in a box round the
    /// centre. The starts are drawn from a seed, so the same graph and seed stand the same way every time.
    enum GraphLayout {
        /// Where every node of `shape` stands. Nodes `kept` from an earlier layout start where they stood and hold
        /// there for the first fifty steps; when every node is kept, nothing moves.
        static func positions(_ shape: GraphShape, keeping kept: [String: SIMD3<Float>] = [:], seed: UInt64 = {{layoutSeed}}) -> [String: SIMD3<Float>] {
            guard !shape.dots.isEmpty else { return [:] }
            if !kept.isEmpty, shape.dots.allSatisfy({ kept[$0.id] != nil }) { return kept }

            // The hubs first, the higher levels before the lower, each level in the app's order.
            let order = shape.dots.indices.sorted { one, other in
                let (a, b) = (shape.dots[one], shape.dots[other])
                return a.level != b.level ? a.level > b.level : one < other
            }.map { shape.dots[$0] }
            let hubCount = order.filter(\.isHub).count
            var draw = Draw(seed)
            var at: [String: Int] = [:]
            var bodies: [Body] = []
            var hubs = 0
            for (index, dot) in order.enumerated() {
                at[dot.id] = index
                let place: SIMD3<Float>
                if let start = kept[dot.id] {
                    place = start
                } else if dot.isHub {
                    let turn = Float(hubs) / Float(max(hubCount, 1)) * 2 * Float.pi
                    let tilt = draw.within(0.6, 2.5)
                    let out = 2.5 + 0.8 * Float(dot.level)
                    place = SIMD3<Float>(out * sin(tilt) * cos(turn), out * cos(tilt) * 0.6 + draw.within(-0.5, 0.5), out * sin(tilt) * sin(turn))
                    hubs += 1
                } else if let first = shape.firsts[dot.id], let near = at[first], near < index {
                    let turn = draw.within(0, 2 * Float.pi)
                    let out = draw.within(1.5, 3.5)
                    place = bodies[near].place + SIMD3<Float>(cos(turn) * out, draw.within(-1.5, 1.5), sin(turn) * out)
                } else {
                    place = SIMD3<Float>(draw.within(-8, 8), draw.within(-4, 4), draw.within(-8, 8))
                }
                bodies.append(Body(place: place, hub: dot.isHub, held: kept[dot.id] != nil))
            }
            let pairs = shape.links.compactMap { link in at[link.from].flatMap { from in at[link.to].map { (from, $0) } } }

            for step in 0..<400 {
                let loose = step > 50
                for one in bodies.indices {
                    for other in (one + 1)..<bodies.count {
                        let apart = bodies[other].place - bodies[one].place
                        let square = max(simd_length_squared(apart), 0.01)
                        let strength: Float = bodies[one].hub && bodies[other].hub ? 35 : 18
                        let push = apart / square.squareRoot() * (strength / square)
                        if !bodies[one].held || loose { bodies[one].speed -= push }
                        if !bodies[other].held || loose { bodies[other].speed += push }
                    }
                }
                for (from, to) in pairs {
                    let pull = (bodies[to].place - bodies[from].place) * 0.06
                    if !bodies[from].held || loose { bodies[from].speed += pull }
                    if !bodies[to].held || loose { bodies[to].speed -= pull }
                }
                var energy: Float = 0
                for index in bodies.indices where !bodies[index].held || loose {
                    bodies[index].speed -= bodies[index].place * 0.02
                    bodies[index].speed *= 0.82
                    bodies[index].place += bodies[index].speed
                    let reach = simd_length(bodies[index].place)
                    if reach > 12 {
                        bodies[index].place *= 12 / reach
                        bodies[index].speed *= 0.5
                    }
                    energy += simd_length_squared(bodies[index].speed)
                }
                if energy < 0.05 { break }
            }

            let centre = bodies.reduce(SIMD3<Float>.zero) { $0 + $1.place } / Float(bodies.count)
            var places: [String: SIMD3<Float>] = [:]
            for (index, dot) in order.enumerated() { places[dot.id] = bodies[index].place - centre }
            return places
        }

        /// A node as the layout moves it.
        private struct Body {
            var place: SIMD3<Float>
            var speed = SIMD3<Float>.zero
            let hub: Bool
            /// Kept from an earlier layout: it holds still for the first steps.
            let held: Bool
        }

        /// Numbers from 0 up to 1, the same run for the same seed.
        private struct Draw {
            private var state: UInt64

            init(_ seed: UInt64) { state = seed }

            mutating func next() -> Float {
                state &+= 0x9e37_79b9_7f4a_7c15
                var mixed = state
                mixed = (mixed ^ (mixed >> 30)) &* 0xbf58_476d_1ce4_e5b9
                mixed = (mixed ^ (mixed >> 27)) &* 0x94d0_49bb_1331_11eb
                mixed ^= mixed >> 31
                return Float(mixed >> 40) / Float(1 << 24)
            }

            mutating func within(_ low: Float, _ high: Float) -> Float { low + (high - low) * next() }
        }
    }
    //@else
    /// Where each node stands: the hubs evenly round a circle facing the camera, the first at the top (a lone hub at
    /// the centre); each leaf {{leafDistance}} from its hub, its leaves spread round it; a leaf joined to no hub round
    /// the centre. The same graph stands the same way every time.
    enum GraphLayout {
        static func positions(_ shape: GraphShape) -> [String: SIMD3<Float>] {
            var places: [String: SIMD3<Float>] = [:]
            let ring: Float = {{ringRadius}}
            let hubs = shape.hubs
            for (index, hub) in hubs.enumerated() {
                places[hub.id] = hubs.count == 1 ? .zero : circle(index, of: hubs.count) * ring
            }
            var around: [String: [String]] = [:], loose: [String] = []
            for dot in shape.dots where !dot.isHub {
                if let hub = shape.hub(of: dot.id) { around[hub, default: []].append(dot.id) } else { loose.append(dot.id) }
            }
            for (hub, leaves) in around {
                guard let centre = places[hub] else { continue }
                for (index, leaf) in leaves.enumerated() {
                    places[leaf] = centre + spread(index, of: leaves.count) * {{leafDistance}}
                }
            }
            for (index, leaf) in loose.enumerated() {
                if hubs.isEmpty {
                    places[leaf] = loose.count == 1 ? .zero : circle(index, of: loose.count) * ring
                } else {
                    places[leaf] = spread(index, of: loose.count) * (hubs.count == 1 ? ring : ring / 2)
                }
            }
            return places
        }

        /// The `index`th of `count` points evenly round a circle of radius 1 facing the camera, the first at the top.
        static func circle(_ index: Int, of count: Int) -> SIMD3<Float> {
            let angle = Float.pi / 2 + 2 * Float.pi * Float(index) / Float(count)
            return SIMD3<Float>(cos(angle), sin(angle), 0)
        }

        /// The `index`th of `count` points spread evenly over a sphere of radius 1, the first up and to the right.
        static func spread(_ index: Int, of count: Int) -> SIMD3<Float> {
            let height = 1 - 2 * (Float(index) + 0.5) / Float(count)
            let across = (1 - height * height).squareRoot()
            let angle = Float(index) * 2.399963
            return SIMD3<Float>(across * cos(angle), height, across * sin(angle))
        }
    }
    //@endif

    /// How the graph views write a node's text.
    enum GraphFormat {
        /// The start of a node's text, as the panel shows it: its first {{excerpt}} characters.
        static func excerpt(_ text: String) -> AttributedString {
            passage(String(text.prefix({{excerpt}})))
        }

        /// A node's text with its inline markdown read (bold, italics, code, links) and its line breaks kept.
        static func passage(_ text: String) -> AttributedString {
            let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
        }
    }

    /// The light tap felt on the bar's buttons and on a node picked in the scene.
    enum GraphHaptic {
        @MainActor static func light() {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
    }
    """##
}
