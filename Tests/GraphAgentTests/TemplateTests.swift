import Foundation
import XCTest
@testable import GraphAgent

/// The templates held to the catalog and the tables, so no call can write a file that reads a word, a number, a
/// look role or a requirement that does not exist, leaves a name unprefixed, or keeps a marker.
final class TemplateTests: XCTestCase {
    private var templates: [(part: KitPart, text: String)] {
        KitCatalog.parts.filter { !$0.template.isEmpty }.map { ($0, $0.template) }
    }

    /// Every way a call can set the flags: none, and every one the other way (every state launched, the force layout,
    /// the leaves a hub names, leaves that vary, bodies from a seed, no title).
    private var plans: [KitPlan] {
        let every = Set(GraphTables.launch.map(\.name))
        let other = ["layout": "force", "hubLeaves": "named", "leafRadiusSpread": "0.04", "bodySeed": "7"]
        return [KitPlan(tuning: [:], launched: []), KitPlan(tuning: [:], launched: every),
                KitPlan(tuning: other, launched: every, strings: ["title": ""])]
    }

    private func matches(_ pattern: String, in text: String, group: Int = 0) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap {
            Range($0.range(at: group), in: text).map { String(text[$0]) }
        }
    }

    func testEveryTemplateRendersWithEveryFlagAndEveryPlaceholderFilled() throws {
        for plan in plans {
            for part in plan.parts where !part.template.isEmpty {
                let rendered = try TemplateRender.render(part.template, flags: plan.flags, values: plan.values)
                XCTAssertFalse(rendered.contains("//@"), "\(part.name) keeps a marker")
                XCTAssertFalse(rendered.contains("{{"), "\(part.name) keeps a placeholder")
            }
        }
    }

    /// A key is used as a `{{key}}` or, when it chooses among words, as the flags `key.word` the templates read.
    func testEveryPlaceholderIsATuningKeyAndEveryKeyIsUsed() {
        let known = Set(KitPlan(tuning: [:], launched: []).values.keys)
        var used: Set<String> = [], read: Set<String> = []
        for (part, text) in templates {
            for key in TemplateRender.placeholders(in: text) {
                XCTAssertTrue(known.contains(key), "\(part.name) uses {{\(key)}}, which no tuning key fills")
                used.insert(key.components(separatedBy: ".")[0])
            }
            for condition in matches(#"(?m)^\s*//@if (.+)$"#, in: text, group: 1) {
                read.formUnion(condition.components(separatedBy: CharacterSet(charactersIn: "|&! ")).filter { !$0.isEmpty })
            }
        }
        for key in GraphTables.tuning {
            if let choices = key.kind.choices {
                XCTAssertTrue(choices.contains { read.contains(key.key + "." + $0) }, "no template reads the tuning key \(key.key)")
            } else {
                XCTAssertTrue(used.contains(key.key), "no template uses the tuning key \(key.key)")
            }
        }
    }

    func testEveryWordATemplateSaysIsAStringKeyAndEveryKeyIsSaid() {
        let members = Set(GraphTables.strings.filter { !$0.isSingular }.map(\.member))
        var said: Set<String> = []
        for (part, text) in templates {
            for member in matches(#"GraphStrings\.([a-zA-Z]+)"#, in: text, group: 1) {
                XCTAssertTrue(members.contains(member), "\(part.name) says GraphStrings.\(member), which no key declares")
                said.insert(member)
            }
        }
        for key in GraphTables.strings where !key.isSingular {
            XCTAssertTrue(said.contains(key.member), "no template says \(key.key)")
        }
    }

    func testEveryLookRoleIsReadAndNoOther() {
        let roles = Set(GraphTables.look.map(\.key))
        var read: Set<String> = []
        for (part, text) in templates {
            for role in matches(#"GraphLook\.([a-zA-Z0-9]+)"#, in: text, group: 1) {
                XCTAssertTrue(roles.contains(role), "\(part.name) reads GraphLook.\(role), which is not a look role")
                read.insert(role)
            }
        }
        XCTAssertEqual(read, roles, "every look role is read somewhere")
    }

    func testEveryRequirementATemplateReadsIsInTheRoleTable() {
        let requirements = Set(GraphRole.allCases.flatMap { $0.properties.map(\.member) })
        var read: Set<String> = []
        for (part, text) in templates {
            for member in Set(matches(#"\.(graph(?:Node|Edge)[A-Z][A-Za-z]*)"#, in: text, group: 1)) {
                XCTAssertTrue(requirements.contains(member), "\(part.name) reads \(member), which no role declares")
                read.insert(member)
            }
        }
        XCTAssertEqual(read, requirements, "every requirement is read somewhere")
    }

    func testEveryTypeAPartDeclaresIsListedForRenaming() {
        for (part, text) in templates {
            let declared = matches(#"(?m)^(?:struct|enum|final class|class) (Graph[A-Za-z]*)"#, in: text, group: 1)
            XCTAssertEqual(Set(declared), Set(part.types), "\(part.name) declares \(declared), lists \(part.types)")
        }
        let protocols = ProtocolsEmitter.emit()
        let declared = matches(#"(?m)^(?:protocol|struct) (Graph[A-Za-z]*)"#, in: protocols, group: 1)
        XCTAssertEqual(Set(declared), Set(KitCatalog.part("GraphProtocols")!.types))
        for name in KitCatalog.names { XCTAssertTrue(name.hasPrefix(KitCatalog.base), name) }
    }

    func testTheProtocolFileDeclaresEveryRequirementWithItsDefault() {
        let text = ProtocolsEmitter.emit()
        for role in GraphRole.allCases {
            XCTAssertTrue(text.contains("protocol \(role.protocolName("Graph")) {"), "\(role)")
            for property in role.properties {
                XCTAssertTrue(text.contains("    var \(property.member): \(property.kind.swiftType) { get }"), property.member)
                XCTAssertTrue(text.contains("    var \(property.member): \(property.kind.swiftType) { \(property.defaultValue) }"), property.member)
            }
            XCTAssertTrue(text.contains("struct \(role.itemType("Graph")): \(role.protocolName("Graph")) {"), "the kit's own \(role)")
        }
    }

    func testTheRootOpensEveryLaunchState() throws {
        let plan = KitPlan(tuning: [:], launched: [])
        let root = try TemplateRender.render(KitCatalog.part("GraphView")!.template, flags: plan.flags, values: plan.values)
        for state in GraphTables.launch { XCTAssertTrue(root.contains("case .\(state.name):"), "the root opens \(state.name)") }
        let launch = LaunchEmitter.emit([])
        for state in GraphTables.launch { XCTAssertTrue(launch.contains("case \(state.name)([String])\n"), state.name) }
        XCTAssertTrue(launch.contains("static var state: State? {\n        nil\n    }"), "no line: a plain launch")
    }

    /// The scene holds nothing but spheres and cylinders: no text, no axes, no floor.
    func testTheSceneDrawsOnlySpheresAndCylinders() throws {
        let plan = KitPlan(tuning: [:], launched: [])
        let stage = try TemplateRender.render(KitCatalog.part("GraphStage")!.template, flags: plan.flags, values: plan.values)
        let geometries = Set(matches(#"\b(SCN[A-Z][A-Za-z]*)\("#, in: stage, group: 1)).filter {
            !["SCNScene", "SCNNode", "SCNCamera", "SCNLight", "SCNMaterial", "SCNVector3"].contains($0)
        }
        XCTAssertEqual(geometries, ["SCNSphere", "SCNCylinder"])
        XCTAssertFalse(stage.contains("SCNText") || stage.contains("SCNFloor") || stage.contains("showsStatistics"))
    }

    func testRenamingTouchesOnlyTheKitsNames() {
        let text = "struct GraphView {}\nlet a = GraphViewModel()\nextension Graph: GraphNodeRepresentable {}\nText(\"Graph\")"
        XCTAssertEqual(TemplateRender.renaming(text, names: KitCatalog.names, base: "Graph", prefix: "Wiki"),
                       "struct WikiView {}\nlet a = GraphViewModel()\nextension Graph: WikiNodeRepresentable {}\nText(\"Graph\")")
    }
}
