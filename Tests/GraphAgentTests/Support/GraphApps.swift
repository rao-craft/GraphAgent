import Foundation

/// The apps the gated build writes the kit into: Seer (its design names stood in, its page written as the prompt
/// gives it), a wiki with its own types, its links kept apart and a prefix, and the least call, plus the check each
/// one runs.
enum GraphApps {
    /// The page body the prompt gives for `atlas`.
    static let seerBody = "GraphView(nodes: graph.state.nodes, load: { try await graph.load(ids: $0) })"

    /// The page body when the page is opened for a highlight's documents.
    static let seerIDsBody = "GraphView(ids: ids, nodes: graph.state.nodes, load: { try await graph.load(ids: $0) })"

    /// DesignAgent's names, as Seer's call maps them: the fonts and the accent.
    static let seerDesign = """
    import SwiftUI

    extension Font {
        static var brandTitle: Font { .system(size: 24, weight: .regular, design: .serif) }
        static var brandBody: Font { .system(size: 20, weight: .regular, design: .serif) }
        static var brandBody2: Font { .system(size: 18, weight: .regular, design: .serif) }
        static var brandNote: Font { .system(size: 18, weight: .light, design: .serif) }
        static var brandNote2: Font { .system(size: 16, weight: .light, design: .serif) }
    }

    extension Color {
        static var accent: Color { Color(red: 174 / 255, green: 144 / 255, blue: 96 / 255) }
    }
    """

    /// The page `$granite` writes, its relay stood in by a plain class of the same shape: `graph.state.nodes`,
    /// `try await graph.load(ids:)`.
    static let seerPage = """
    import SwiftUI
    import SeerKit

    @MainActor
    final class GraphService {
        struct State {
            var nodes: [GraphNode] = []
        }

        var state = State()

        func load(ids: [String]) async throws {
            state.nodes = GraphSamples.nodes(for: ids.isEmpty ? ["space-001", "space-002", "space-003"] : ids)
        }
    }

    struct AtlasPage: View {
        let graph: GraphService

        var body: some View {
            \(seerBody)
        }
    }

    struct AtlasIDsPage: View {
        let graph: GraphService
        let ids: [String]

        var body: some View {
            \(seerIDsBody)
        }
    }
    """

    /// Seer's mock graph, in SeerKit's type: per document a hub `<id>#0` holding its text and a leaf a sentence,
    /// `<id>#1`, … joined to it; the first document's hub is level 2, the rest level 1. `$mocks`' to write; stood in
    /// here.
    static let seerSamples = #"""
    import Foundation
    import SeerKit

    enum GraphSamples {
        static let texts = [
            "space-001": "Mars is the fourth planet from the Sun and the second-smallest planet in the Solar System. It has a thin atmosphere composed mostly of carbon dioxide.",
            "space-002": "A Hohmann transfer is the cheapest path between two circular orbits.",
            "space-003": "Launch windows to Mars open every twenty-six months. The trip takes about nine months. Landing is the hardest part.",
        ]

        static func nodes(for ids: [String]) -> [GraphNode] {
            ids.enumerated().flatMap { index, id -> [GraphNode] in
                let text = texts[id] ?? id
                let sentences = text.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                let leaves = sentences.count > 1 ? sentences.indices.map { "\(id)#\($0 + 1)" } : []
                let hub = GraphNode(id: "\(id)#0", level: index == 0 ? 2 : 1, text: text, neighborIds: leaves)
                return [hub] + zip(leaves, sentences).map { GraphNode(id: $0, level: 0, text: $1 + ".", neighborIds: [hub.id]) }
            }
        }
    }
    """#

    /// What Seer's targets run: the conversions, the words, the shape and the layout read back, the launch read,
    /// every view drawn offscreen in light and dark, and on the Mac the scene itself rendered and its pixels read.
    static let seerCheck = #"""
    import SwiftUI
    import SeerKit
    import simd
    #if os(macOS)
    import AppKit
    import Metal
    import SceneKit
    #endif

