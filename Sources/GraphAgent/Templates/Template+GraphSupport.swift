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
        private let index: [String: Int]
        private let joined: [String: Set<String>]

        init(dots: [Dot], links: [Link]) {
            var index: [String: Int] = [:], kept: [Dot] = []
            for dot in dots where index[dot.id] == nil {
                index[dot.id] = kept.count
                kept.append(dot)
            }
            var pairs: Set<[String]> = [], joined: [String: Set<String>] = [:], linked: [Link] = []
            for link in links where link.from != link.to && index[link.from] != nil && index[link.to] != nil {
                guard pairs.insert([link.from, link.to].sorted()).inserted else { continue }
                linked.append(link)
                joined[link.from, default: []].insert(link.to)
                joined[link.to, default: []].insert(link.from)
            }
            self.dots = kept
            self.links = linked
            self.index = index
            self.joined = joined
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

        /// The hub a leaf hangs from: the first hub, in the stepping order, joined to it.
        func hub(of id: String) -> String? {
            let near = joined[id] ?? []
            return hubs.first { near.contains($0.id) }?.id
        }

        /// The leaves joined to `hub`.
        func leaves(of hub: String) -> Set<String> {
            (joined[hub] ?? []).filter { dot($0)?.isHub == false }
        }

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
