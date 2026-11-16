//  WHAT: The two roles an app's type can take for the graph views (a node, an edge between two of them) and
//        everything each role's views read. The one source of the protocols' requirements, of what a mapping line
//        may name, and of the guide's word list.
//  PIN:  ONE TABLE. The protocol file, the conformances and the tests all read these lists, so a property added here
//        is a requirement, a mapping word and a default at once.

import Foundation

enum GraphRole: String, CaseIterable, Sendable {
    case node, edge

    /// The role's name in Swift: `Node`.
    var name: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    /// The role in words, with its article: `a node`, `an edge`.
    var named: String { (self == .edge ? "an " : "a ") + rawValue }

    /// The protocol an app's type conforms to, under the call's prefix: `GraphNodeRepresentable`.
    func protocolName(_ prefix: String) -> String { prefix + name + "Representable" }

    /// The kit's own value type for the role, when the app has none: `GraphNodeItem`.
    func itemType(_ prefix: String) -> String { prefix + name + "Item" }

    /// Other words a mapping line may start with.
    var aliases: [String] {
        switch self {
        case .node: return ["vertex", "point", "partition", "passage", "item"]
        case .edge: return ["link", "connection", "pair", "relation"]
        }
    }

    /// The properties a line of this role must map, because no default stands in for them.
    var required: [String] {
        switch self {
        case .node: return ["id"]
        case .edge: return ["from", "to"]
        }
    }

    /// What the role is, for the protocol's doc comment.
    var doc: String {
        switch self {
        case .node: return "A node as the graph views show it: a hub (level above 0, a large sphere always in view) or a leaf (level 0, a small sphere out only around its open hub)."
        case .edge: return "An edge as the graph views show it: a thin cylinder between two nodes, drawn from an open hub to its leaves."
        }
    }

    var properties: [GraphProperty] {
        switch self {
        case .node:
            return [
                .init("id", "graphNodeID", .text, "Its id: what the edges and the neighbours name it by, in small type in the panel.",
                      aliases: ["identifier", "key", "partitionId", "uid", "slug"]),
                .init("level", "graphNodeLevel", .level, "Its level: above 0 a hub, sized by it; 0 a leaf.",
                      aliases: ["layer", "depth", "tier", "rank"]),
                .init("text", "graphNodeText", .text, "Its text: the panel shows its start, its sheet all of it.",
                      aliases: ["body", "content", "passage", "summary"]),
                .init("neighbours", "graphNodeNeighbours", .ids, "The ids of the nodes it is joined to; an edge line can say the same.",
                      aliases: ["neighbors", "neighbourIds", "neighborIds", "links", "connections", "children"]),
            ]
        case .edge:
            return [
                .init("from", "graphEdgeFrom", .text, "The id of the node at one end.", aliases: ["source", "start", "parent", "a"]),
                .init("to", "graphEdgeTo", .text, "The id of the node at the other end.", aliases: ["target", "end", "child", "b"]),
            ]
        }
    }

    /// The property a mapping line's word names, by its key or an alias, any case.
    func property(named word: String) -> GraphProperty? {
        let lower = word.lowercased()
        return properties.first { $0.key.lowercased() == lower } ?? properties.first { $0.aliases.contains { $0.lowercased() == lower } }
    }

    /// The role a mapping line's first word names, by its name or an alias, any case.
    static func named(_ word: String) -> GraphRole? {
        let lower = word.lowercased()
        return GraphRole(rawValue: lower) ?? allCases.first { $0.aliases.contains(lower) }
    }
}
