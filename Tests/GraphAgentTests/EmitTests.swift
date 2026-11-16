import Foundation
import XCTest
@testable import GraphAgent

/// What a call writes: which files, under which names, what the Seer call's output says, and the same bytes again.
final class EmitTests: XCTestCase {
    private func write(_ input: GraphAgent.Input, into folder: URL) throws -> GraphResult {
        var call = input
        call.directory = folder.path
        return try GraphAgent.write(call, note: { _ in }, yield: { _ in })
    }

    private func names(_ result: GraphResult) -> Set<String> {
        Set(result.paths.map { URL(fileURLWithPath: $0).lastPathComponent })
    }

    func testTheSeerCallWritesTheKitAndOneConformance() throws {
        let folder = try Fixture.folder()
        let result = try write(try Fixture.example("seer"), into: folder)
        XCTAssertEqual(names(result), [
            "GraphProtocols.swift", "GraphValue.swift", "GraphLook.swift", "GraphStrings.swift", "GraphLaunch.swift",
            "GraphSupport.swift", "GraphStage.swift", "GraphScene.swift", "GraphBar.swift", "GraphBadge.swift", "GraphPanel.swift",
            "GraphTextSheet.swift", "GraphLoadingView.swift", "GraphEmptyView.swift", "GraphFailedView.swift", "GraphView.swift",
            "GraphPreviews.swift", "GraphNode+Node.swift",
        ])
        XCTAssertEqual(result.views, ["GraphView", "GraphScene", "GraphBadge", "GraphPanel", "GraphTextSheet", "GraphLoadingView",
                                      "GraphEmptyView", "GraphFailedView"])
        XCTAssertEqual(try Fixture.text(result.paths, "GraphNode+Node.swift"), """
        import Foundation
        import SeerKit

        /// A `GraphNode` as the graph views show a node.
        extension GraphNode: GraphNodeRepresentable {
            var graphNodeID: String { GraphValue.text(self.id) }
            var graphNodeLevel: Int { GraphValue.level(self.level) }
            var graphNodeText: String { GraphValue.text(self.text) }
            var graphNodeNeighbours: [String] { GraphValue.ids(self.neighborIds) }
        }

        """)
    }

    /// Every `code` item of the scorecard's `atlas` area matches the Seer call's output, and B-data-8 (the mock
    /// graph's ids) is left to `$mocks`.
    func testTheSeerCallsOutputMatchesTheScorecardsCodeFacts() throws {
        let code = try Fixture.all(try write(try Fixture.example("seer"), into: try Fixture.folder()).paths)
        for item in Fixture.scorecard {
            for pattern in item.all {
                XCTAssertNotNil(code.range(of: pattern, options: .regularExpression), "\(item.id): \(pattern)")
            }
        }
        XCTAssertNil(code.range(of: Fixture.mockIDs, options: .regularExpression), "B-data-8 is the mock graph's: the kit never writes its ids")
    }

    /// Every word the spec quotes for the Atlas sheet is in the Seer call's output.
    func testEveryQuotedWordOfTheSpecIsWritten() throws {
        let result = try write(try Fixture.example("seer"), into: try Fixture.folder())
        let code = try Fixture.all(result.paths)
        for word in Fixture.quoted { XCTAssertNotNil(code.range(of: word), word) }
        let strings = try Fixture.text(result.paths, "GraphStrings.swift")
        for line in [
            #"static var title: String { "Atlas" }"#,
            #"static func hub(_ level: Int) -> String { "L\(level) Hub" }"#,
            #"static var leaf: String { "Leaf" }"#,
            #"static var loading: String { "Connecting…" }"#,
            #"static var empty: String { "Add your first document to see your knowledge graph." }"#,
        ] {
            XCTAssertTrue(strings.contains(line), line)
        }
    }