    public enum __APP__Check {
        @MainActor
        public static func run() -> (drawn: [String], failed: [String]) {
            var drawn: [String] = [], failed: [String] = []
            func expect(_ name: String, _ holds: Bool) { if !holds { failed.append(name) } }
            func draw<Content: View>(_ name: String, height: CGFloat? = nil, @ViewBuilder _ content: () -> Content) {
                for scheme in [ColorScheme.light, .dark] {
                    let view = content()
                        .frame(width: 402, height: height)
                        .fixedSize(horizontal: false, vertical: height == nil)
                        .environment(\.colorScheme, scheme)
                    if ImageRenderer(content: view).cgImage == nil { failed.append(name) } else { drawn.append(name) }
                }
            }

            let nodes = GraphSamples.nodes(for: ["space-001", "space-002", "space-003"])
            let hub = "space-001#0"
            expect("id", nodes[0].graphNodeID == hub)
            expect("level", nodes[0].graphNodeLevel == 2 && nodes[3].graphNodeLevel == 1 && nodes[1].graphNodeLevel == 0)
            expect("text", nodes[0].graphNodeText.hasPrefix("Mars is the fourth planet"))
            expect("neighbours", nodes[0].graphNodeNeighbours == ["space-001#1", "space-001#2"])
            expect("no title", GraphStrings.title == "")
            expect("badge", GraphStrings.hub(2) == "L2 Hub" && GraphStrings.leaf == "Leaf")
            expect("loading", GraphStrings.loading == "Connecting…")
            expect("excerpt", String(GraphFormat.excerpt(String(repeating: "x", count: 500)).characters).count == 240)
            expect("whole passage", String(GraphFormat.excerpt(nodes[0].graphNodeText).characters) == nodes[0].graphNodeText)
            expect("markdown", String(GraphFormat.passage("A **bold** word").characters) == "A bold word")

            let shape = GraphShape(nodes: nodes, edges: [GraphEdgeItem]())
            let leaves: Set<String> = ["space-001#1", "space-001#2"]
            expect("dots", shape.dots.count == nodes.count)
            expect("links", shape.links.count == 5)
            expect("order", shape.ordered.prefix(3) == [hub, "space-002#0", "space-003#0"])
            expect("hub of a leaf", shape.hub(of: "space-001#2") == hub && shape.hub(of: "space-003#1") == "space-003#0")
            expect("leaves out", shape.leavesOut(open: hub, selected: hub) == leaves)
            expect("closed", shape.leavesOut(open: nil, selected: nil).isEmpty)
            let out = shape.leavesOut(open: hub, selected: hub)
            expect("drawn", shape.links.filter { shape.drawn($0, open: hub, out: out) }.count == 2)
            expect("glowing", shape.glowing(open: hub, selected: hub) == leaves.union([hub]))
            // A hub's leaves are the ones it names: `b` names the hub, the hub does not name `b`.
            let named = GraphShape(dots: [.init(id: "h", level: 1), .init(id: "a", level: 0), .init(id: "b", level: 0)],
                                   links: [.init(from: "h", to: "a"), .init(from: "b", to: "h")])
            expect("the leaves a hub names", named.leavesOut(open: "h", selected: "h") == ["a"])
            expect("the hub that names a leaf", named.hub(of: "a") == "h" && named.hub(of: "b") == nil)
            // The force layout: every node stands, the same every launch for the seed, centred; kept, nothing moves.
            let places = GraphLayout.positions(shape)
            expect("every node stands", places.count == nodes.count)
            expect("the same every launch", places == GraphLayout.positions(shape))
            expect("another seed, another stand", places != GraphLayout.positions(shape, seed: 7))
            expect("centred", simd_length(places.values.reduce(SIMD3<Float>.zero, +) / Float(places.count)) < 0.001)
            expect("kept", GraphLayout.positions(shape, keeping: places) == places)
            UserDefaults.standard.register(defaults: ["destination": "atlas"])
            expect("launch", GraphLaunch.state == .graph(["space-001"]))
            UserDefaults.standard.register(defaults: ["destination": "models"])
            expect("plain launch", GraphLaunch.state == nil)

            draw("badge") { HStack { GraphBadge(level: 2); GraphBadge(level: 0) } }
            draw("panel") { GraphPanel(node: nodes[0], showsText: .constant(false), close: {}) }
            draw("text sheet", height: 437) { GraphTextSheet(text: nodes[0].graphNodeText) }
            draw("loading", height: 437) { GraphLoadingView() }
            draw("empty", height: 437) { GraphEmptyView() }
            draw("failed", height: 437) { GraphFailedView(message: "The graph could not be reached.", retry: {}) }
            draw("bar", height: 437) { NavigationStack { Color.clear.modifier(GraphBar(title: GraphStrings.title, enabled: true, fit: {}, previous: {}, next: {})) } }
            draw("graph", height: 437) { NavigationStack { GraphView(nodes: nodes) } }
            draw("waiting", height: 437) { NavigationStack { GraphView(nodes: [GraphNode](), load: { _ in }) } }
            draw("page", height: 437) { NavigationStack { AtlasPage(graph: GraphService()) } }
            draw("page for ids", height: 437) { NavigationStack { AtlasIDsPage(graph: GraphService(), ids: ["space-002"]) } }

            #if os(macOS)
            failed += scene(shape, hub: hub, leaves: Array(leaves).sorted())
            drawn.append("scene")
            #endif
            return (drawn, failed)
        }

