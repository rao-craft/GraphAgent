//  WHAT: A 3D graph of how things connect, as a Granite agent package. A call names the app's types with one mapping
//        line a role (`node: GraphNode id=id level=level text=text neighbours=neighborIds`), the look, the words, the
//        numbers and the launch states; the run writes plain SwiftUI and SceneKit into the folder the call names (the
//        scene of hubs and leaves joined by thin cylinders, the card of the selected node, its text sheet, the bar's
//        buttons, the loading, empty and failure views), the protocols they read, the conformances that make the
//        app's types those protocols, and answers where, with the root view's initializer.
//  IN:   Input: the folder, the mapping lines and their modules, look, strings, tuning and launch lines, a prefix for
//        the kit's names.
//  OUT:  GraphResult: the files written, the views, the conformances, the root's initializer, and what the app still
//        has to do.
//  PIN:  NO MODEL. Every file is made from the call, the same way every time; a line that is not understood is
//        refused with its reason, every reason at once, and nothing is written until every problem is fixed and
//        every file parses.
//  PIN:  THE VIEWS NEVER ROUTE. They take values and closures and hold no global state; the app presents the graph,
//        and the kit presents only its own sheet.

import Foundation
import GraniteAgents

public struct GraphAgent: GraniteAgentPackage {
    public struct Input: Codable, Sendable {
        /// The folder the views go in, relative to the project; `Components/Graph` when left out.
        public var into: String?
        /// One line a role: `node: GraphNode id=id level=level text=text neighbours=neighborIds`.
        public var mappings: [String]?
        /// Modules the conformances import: where a mapped type lives.
        public var imports: [String]?
        /// The look roles mapped to the app's names, one a line: `title = Font.brandTitle`.
        public var look: [String]?
        /// The words, one a line: `title = Atlas`, `hub = L{level} Hub`.
        public var strings: [String]?
        /// Numbers, symbols and motion, one a line: `hubRadius = 0.45`.
        public var tuning: [String]?
        /// The states the root opens in for a `-destination` launch, one a line: `atlas = graph(space-001, space-002)`.
        public var launch: [String]?
        /// What the kit's names start with instead of `Graph`, when the app already has those names.
        public var prefix: String?
        /// The host's folder.
        public var directory: String?

        public init(into: String? = nil, mappings: [String]? = nil, imports: [String]? = nil, look: [String]? = nil,
                    strings: [String]? = nil, tuning: [String]? = nil, launch: [String]? = nil, prefix: String? = nil,
                    directory: String? = nil) {
            self.into = into; self.mappings = mappings; self.imports = imports; self.look = look; self.strings = strings
            self.tuning = tuning; self.launch = launch; self.prefix = prefix; self.directory = directory
        }
    }

    public typealias Event = GraphFrame
    public typealias Output = GraphResult
    public typealias Compute = Void

