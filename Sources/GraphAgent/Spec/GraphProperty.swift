//  WHAT: One thing a graph view reads off an app's type: the word a mapping line names it by, the requirement it
//        is in the protocol, what it holds, and the sentence that documents it.

import Foundation

struct GraphProperty: Sendable, Equatable {
    /// The word on a mapping line: `id`, `level`, `neighbours`.
    let key: String
    /// The protocol requirement: `graphNodeLevel`. Namespaced, so an app's own `level` never collides with it.
    let member: String
    let kind: GraphKind
    /// One sentence, the requirement's doc comment.
    let doc: String
    /// Other words a line may use for it.
    let aliases: [String]

    init(_ key: String, _ member: String, _ kind: GraphKind, _ doc: String, aliases: [String] = []) {
        self.key = key; self.member = member; self.kind = kind; self.doc = doc; self.aliases = aliases
    }

    /// What the protocol's extension answers for a type that does not map it.
    var defaultValue: String { kind.defaultValue }
}