        #if os(macOS)
        /// The scene rendered as the sheet shows it, in light and dark: the first hub selected and centred, it and the
        /// leaves it names in the accent's bronze where the layout stands them, nothing behind; then the whole graph
        /// fitted with nothing open, every hub plain and every leaf away.
        @MainActor
        static func scene(_ shape: GraphShape, hub: String, leaves: [String]) -> [String] {
            var failed: [String] = []
            guard let device = MTLCreateSystemDefaultDevice() else { return ["no Metal device"] }
            let size = CGSize(width: 402, height: 400)
            let places = GraphLayout.positions(shape)
            for scheme in [ColorScheme.light, .dark] {
                var environment = EnvironmentValues()
                environment.colorScheme = scheme
                let stage = GraphStage()
                stage.paint(dark: scheme == .dark, accent: GraphTone(GraphLook.accent.resolve(in: environment)))
                stage.build(shape)
                for view in ["focus", "fit"] {
                    let name = (scheme == .dark ? "dark " : "light ") + view
                    if view == "focus" {
                        stage.show(open: hub, selected: hub, animated: false)
                        stage.focus(on: hub, eye: stage.camera, animated: false)
                    } else {
                        stage.show(open: nil, selected: nil, animated: false)
                        stage.fit(eye: stage.camera, animated: false)
                    }
                    let renderer = SCNRenderer(device: device, options: nil)
                    renderer.scene = stage.scene
                    renderer.pointOfView = stage.camera
                    let image = renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
                    guard let picture = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return ["\(name) scene: no image"] }
                    if let folder = ProcessInfo.processInfo.environment["GRAPH_SHOTS"],
                       let png = NSBitmapImageRep(cgImage: picture).representation(using: .png, properties: [:]) {
                        let file = "__APP__-scene-\(scheme == .dark ? "dark" : "light")\(view == "fit" ? "-fit" : "").png"
                        try? png.write(to: URL(fileURLWithPath: folder).appendingPathComponent(file))
                    }
                    let width = picture.width, height = picture.height
                    var bytes = [UInt8](repeating: 0, count: width * height * 4)
                    bytes.withUnsafeMutableBytes { buffer in
                        let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                        context?.draw(picture, in: CGRect(x: 0, y: 0, width: width, height: height))
                    }
                    /// The pixel at a point of the 402 × 400 frame, from its top left.
                    func pixel(_ x: Double, _ y: Double) -> (red: Int, green: Int, blue: Int, alpha: Int) {
                        let column = min(max(Int(x / size.width * Double(width)), 0), width - 1)
                        let row = min(max(Int(y / size.height * Double(height)), 0), height - 1)
                        let at = (row * width + column) * 4
                        return (Int(bytes[at]), Int(bytes[at + 1]), Int(bytes[at + 2]), Int(bytes[at + 3]))
                    }
                    /// Where a node's centre shows in the frame, through the camera; nil outside it.
                    func spot(_ id: String) -> (x: Double, y: Double)? {
                        guard let place = places[id], let lens = stage.camera.camera else { return nil }
                        let seen = stage.camera.simdWorldTransform.inverse * SIMD4<Float>(place, 1)
                        let scale = Double(size.height) / 2 / Double(tan(lens.fieldOfView / 2 * .pi / 180))
                        let x = Double(size.width) / 2 + Double(seen.x / -seen.z) * scale
                        let y = Double(size.height) / 2 - Double(seen.y / -seen.z) * scale
                        return x > 4 && x < Double(size.width) - 4 && y > 4 && y < Double(size.height) - 4 ? (x, y) : nil
                    }
                    func bronze(_ point: (red: Int, green: Int, blue: Int, alpha: Int)) -> Bool {
                        point.alpha > 200 && point.red > point.blue + 25 && point.green > point.blue && point.red >= point.green
                    }
                    func plain(_ point: (red: Int, green: Int, blue: Int, alpha: Int)) -> Bool {
                        point.alpha > 200 && abs(point.red - point.blue) < 30 && (scheme == .dark ? point.red < 190 && point.red > 40 : point.red > 170)
                    }
                    if view == "focus" {
                        let centre = pixel(Double(size.width) / 2, Double(size.height) / 2)
                        if !bronze(centre) { failed.append("\(name): the selected hub is \(centre)") }
                        let seen = leaves.compactMap { leaf in spot(leaf).map { (leaf, pixel($0.x, $0.y)) } }
                        if seen.isEmpty { failed.append("\(name): none of the hub's leaves is in view") }
                        for (leaf, point) in seen where !bronze(point) { failed.append("\(name): the leaf \(leaf) is \(point)") }
                    } else {
                        for dot in shape.hubs {
                            guard let at = spot(dot.id) else { failed.append("\(name): the hub \(dot.id) is out of view"); continue }
                            let point = pixel(at.x, at.y)
                            if !plain(point) { failed.append("\(name): the hub \(dot.id) is \(point)") }
                        }
                        for dot in shape.dots where !dot.isHub {
                            if let at = spot(dot.id), pixel(at.x, at.y).alpha > 10 { failed.append("\(name): the leaf \(dot.id) shows with nothing open") }
                        }
                    }
                    let corner = pixel(4, 4)
                    if corner.alpha > 10 { failed.append("\(name): the backdrop is \(corner)") }
                }
            }
            return failed
        }
        #endif
    }
    """#

    /// The wiki's check: its own types read through the conformances, its links kept apart, its words and launch,
    /// and every view of its prefixed kit drawn.
    static let wikiCheck = #"""
    import SwiftUI

    public enum WikiCheck {
        @MainActor
        public static func run() -> (drawn: [String], failed: [String]) {
            var drawn: [String] = [], failed: [String] = []
            func expect(_ name: String, _ holds: Bool) { if !holds { failed.append(name) } }
            func draw<Content: View>(_ name: String, height: CGFloat? = nil, @ViewBuilder _ content: () -> Content) {
                for scheme in [ColorScheme.light, .dark] {
                    let view = content()
                        .frame(width: 402, height: height)
                        .fixedSize(horizontal: false, vertical: height == nil)
                        .environment(\.colorScheme, scheme)
                    if ImageRenderer(content: view).cgImage == nil { failed.append(name) } else { drawn.append(name) }
                }
            }

            let pages = [Page(slug: "home", depth: 2, summary: "The start. Every page links here.", title: "Home"),
                         Page(slug: "about", depth: 0, summary: nil, title: "About"),
                         Page(slug: "faq", depth: 1, summary: "Questions, answered.", title: "FAQ"),
                         Page(slug: "home", depth: 0, summary: "A second page with the same slug.", title: "Copy")]
            let links = [PageLink(source: "home", target: "about"), PageLink(source: "about", target: "home"),
                         PageLink(source: "faq", target: "about"), PageLink(source: "faq", target: "nowhere")]
            expect("id", pages[0].graphNodeID == "home" && pages[0].graphNodeLevel == 2)
            expect("no summary", pages[1].graphNodeText == "")
            expect("no neighbours", pages[0].graphNodeNeighbours.isEmpty)
            expect("edge", links[0].graphEdgeFrom == "home" && links[0].graphEdgeTo == "about")
            let shape = WikiShape(nodes: pages, edges: links)
            expect("each slug once", shape.dots.map(\.id) == ["home", "about", "faq"])
            expect("each link once, between nodes that are there", shape.links.count == 2)
            expect("the higher hub first", shape.hub(of: "about") == "home")
            expect("words", WikiStrings.hub(3) == "Depth 3" && WikiStrings.title == "Pages")
            UserDefaults.standard.register(defaults: ["destination": "pages.page"])
            expect("launch", WikiLaunch.state == .text(["home"]))
            UserDefaults.standard.register(defaults: ["destination": "pages.map"])
            expect("launch map", WikiLaunch.state == .graph([]))

            draw("graph", height: 437) { NavigationStack { WikiView(nodes: pages, edges: links) } }
            draw("panel") { WikiPanel(node: pages[1], showsText: .constant(false), close: {}) }
            draw("badge") { WikiBadge(level: 0) }
            draw("empty", height: 437) { WikiEmptyView() }
            draw("sheet", height: 437) { WikiTextSheet(text: "**Home** and _about_.") }
            return (drawn, failed)
        }
    }
    """#

    /// The least call's check: no type of the app's, the kit's own values, the hubs round the default circle.
    static let leastCheck = #"""
    import SwiftUI
    import simd

    public enum LeastCheck {
        @MainActor
        public static func run() -> (drawn: [String], failed: [String]) {
            var drawn: [String] = [], failed: [String] = []
            func draw<Content: View>(_ name: String, @ViewBuilder _ content: () -> Content) {
                let view = content().frame(width: 402, height: 437)
                if ImageRenderer(content: view).cgImage == nil { failed.append(name) } else { drawn.append(name) }
            }
            if GraphLaunch.state != nil { failed.append("launch") }
            if GraphSample.nodes.filter({ $0.level > 0 }).count != 3 { failed.append("sample hubs") }
            let shape = GraphShape(nodes: GraphSample.nodes, edges: [GraphEdgeItem]())
            let places = GraphLayout.positions(shape)
            func near(_ one: SIMD3<Float>?, _ other: SIMD3<Float>) -> Bool { one.map { simd_distance($0, other) < 0.001 } ?? false }
            if !near(places[shape.hubs[0].id], SIMD3<Float>(0, 3, 0)) { failed.append("first hub at the top") }
            if !near(places[shape.hubs[1].id], SIMD3<Float>(-3 * 0.866_025, -1.5, 0)) { failed.append("hubs round the circle") }
            if let leaf = shape.dots.first(where: { !$0.isHub }), let hub = shape.hub(of: leaf.id),
               abs(simd_distance(places[leaf.id]!, places[hub]!) - 1.8) > 0.001 { failed.append("leaf distance") }
            if !near(GraphLayout.positions(GraphShape(dots: [.init(id: "a", level: 1)], links: []))["a"], .zero) { failed.append("lone hub") }
            draw("graph") { NavigationStack { GraphView(nodes: GraphSample.nodes) } }
            draw("panel") { GraphPanel(node: GraphSample.nodes[1], showsText: .constant(false), close: {}) }
            return (drawn, failed)
        }
    }
    """#
}