    public static let word = "graph"
    /// What it makes: the views a page shows, and the conformances that make the app's types theirs.
    public static let makes = [
        AgentMake(kind: "view", what: "a 3D graph of how things connect as reusable SwiftUI and SceneKit views (GraphView, the root a page shows, and its scene, panel, badge, text sheet and status views); a page shows it with GraphView(nodes:load:)",
                  into: ["Components/Graph/*"], never: "routes; never a page, a service, a client or a model type"),
        AgentMake(kind: "conformance", what: "the app's own types made the graph's: one extension a mapping line",
                  into: ["Components/Graph/Conformances/*"], never: "a change to the app's types themselves"),
    ]
    public static let summary = "writes a 3D graph of how things connect as plain SwiftUI and SceneKit (hubs and their leaves as spheres joined by thin cylinders, the selected node pulsing, a card with its badge and the start of its text), made to show the app's own types from one mapping line a type."
    public static let fields = [
        "into": "the folder for the views, relative to the project; Components/Graph when left out",
        "mappings": "one line a role (node, edge): `node: GraphNode id=id level=level text=text neighbours=neighborIds`, `edge: Link from=source to=target`; a bare path is read off the value, anything else is Swift that may name `value`",
        "imports": "modules the conformances import, such as the package a mapped type is declared in",
        "look": "look roles mapped to the app's names, one a line: `title = Font.brandTitle`; roles title, note, note2, passage (Font), accent, foreground, hubBadge, leafBadge (Color); an unmapped role is the system's",
        "strings": "the words, one a line, `key = words` (quotes optional): `title = Atlas`, `hub = L{level} Hub`, `loading = Connecting…`; `title =` with nothing after it draws no title; every key and its default in Graph.md",
        "tuning": "numbers, symbols and motion, one a line: `hubRadius = 0.45`, `excerpt = 240`, `pulseScale = 1.12`, `showAnimation = .spring(response: 0.4, dampingFraction: 0.8)`; `layout = force` stands the nodes where their links pull them instead of round a circle (`layoutSeed = 7` picks its starts); `hubLeaves = named` puts out only the leaves an open hub names itself; every key in Graph.md",
        "launch": "the state the root opens in for a launch with `-destination <name>`, one a line: `atlas = graph(space-001, space-002)`; states graph and text, each with the ids it loads in parentheses (none: the page's own)",
        "prefix": "what the kit's names start with instead of Graph, when the app already has those names: `Wiki` writes WikiView",
    ]
    public static let guide = """
        Tag graph for a screen that shows how an app's items connect, in 3D: hubs (level above 0) as large spheres \
        evenly round a circle facing the camera (or, with `layout = force`, where their links pull them), each leaf \
        (level 0) a small sphere out only around its open hub, joined to it by thin cylinders. The built-in camera \
        control turns and zooms it; the selected node pulses and its group takes the accent; a frosted card over \
        the bottom shows the node's badge (a hub's level, or Leaf), \
        its id and the start of its text, and a tap opens all of it. The bar holds a button that fits the whole graph \
        in view and two that step through the nodes, level by level. It writes plain SwiftUI and SceneKit (iOS 17 \
        and macOS 14) into `into` (Components/Graph). The root is `GraphView(ids: [String] = [], nodes: [Node], \
        load: { try await … })`: `load` is called with `ids` as it appears, a spinner shows until there are nodes, \
        then the first hub is selected; pass `edges:` when the app keeps its links apart from its nodes. The app \
        presents it. The views read two protocols, and `mappings` make the app's types conform, one line a role: \
        `role: Type word=value …`. Roles and their words: node (id, level, text, neighbours); edge (from, to). A node \
        line maps id, an edge line from and to. An id may be a String, a UUID, a URL or a whole number, a level a \
        whole number or a Double, neighbours a list or a set of ids. A type from a package needs `imports`. A word \
        left out takes a default; a role no line maps uses the kit's own value (GraphNodeItem, GraphEdgeItem). \
        `look` maps the look roles to the app's names (`title = Font.brandTitle`, `accent = Color.accent`); \
        `strings` sets any word by key (`title = Map`, `hub = L{level} Hub`, `loading = Connecting…`; `{level}` \
        stands for a hub's level; `title =` alone draws no title); `tuning` sets any number, symbol or motion by key \
        (`hubRadius = 0.45`, `excerpt = 240`, `pulseScale = 1.12`, `layout = force`); `launch` opens a state for \
        `-destination <name>` (`map = graph(doc-1, doc-2)`: \
        the graph of those ids, the first hub selected; `text(…)` opens its whole text too). Example, a wiki whose \
        pages link to each other: {"mappings": ["node: Page id=slug level=depth text=summary", "edge: PageLink \
        from=source to=target"], "strings": ["title = Pages", "hub = Depth {level}"], "prefix": "Wiki"}. A line it \
        cannot read is refused with the reason and nothing is written: fix the line and call again. Not for the \
        app's services, its network client or its model types.
        """

    public static func output(from events: [GraphFrame]) -> GraphResult? { events.compactMap(\.result).last }

    public init() {}