    /// The numbers the spec gives, written where a person would write them.
    func testTheSeerCallsNumbersLookAndLaunch() throws {
        let result = try write(try Fixture.example("seer"), into: try Fixture.folder())
        let stage = try Fixture.text(result.paths, "GraphStage.swift")
        for line in ["Float(0.45 + 0.18 * Double(dot.level))", "SCNSphere(radius: 0.18)", "SCNCylinder(radius: 0.03, height: CGFloat(length))",
                     "camera.simdPosition = SIMD3<Float>(0, 0, 14)", "SIMD3<Float>(repeating: 1.12)", "pulse.duration = 1\n",
                     "lens.fieldOfView = 50", "let distance: Float = dot.isHub ? 18 : 12", "material.shaderModifiers = [.surface: Self.clay]"] {
            XCTAssertTrue(stage.contains(line), line)
        }
        let support = try Fixture.text(result.paths, "GraphSupport.swift")
        XCTAssertTrue(support.contains("let ring: Float = 3"))
        XCTAssertTrue(support.contains("spread(index, of: leaves.count) * 1.8"))
        XCTAssertTrue(support.contains("passage(String(text.prefix(240)))"))
        let scene = try Fixture.text(result.paths, "GraphScene.swift")
        XCTAssertTrue(scene.contains("view.allowsCameraControl = true"))
        XCTAssertTrue(scene.contains("view.backgroundColor = .clear"))
        let panel = try Fixture.text(result.paths, "GraphPanel.swift")
        for line in [".background(.ultraThinMaterial)", ".clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))",
                     "Image(systemName: \"xmark.circle.fill\")", ".font(.system(.caption2, design: .monospaced))", ".presentationDetents([.medium, .large])"] {
            XCTAssertTrue(panel.contains(line), line)
        }
        XCTAssertTrue(try Fixture.text(result.paths, "GraphBadge.swift").contains(".font(.system(size: 12, weight: .regular, design: .serif))"))
        XCTAssertTrue(try Fixture.text(result.paths, "GraphView.swift").contains(".animation(.spring(response: 0.4, dampingFraction: 0.8), value: selected)"))
        let look = try Fixture.text(result.paths, "GraphLook.swift")
        for line in ["static var title: Font { Font.brandTitle }", "static var note2: Font { Font.brandNote2 }",
                     "static var accent: Color { Color.accent }", "static var passage: Font { .body }", "static var hubBadge: Color { .indigo }"] {
            XCTAssertTrue(look.contains(line), line)
        }
        let launch = try Fixture.text(result.paths, "GraphLaunch.swift")
        XCTAssertTrue(launch.contains(#"switch UserDefaults.standard.string(forKey: "destination") {"#))
        XCTAssertTrue(launch.contains(#"case "atlas": return .graph(["space-001", "space-002", "space-003"])"#))
    }

    func testTheSameCallWritesTheSameBytes() throws {
        let folder = try Fixture.folder()
        let first = try write(try Fixture.example("seer"), into: folder)
        let texts = try first.paths.map { try String(contentsOfFile: $0, encoding: .utf8) }
        let second = try write(try Fixture.example("seer"), into: folder)
        XCTAssertEqual(second.paths, first.paths)
        XCTAssertEqual(try second.paths.map { try String(contentsOfFile: $0, encoding: .utf8) }, texts)
        XCTAssertEqual(Set(second.made.map(\.state)), [.unchanged], "written again to the same text")
        let elsewhere = try write(try Fixture.example("seer"), into: try Fixture.folder())
        XCTAssertEqual(try elsewhere.paths.map { try String(contentsOfFile: $0, encoding: .utf8) }, texts)
    }

    /// A later call into the same folder takes away what it no longer writes: a conformance of a line it dropped.
    func testALaterCallTakesAwayWhatItNoLongerWrites() throws {
        let folder = try Fixture.folder()
        var call = GraphAgent.Input(mappings: ["node: Doc id=key", "edge: Wire from=a to=b"])
        let first = try write(call, into: folder)
        XCTAssertTrue(names(first).contains("Wire+Edge.swift"))
        XCTAssertEqual(first.roots, ["GraphView(ids: [String] = [], nodes: [Doc], edges: [Wire], load: (([String]) async throws -> Void)? = nil)"])
        call.mappings = ["node: Doc id=key neighbours=links"]
        let second = try write(call, into: folder)
        let removed = second.made.filter { $0.state == .removed }.map { URL(fileURLWithPath: $0.path ?? "").lastPathComponent }
        XCTAssertEqual(removed, ["Wire+Edge.swift"])
        for path in second.made.filter({ $0.state == .removed }).compactMap(\.path) {
            XCTAssertFalse(FileManager.default.fileExists(atPath: path), path)
        }
        XCTAssertEqual(second.roots, ["GraphView(ids: [String] = [], nodes: [Doc], load: (([String]) async throws -> Void)? = nil)"])
    }

    func testAPrefixRenamesEveryNameTheKitDeclaresAndNoneOfTheApps() throws {
        let folder = try Fixture.folder()
        let result = try write(try Fixture.example("wiki-pages"), into: folder)
        XCTAssertTrue(result.paths.allSatisfy { $0.hasPrefix(folder.appendingPathComponent("Shared/Views/PageMap").path + "/") })
        XCTAssertTrue(names(result).isSuperset(of: ["WikiView.swift", "WikiLook.swift", "WikiStage.swift", "Page+Node.swift", "PageLink+Edge.swift"]))
        let code = try Fixture.all(result.paths)
        for name in KitCatalog.names {
            XCTAssertNil(code.range(of: #"(?<![A-Za-z0-9_])"# + name + #"(?![A-Za-z0-9_])"#, options: .regularExpression), "\(name) is renamed")
        }
        XCTAssertTrue(code.contains("extension Page: WikiNodeRepresentable {"))
        XCTAssertTrue(code.contains("var graphEdgeFrom: String { WikiValue.text(self.source) }"))
        XCTAssertTrue(code.contains(#"static func hub(_ level: Int) -> String { "Depth \(level)" }"#))
        XCTAssertTrue(code.contains(#"case "pages.page": return .text(["home"])"#))
        XCTAssertTrue(code.contains(".font(.system(size: 12, weight: .regular, design: .rounded))"))
        XCTAssertTrue(code.contains("passage(String(text.prefix(160)))"))
        XCTAssertEqual(result.roots, ["WikiView(ids: [String] = [], nodes: [Page], edges: [PageLink], load: (([String]) async throws -> Void)? = nil)"])
    }

    func testTheAppsTypesAreReadToCheckEachPath() throws {
        let folder = try Fixture.folder()
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("Shared"), withIntermediateDirectories: true)
        try Fixture.wikiModels.write(to: folder.appendingPathComponent("Shared/Models.swift"), atomically: true, encoding: .utf8)
        // The second example reads well against the types it was written for.
        XCTAssertNoThrow(try write(try Fixture.example("wiki-pages"), into: folder))
        let wrong = GraphAgent.Input(mappings: [
            "node: Page id=slugg level=title text=summary",
            "edge: PageLink from=source to=target",
        ])
        XCTAssertThrowsError(try write(wrong, into: folder)) { error in
            let text = "\(error)"
            for reason in ["node id=slugg: `Page` has no `slugg`: its fields are slug, depth, summary, title",
                           "node level=title: `title` is `String`, and `level` shows a level"] {
                XCTAssertTrue(text.contains(reason), "\(reason) in \(text)")
            }
        }
    }

    func testANodeLineMapsItsIDAndAnEdgeLineBothEnds() throws {
        let call = GraphAgent.Input(mappings: ["node: Doc text=body", "edge: Wire from=a", "node: Other id=id"])
        XCTAssertThrowsError(try write(call, into: try Fixture.folder())) { error in
            let text = "\(error)"
            for reason in ["`node: Doc` maps no `id`: the edges and the neighbours name a node by its id; add `id=…`",
                           "`edge: Wire` maps no `to`: an edge joins the ids at its two ends; add `to=…`",
                           "node is mapped twice: one type a role"] {
                XCTAssertTrue(text.contains(reason), "\(reason) in \(text)")
            }
        }
    }

    func testNotesSayWhatTheAppStillHasToDo() throws {
        let lonely = try write(GraphAgent.Input(mappings: ["node: Doc id=key level=0 text=body"]), into: try Fixture.folder())
        XCTAssertTrue(lonely.notes.contains { $0.hasPrefix("Left out level=0") })
        XCTAssertTrue(lonely.notes.contains { $0.hasPrefix("The node line maps no `neighbours` and no `edge:` line is given") })
        XCTAssertTrue(lonely.notes.contains { $0.hasPrefix("No `look` lines") })
        let edgesOnly = try write(GraphAgent.Input(mappings: ["edge: Wire from=a to=b"]), into: try Fixture.folder())
        XCTAssertTrue(edgesOnly.notes.contains { $0.hasPrefix("No `node:` line, so GraphView shows the kit's own GraphNodeItem") })
        XCTAssertEqual(edgesOnly.roots, ["GraphView(ids: [String] = [], nodes: [GraphNodeItem], edges: [Wire], load: (([String]) async throws -> Void)? = nil)"])
    }
}
