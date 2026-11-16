//  WHAT: One mapping line, read: which role an app's type takes, and how each thing the views show is read off it.

import Foundation

struct Mapping: Sendable, Equatable {
    /// How a right side reads its value.
    enum Source: Sendable, Equatable {
        /// A bare path, read off the value: `partitionId`, `document?.id`.
        case path(String)
        /// Swift that may name `value`: `value.links.map(\.id)`.
        case expression(String)
    }

    struct Assignment: Sendable, Equatable {
        let property: GraphProperty
        let source: Source
    }

    let line: String
    let role: GraphRole
    /// The app's type, as the line wrote it: `GraphNode`, `SeerKit.GraphNode`.
    let type: String
    let assignments: [Assignment]

    /// The type's name for a file: `SeerKit.GraphNode` is `SeerKitGraphNode`.
    var fileStem: String { type.replacingOccurrences(of: ".", with: "") }

    /// The assignment of the property with `key`, if the line maps it.
    func assignment(_ key: String) -> Assignment? { assignments.first { $0.property.key == key } }
}
