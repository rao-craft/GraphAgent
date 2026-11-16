import XCTest
@testable import GraphAgent

/// The lines a model writes, read: every form the guide promises, and a reason for every line refused.
final class LineTests: XCTestCase {
    // MARK: Mapping

    func testAMappingLineOfBarePaths() throws {
        let mapping = try MappingLine.parse("node: GraphNode id=id level=level text=text neighbours=neighborIds")
        XCTAssertEqual(mapping.role, .node)
        XCTAssertEqual(mapping.type, "GraphNode")
        XCTAssertEqual(mapping.assignments.map(\.property.member), ["graphNodeID", "graphNodeLevel", "graphNodeText", "graphNodeNeighbours"])
        XCTAssertEqual(mapping.assignments.map(\.source), [.path("id"), .path("level"), .path("text"), .path("neighborIds")])
    }

    func testExpressionsAliasesModulesAndRootsAreRead() throws {
        let mapping = try MappingLine.parse(#"passage: SeerKit.Partition identifier=partitionId, depth = layer body=value.body ?? "" links=self.edges"#)
        XCTAssertEqual(mapping.role, .node, "`passage` is a node")
        XCTAssertEqual(mapping.type, "SeerKit.Partition")
        XCTAssertEqual(mapping.fileStem, "SeerKitPartition")
        XCTAssertEqual(mapping.assignments.map(\.property.key), ["id", "level", "text", "neighbours"], "aliases name their property")
        XCTAssertEqual(mapping.assignments.map(\.source), [.path("partitionId"), .path("layer"), .expression(#"value.body ?? """#), .path("edges")])
        let edge = try MappingLine.parse("link: Wire source=a.id, target=b.id")
        XCTAssertEqual(edge.role, .edge, "`link` is an edge")
        XCTAssertEqual(edge.assignments.map(\.property.member), ["graphEdgeFrom", "graphEdgeTo"])
        XCTAssertEqual(edge.assignments.map(\.source), [.path("a.id"), .path("b.id")])
    }

    func testMappingLinesThatAreRefusedSayWhy() {
        let refused: [(String, String)] = [
            ("node GraphNode id=id", "has no colon"),
            ("bubble: GraphNode id=id", "is not a role: a line starts with node or edge"),
            ("node: graphNode id=id", "is not a type name"),
            ("node: Box<Item> id=id", "is not a type name"),
            ("node: Item colour=red", "a node maps id, level, text, neighbours"),
            ("edge: Link from=a to=b weight=c", "an edge maps from, to"),
            ("node: Item id=a identifier=b", "`id` is mapped twice"),
            ("node: Item text=", "has `=` and no value"),
            ("edge: Link", "it maps nothing"),
            ("node: Item stray id=id", "`stray` is not `word=value`"),
            ("", "it is empty"),
        ]
        for (line, reason) in refused {
            XCTAssertThrowsError(try MappingLine.parse(line), line) { error in
                XCTAssertTrue("\(error)".contains(reason), "\(line) → \(error)")
            }
        }
    }

    func testEveryRoleKnowsItsWordsOnce() {
        for role in GraphRole.allCases {
            var words: Set<String> = []
            for property in role.properties {
                for word in [property.key] + property.aliases {
                    XCTAssertTrue(words.insert(word.lowercased()).inserted, "\(role).\(word) names two properties")
                }
                XCTAssertTrue(property.member.hasPrefix("graph"), "\(property.member) is namespaced")
                XCTAssertTrue(property.doc.hasSuffix("."), "\(property.member)'s doc is a sentence")
            }
            XCTAssertNotNil(role.property(named: role.properties[0].key.uppercased()), "words are read in any case")
            for key in role.required { XCTAssertNotNil(role.property(named: key), "\(role) requires \(key), which it has") }
        }
        var roleWords: Set<String> = []
        for role in GraphRole.allCases {
            for word in [role.rawValue] + role.aliases { XCTAssertTrue(roleWords.insert(word).inserted, "\(word) names two roles") }
        }
    }

    func testEachKindTakesTheFieldTypesItsConversionsTake() {
        let cases: [(GraphKind, String, Bool)] = [
            (.text, "String", true), (.text, "String?", true), (.text, "UUID", true), (.text, "URL?", true), (.text, "Int64", true),
            (.text, "[String]", false), (.text, "Date", false),
            (.level, "Int", true), (.level, "UInt8?", true), (.level, "Double", true), (.level, "CGFloat", true), (.level, "String", false),
            (.ids, "[String]", true), (.ids, "Set<String>", true), (.ids, "[UUID]?", true), (.ids, "[Int]", true),
            (.ids, "[Page]", false), (.ids, "String", false), (.ids, "[String: Int]", false),
        ]
        for (kind, type, takes) in cases { XCTAssertEqual(kind.accepts(type), takes, "\(kind) takes \(type)") }
        XCTAssertTrue(GraphKind.ids.isNothing("[]"))
        XCTAssertTrue(GraphKind.level.isNothing("0"))
        XCTAssertFalse(GraphKind.text.isNothing("title"))
    }

    // MARK: Look

    func testLookLinesMapARoleToTheAppsName() throws {
        let accepted = ["title = Font.brandTitle", "accent=Color.accent", "note2 = .footnote", "PASSAGE = Font.body", "hubBadge = Color(red: 0.3, green: 0.3, blue: 0.8)"]
        for line in accepted {
            guard case .success = LookLine.parse(line, roles: GraphTables.look) else { return XCTFail(line) }
        }
        guard case .success(let parsed) = LookLine.parse("note = Font.brandNote", roles: GraphTables.look) else { return XCTFail() }
        XCTAssertEqual(parsed.role.key, "note")
        XCTAssertEqual(parsed.expression, "Font.brandNote")
    }

    func testLookLinesThatAreRefusedSayWhy() {
        let refused: [(String, String)] = [
            ("title Font.brandTitle", "a look line is `role = the app's name`"),
            ("hero = Font.brandTitle", "`hero` is not a look role; the roles are title, note"),
            ("title = Color.accent", "`title` is a Font"),
            ("accent = \"bronze\"", "`accent` is a Color"),
        ]
        for (line, reason) in refused {
            guard case .failure(let error) = LookLine.parse(line, roles: GraphTables.look) else { XCTFail(line); continue }
            XCTAssertTrue("\(error)".contains(reason), "\(line) → \(error)")
        }
    }

    // MARK: Strings

    func testStringsLinesSetAWordQuotedOrNot() throws {
        let cases: [(String, String, String)] = [
            ("title = Atlas", "title", "Atlas"),
            ("hub = L{level} Hub", "hub", "L{level} Hub"),
            ("loading = \"Connecting…\"", "loading", "Connecting…"),
            ("empty = Add your first document to see your knowledge graph.", "empty", "Add your first document to see your knowledge graph."),
            ("empty = \"Nothing here,\\nyet.\"", "empty", "Nothing here,\nyet."),
            ("title =", "title", ""),
        ]
        for (line, key, text) in cases {
            guard case .success(let parsed) = StringsLine.parse(line, keys: GraphTables.strings) else { XCTFail(line); continue }
            XCTAssertEqual(parsed.key.key, key, line)
            XCTAssertEqual(parsed.text, text, line)
        }
    }

    func testStringsLinesThatAreRefusedSayWhy() {
        let refused: [(String, String)] = [
            ("title: Atlas", "a strings line is `key = words`"),
            ("colour = red", "`colour` is not a string key; the keys are title, hub"),
            ("title = \"\"", "`title` is empty: say it in words, write `title =` alone for none, or leave the line out"),
            ("leaf =", "`leaf` is empty: say it in words or leave the line out for \"Leaf\""),
            ("hub = Hub", "`hub` says `{level}`"),
            ("leaf = Leaf {level}", "`leaf` says no `{…}`"),
        ]
        for (line, reason) in refused {
            guard case .failure(let error) = StringsLine.parse(line, keys: GraphTables.strings) else { XCTFail(line); continue }
            XCTAssertTrue("\(error)".contains(reason), "\(line) → \(error)")
        }
    }

    // MARK: Tuning

    func testTuningLinesAreMadeRegular() throws {
        let cases: [(String, String)] = [
            ("hubRadius = 0.45", "0.45"), ("ringRadius = 3", "3"), ("excerpt = 240", "240"), ("badgeDesign = Serif", "serif"),
            ("panelMaterial = ultraThin", "ultraThin"), ("panelMaterial = thinMaterial", "thin"),
            ("fitSymbol = rectangle.expand.diagonal", "rectangle.expand.diagonal"),
            ("showAnimation = .spring(response: 0.4, dampingFraction: 0.8)", ".spring(response: 0.4, dampingFraction: 0.8)"),
            ("showAnimation = spring(response:0.4,dampingFraction:0.8)", ".spring(response: 0.4, dampingFraction: 0.8)"),
            ("showAnimation = .smooth", ".smooth"),
            ("layout = Force", "force"), ("hubLeaves = named", "named"), ("bodySeed = 19106", "19106"),
        ]
        for (line, value) in cases {
            guard case .success(let parsed) = TuningLine.parse(line, keys: GraphTables.tuning) else { XCTFail(line); continue }
            XCTAssertEqual(parsed.value, value, line)
        }
    }

    func testTuningLinesThatAreRefusedSayWhy() {
        let refused: [(String, String)] = [
            ("hubRadius 0.45", "a tuning line is `key = value`"),
            ("nodeRadius = 0.45", "`nodeRadius` is not a tuning key; the keys are hubRadius"),
            ("hubRadius = big", "`hubRadius` takes a number"),
            ("excerpt = 2.5", "`excerpt` takes a whole number"),
            ("fitSymbol = Expand All", "`fitSymbol` takes an SF Symbol's name"),
            ("badgeDesign = comic", "`badgeDesign` takes a font design"),
            ("panelMaterial = glass", "`panelMaterial` takes a material"),
            ("showAnimation = .wobble(3)", "`showAnimation` takes an animation"),
            ("layout = grid", "`layout` takes a layout: circle or force"),
            ("hubLeaves = all", "`hubLeaves` takes a leaf rule: joined or named"),
        ]
        for (line, reason) in refused {
            guard case .failure(let error) = TuningLine.parse(line, keys: GraphTables.tuning) else { XCTFail(line); continue }
            XCTAssertTrue("\(error)".contains(reason), "\(line) → \(error)")
        }
    }

    // MARK: Launch

    func testLaunchLinesMapADestinationToAStateAndItsIDs() throws {
        guard case .success(let parsed) = LaunchLine.parse("atlas = graph(space-001, space-002, \"space-003\")", states: GraphTables.launch) else { return XCTFail() }
        XCTAssertEqual(parsed.destination, "atlas")
        XCTAssertEqual(parsed.state.name, "graph")
        XCTAssertEqual(parsed.ids, ["space-001", "space-002", "space-003"])
        guard case .success(let plain) = LaunchLine.parse("atlas.text = text", states: GraphTables.launch) else { return XCTFail() }
        XCTAssertEqual(plain.state.name, "text")
        XCTAssertEqual(plain.ids, [], "no ids: the page's own")
    }

    func testLaunchLinesThatAreRefusedSayWhy() {
        let refused: [(String, String)] = [
            ("atlas graph", "a launch line is `destination = state`"),
            ("the atlas = graph", "is not a destination name"),
            ("atlas = map(a)", "`map` is not a state the kit opens in; the states are graph and text"),
        ]
        for (line, reason) in refused {
            guard case .failure(let error) = LaunchLine.parse(line, states: GraphTables.launch) else { XCTFail(line); continue }
            XCTAssertTrue("\(error)".contains(reason), "\(line) → \(error)")
        }
    }

    func testEveryKeyIsKnownOnceAndDocumented() {
        for (name, keys) in [("look", GraphTables.look.map(\.key)), ("strings", GraphTables.strings.map(\.key)),
                             ("tuning", GraphTables.tuning.map(\.key)), ("launch", GraphTables.launch.map(\.name))] {
            XCTAssertEqual(Set(keys).count, keys.count, "\(name) names a key twice")
        }
        for key in GraphTables.strings { XCTAssertTrue(key.doc.hasSuffix("."), key.key) }
        for key in GraphTables.tuning {
            XCTAssertNotNil(TuningLine.regular(key.value, as: key.kind), "\(key.key)'s default reads as \(key.kind)")
            XCTAssertTrue(key.doc.hasSuffix("."), key.key)
        }
        for role in GraphTables.look where !role.fallback.contains("\n") {
            XCTAssertTrue(LookLine.shaped(role.fallback, as: role.kind), "\(role.key)'s fallback reads as a \(role.kind.rawValue)")
        }
    }
}