    public func run(_ input: Input, context: Context) -> AsyncThrowingStream<GraphFrame, Error> {
        // The folder is the call's, else the host's (a host over the wire may give it only there), else the
        // process's: never the runner's working folder while the host named one.
        var resolved = input
        if resolved.directory == nil { resolved.directory = context.host.directory }
        let call = resolved
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let result = try Self.write(call, note: context.host.note) { continuation.yield($0) }
                    continuation.yield(.written(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static let defaultFolder = "Components/Graph"

    /// The whole call: the lines read, the kit planned and made, staged, checked and written.
    static func write(_ input: Input, note: @Sendable (String) -> Void, yield: (GraphFrame) -> Void) throws -> GraphResult {
        var problems: [String] = []

        // The mapping lines, one type a role, each with what its role cannot do without.
        var mappings: [Mapping] = []
        for line in input.mappings ?? [] where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do { mappings.append(try MappingLine.parse(line)) } catch { problems.append("\(error)") }
        }
        var roles: Set<GraphRole> = []
        for mapping in mappings where !roles.insert(mapping.role).inserted {
            problems.append("\(mapping.role.rawValue) is mapped twice: one type a role")
        }
        for mapping in mappings {
            let missing = mapping.role.required.filter { mapping.assignment($0) == nil }
            guard !missing.isEmpty else { continue }
            let why = mapping.role == .node ? "the edges and the neighbours name a node by its id" : "an edge joins the ids at its two ends"
            problems.append("`\(mapping.role.rawValue): \(mapping.type)` maps no " + KeyedLine.list(missing.map { "`\($0)`" })
                + ": \(why); add " + missing.map { "`\($0)=…`" }.joined(separator: " and "))
        }

        // The keyed lines, each key once.
        var look: [String: String] = [:], strings: [String: String] = [:], tuning: [String: String] = [:]
        var launches: [(destination: String, state: LaunchState, ids: [String])] = []
        func keyed<T>(_ field: String, _ lines: [String]?, _ parse: (String) -> Result<T, GraphError>, key: (T) -> String, take: (T) -> Void) {
            var seen: Set<String> = []
            for line in lines ?? [] where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                switch parse(line) {
                case .failure(let error): problems.append("\(field): \(error)")
                case .success(let value):
                    guard seen.insert(key(value)).inserted else { problems.append("\(field): `\(key(value))` is set twice: keep one line"); continue }
                    take(value)
                }
            }
        }
        keyed("look", input.look, { LookLine.parse($0, roles: GraphTables.look) }, key: { $0.role.key }) { look[$0.role.key] = $0.expression }
        keyed("strings", input.strings, { StringsLine.parse($0, keys: GraphTables.strings) }, key: { $0.key.key }) { strings[$0.key.key] = $0.text }
        keyed("tuning", input.tuning, { TuningLine.parse($0, keys: GraphTables.tuning) }, key: { $0.key.key }) { tuning[$0.key.key] = $0.value }
        keyed("launch", input.launch, { LaunchLine.parse($0, states: GraphTables.launch) }, key: { $0.destination }) { launches.append($0) }

        // The prefix and the modules.
        let named = (input.prefix ?? "").trimmingCharacters(in: .whitespaces)
        if !named.isEmpty, !SwiftName.isTypeName(named) {
            problems.append("`\(named)` is not a prefix for type names: UpperCamelCase letters and digits, like `Wiki`")
        }
        let prefix = named.isEmpty || !SwiftName.isTypeName(named) ? KitCatalog.base : named
        var imports = (input.imports ?? []).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        for module in imports where !SwiftName.isModuleName(module) {
            problems.append("`\(module)` is not a module name")
        }

        // Each path checked against the app's own types, in their spelling; a type a local package declares imported.
        // The kit's own folder is not the app's: its previews declare sample values.
        let files = AgentFiles(directory: input.directory)
        let folder = files.resolve(input.into ?? defaultFolder)
        let app = AppTypes(root: files.root, excluding: folder)
        var notes: [String] = []
        var nothing: [String] = []
        mappings = mappings.map { mapping in
            // A property written as nothing is left out, so the protocol's default answers for it.
            let kept = mapping.assignments.filter { assignment in
                guard case .expression(let text) = assignment.source, assignment.property.kind.isNothing(text) else { return true }
                nothing.append("\(assignment.property.key)=\(text.trimmingCharacters(in: .whitespaces))")
                return false
            }
            return Mapping(line: mapping.line, role: mapping.role, type: mapping.type, assignments: kept)
        }
        if !nothing.isEmpty {
            notes.append("Left out \(nothing.joined(separator: ", ")): a property a line leaves out shows its default, so a line needs only what the type has.")
        }
        let roleTypes = Dictionary(mappings.map { ($0.role, $0.type) }, uniquingKeysWith: { first, _ in first })
        mappings = mappings.map { mapping in
            guard let declared = app.types[AppTypes.named(mapping.type)] else { return mapping }
            if let module = declared.module, !imports.contains(module), !mapping.type.hasPrefix(module + ".") {
                imports.append(module)
                notes.append("`\(mapping.type)` is declared in \(module), so the conformances import it.")
            }
            let assignments = mapping.assignments.map { assignment -> Mapping.Assignment in
                guard case .path(let path) = assignment.source else { return assignment }
                let property = assignment.property
                let (fixed, problem) = app.check(path, from: mapping.type)
                if let problem { problems.append("\(mapping.role.rawValue) \(property.key)=\(path): \(problem)"); return assignment }
                if fixed != path { notes.append("\(mapping.role.rawValue) \(property.key): `\(path)` is `\(fixed)` on \(declared.name).") }
                if let written = app.type(of: fixed, from: mapping.type) {
                    var base = written
                    while base.hasSuffix("?") || base.hasSuffix("!") { base.removeLast() }
                    let known = GraphKind.integers.union(["String", "Substring", "URL", "Double", "Float", "CGFloat", "Bool", "Date", "UUID", "Decimal"])
                    let declaredHere = app.types[AppTypes.named(base)] != nil && !base.hasPrefix("[")
                    if !property.kind.accepts(written), declaredHere || known.contains(base) || base.hasPrefix("[") || base.hasPrefix("Set<") {
                        let hint = property.kind == .ids ? ", like `\(property.key)=value.\(fixed).map(\\.id)`" : ""
                        problems.append("\(mapping.role.rawValue) \(property.key)=\(path): `\(fixed)` is `\(written)`, and `\(property.key)` shows "
                            + "\(property.kind.takesInWords): map a field of one of those\(hint), or leave `\(property.key)` out")
                        return assignment
                    }
                }
                return Mapping.Assignment(property: property, source: .path(fixed))
            }
            return Mapping(line: mapping.line, role: mapping.role, type: mapping.type, assignments: assignments)
        }
        if let node = mappings.first(where: { $0.role == .node }) {
            if node.assignment("neighbours") == nil, roleTypes[.edge] == nil {
                notes.append("The node line maps no `neighbours` and no `edge:` line is given, so no node is joined to another: every leaf stays out and no hub opens; map `neighbours=…`, or an edge line and pass `edges:`.")
            }
        } else if !mappings.isEmpty {
            notes.append("No `node:` line, so GraphView shows the kit's own \(GraphRole.node.itemType(prefix)): map the app's node with `node: Type id=… level=… text=…`.")
        }
        guard problems.isEmpty else { throw GraphError.problems(problems) }

        // The plan: every part, each number in its place.
        let plan = KitPlan(tuning: tuning, launched: Set(launches.map(\.state.name)), strings: strings)
        let flags = plan.flags
        let values = plan.values
        yield(.read(mappings: mappings.count, views: plan.views.count))
        note("writing \(plan.views.count) views into \(files.relative(folder))")

        let names = KitCatalog.names
        func renamed(_ text: String) -> String { TemplateRender.renaming(text, names: names, base: KitCatalog.base, prefix: prefix) }
        func file(_ name: String) -> String { prefix + name.dropFirst(KitCatalog.base.count) + ".swift" }
        var planned: [(url: URL, text: String)] = []
        for part in plan.parts {
            let text: String
            switch part.name {
            case "GraphProtocols": text = ProtocolsEmitter.emit()
            case "GraphLook": text = LookEmitter.emit(look)
            case "GraphStrings": text = StringsEmitter.emit(strings, flags: flags)
            case "GraphLaunch": text = LaunchEmitter.emit(launches)
            default: text = try TemplateRender.render(part.template, flags: flags, values: values)
            }
            planned.append((folder.appendingPathComponent(file(part.name)), renamed(text)))
        }
        let conformances = folder.appendingPathComponent("Conformances", isDirectory: true)
        for conformance in ConformanceEmitter.emit(mappings, imports: imports, prefix: prefix) {
            planned.append((conformances.appendingPathComponent(conformance.name), conformance.text))
        }

        // What an earlier call left that this one does not write: a conformance of a line it no longer has.
        let manager = FileManager.default
        let plannedPaths = Set(planned.map(\.url.standardizedFileURL.path))
        var stale: [URL] = []
        for part in KitCatalog.parts {
            let url = folder.appendingPathComponent(file(part.name))
            if !plannedPaths.contains(url.standardizedFileURL.path), manager.fileExists(atPath: url.path) { stale.append(url) }
        }
        let protocols = GraphRole.allCases.map { $0.protocolName(prefix) }
        for name in ((try? manager.contentsOfDirectory(atPath: conformances.path)) ?? []).sorted() where name.hasSuffix(".swift") {
            let url = conformances.appendingPathComponent(name)
            guard !plannedPaths.contains(url.standardizedFileURL.path),
                  let text = try? String(contentsOf: url, encoding: .utf8),
                  protocols.contains(where: { text.contains(": \($0) {") }) else { continue }
            stale.append(url)
        }

        let existed = Set(planned.map(\.url.path).filter { manager.fileExists(atPath: $0) })
        let unchanged = Set(planned.filter { (try? String(contentsOf: $0.url, encoding: .utf8)) == $0.text }.map(\.url.path))
        let written = try files.write(planned)
        for url in stale { try? manager.removeItem(at: url) }
        note("wrote \(written.count) files" + (stale.isEmpty ? "" : ", took away \(stale.count)"))

        // What it was asked for: every view of the plan, and one conformance a mapping line. What it made: each of
        // those whose file was written, and each file taken away.
        func state(_ path: String) -> AgentMade.State { unchanged.contains(path) ? .unchanged : existed.contains(path) ? .rewritten : .written }
        func path(_ name: String) -> String? { written.first { ($0 as NSString).lastPathComponent == name } }
        let views = plan.views.map { prefix + $0.dropFirst(KitCatalog.base.count) }
        var expected = views.map { AgentExpected(kind: "view", name: $0) }
        expected += mappings.map { AgentExpected(kind: "conformance", name: $0.type) }
        var made: [AgentMade] = views.compactMap { view in path(view + ".swift").map { AgentMade(kind: "view", name: view, path: $0, state: state($0)) } }
        made += mappings.compactMap { mapping in
            path("\(mapping.fileStem)+\(mapping.role.name).swift").map { AgentMade(kind: "conformance", name: mapping.type, path: $0, state: state($0)) }
        }
        made += stale.map { url in
            let name = url.deletingPathExtension().lastPathComponent
            return AgentMade(kind: url.deletingLastPathComponent().lastPathComponent == "Conformances" ? "conformance" : "view",
                             name: name.components(separatedBy: "+").first ?? name, path: url.path, state: .removed)
        }

        let nodeType = roleTypes[.node] ?? GraphRole.node.itemType(prefix)
        var root = "\(prefix)View(ids: [String] = [], nodes: [\(nodeType)]"
        if let edgeType = roleTypes[.edge] { root += ", edges: [\(edgeType)]" }
        root += ", load: (([String]) async throws -> Void)? = nil)"
        if look.isEmpty {
            notes.append("No `look` lines: the views use the system's fonts and colours; map the app's with `look` (`title = Font.brandTitle`).")
        }
        for (key, _) in tuning.sorted(by: { $0.key < $1.key }) {
            guard let part = GraphTables.tuning.first(where: { $0.key == key })?.part, !flags.contains(part) else { continue }
            let choice = part.split(separator: ".", maxSplits: 1).map(String.init)
            notes.append("`\(key)` is used only with `\(choice[0]) = \(choice[1])`, so it changes nothing.")
        }
        return GraphResult(path: written.first, paths: written + stale.map(\.path), views: views,
                           conformances: mappings.map { "\($0.type): \($0.role.rawValue)" }, roots: [root], notes: notes,
                           made: made, expected: expected)
    }
}
