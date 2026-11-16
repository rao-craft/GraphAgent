//  WHAT: The template of `GraphView.swift`, the root a page shows.

extension Template {
    static let graphView = ##"""
    import SwiftUI

    //@if layout.force
    /// A 3D graph of how things connect: hubs (level above 0) as large spheres and leaves (level 0) as small ones,
    /// standing where their links pull them and every other node pushes them, each hub's leaves out while it is open,
    /// joined to it by thin cylinders. The built-in camera control turns and zooms it. A tap on a node selects it (a
    /// hub opens), a tap elsewhere selects none; the
    //@else
    /// A 3D graph of how things connect: hubs (level above 0) as large spheres evenly round a circle facing the
    /// camera, each hub's leaves (level 0) out around it while it is open, joined to it by thin cylinders. The built-in
    /// camera control turns and zooms it. A tap on a node selects it (a hub opens), a tap elsewhere selects none; the
    //@endif
    /// selected node pulses, and its card rises over the bottom with its badge, its id and the start of its text. The
    /// bar fits the whole graph in view and steps through the nodes. A spinner shows until there are nodes; `load` is
    /// called with `ids` as it appears, and the first hub is selected once they come. It never routes: the app
    /// presents it.
    ///
    ///     GraphView(nodes: graph.state.nodes, load: { try await graph.load(ids: $0) })
    struct GraphView<Node: GraphNodeRepresentable, Edge: GraphEdgeRepresentable>: View {
        /// The ids `load` is called with: the page's own; a `-destination` launch may name others.
        let ids: [String]
        let nodes: [Node]
        let edges: [Edge]
        var load: (@MainActor ([String]) async throws -> Void)?

        @State private var phase = Phase.waiting
        @State private var selected: String?
        @State private var open: String?
        @State private var fit = 0
        @State private var showsText = false
        @State private var attempt = 0
        @State private var launched = false

        /// Where loading stands.
        private enum Phase: Equatable {
            case waiting, loading, done
            case failed(String)
        }

        init(ids: [String] = [], nodes: [Node], edges: [Edge], load: (@MainActor ([String]) async throws -> Void)? = nil) {
            self.ids = ids
            self.nodes = nodes
            self.edges = edges
            self.load = load
        }

        var body: some View {
            let shape = GraphShape(nodes: nodes, edges: edges)
            ZStack(alignment: .bottom) {
                content(shape)
                    .ignoresSafeArea(.all)
                    .padding(.bottom, 16)

                VStack(spacing: 0) {
                    Spacer()
                    if let node = selectedNode {
                        GraphPanel(node: node, showsText: $showsText, close: { selected = nil })
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                            .ignoresSafeArea(edges: .bottom)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .ignoresSafeArea(.all)
            }
            .modifier(GraphBar(title: GraphStrings.title, enabled: !shape.dots.isEmpty,
                               fit: { fitAll() }, previous: { step(-1, in: shape) }, next: { step(1, in: shape) }))
            .task(id: attempt) { await reload() }
            .onChange(of: shape, initial: true) { _, shape in settle(shape) }
            .task(id: nodes.isEmpty) { await openLaunch() }
            .animation({{showAnimation}}, value: selected)
        }

        @ViewBuilder
        private func content(_ shape: GraphShape) -> some View {
            if case .failed(let message) = phase {
                GraphFailedView(message: message, retry: { attempt += 1 })
            } else if shape.dots.isEmpty {
                if phase == .done {
                    GraphEmptyView()
                } else {
                    GraphLoadingView()
                }
            } else {
                GraphScene(shape: shape, open: open, selected: selected, fit: fit, tap: { tap($0, in: shape) })
                    .ignoresSafeArea()
                    .overlay(alignment: .topTrailing) {
                        if phase == .loading {
                            ProgressView()
                                .tint(.white)
                                .padding(14)
                                .background(.ultraThinMaterial, in: Circle())
                                .padding()
                        }
                    }
            }
        }

        /// The selected node, as the app gave it.
        private var selectedNode: Node? {
            guard let selected else { return nil }
            return nodes.first { $0.graphNodeID == selected }
        }

        /// Loads the launch's ids, or the page's: a failure shows why and a button to try again.
        private func reload() async {
            guard let load else {
                phase = .done
                return
            }
            phase = .loading
            let launch = GraphLaunch.state?.ids ?? []
            do {
                try await load(launch.isEmpty ? ids : launch)
                phase = .done
            } catch is CancellationError {
                return
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }

        /// The first node in the stepping order selected, its hub open, when nothing is selected or the selected node
        /// is gone.
        private func settle(_ shape: GraphShape) {
            if let selected, shape.dot(selected) != nil { return }
            guard let first = shape.ordered.first else {
                selected = nil
                open = nil
                return
            }
            go(first, in: shape)
        }

        /// Selects a node and opens its hub: the node itself, or the hub a leaf hangs from.
        private func go(_ id: String, in shape: GraphShape) {
            selected = id
            open = shape.dot(id)?.isHub == true ? id : shape.hub(of: id)
        }

        /// The node before or after the selected one in the stepping order, round from the end to the start.
        private func step(_ by: Int, in shape: GraphShape) {
            let order = shape.ordered
            guard !order.isEmpty else { return }
            let index = selected.flatMap { order.firstIndex(of: $0) }
            let next = index.map { ($0 + by + order.count) % order.count } ?? (by > 0 ? 0 : order.count - 1)
            go(order[next], in: shape)
        }

        /// A tap in the scene: on a hub it opens or closes, and the node is selected; elsewhere nothing is.
        private func tap(_ id: String?, in shape: GraphShape) {
            guard let id, let dot = shape.dot(id) else {
                selected = nil
                open = nil
                return
            }
            if dot.isHub { open = open == id ? nil : id }
            selected = id
        }

        /// Nothing selected, no hub open, and the whole graph in view.
        private func fitAll() {
            selected = nil
            open = nil
            fit += 1
        }

        /// What a `-destination` launch opens over the graph, unanimated once its nodes are there and have settled.
        private func openLaunch() async {
            guard !nodes.isEmpty, !launched, let state = GraphLaunch.state else { return }
            launched = true
            try? await Task.sleep(for: .milliseconds(600))
            var transaction = SwiftUI.Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                switch state {
                case .graph:
                    break
                case .text:
                    if selected != nil { showsText = true }
                }
            }
        }
    }

    extension GraphView where Edge == GraphEdgeItem {
        /// A graph whose nodes name their neighbours, with no edges of their own.
        init(ids: [String] = [], nodes: [Node], load: (@MainActor ([String]) async throws -> Void)? = nil) {
            self.init(ids: ids, nodes: nodes, edges: [], load: load)
        }
    }

    #Preview("Graph") {
        NavigationStack {
            GraphView(nodes: GraphSample.nodes)
        }
    }

    #Preview("Loading") {
        NavigationStack {
            GraphView(nodes: [GraphNodeItem](), load: { _ in try await Task.sleep(for: .seconds(60)) })
        }
    }
    """##
}
