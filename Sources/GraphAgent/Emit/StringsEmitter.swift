//  WHAT: `GraphStrings.swift`: every word the views say, one static member a key, the call's words where a
//        `strings` line sets them and the kit's own elsewhere. A word that says something (`L{level} Hub`) is a
//        function of it; a key with a `.one` form says one with it.

import Foundation

enum StringsEmitter {
    static func emit(_ set: [String: String], flags: Set<String>) -> String {
        var lines = [
            "import Foundation",
            "",
            "/// Every word the graph views say. The call's `strings` lines set them; the rest are the kit's own.",
            "enum GraphStrings {",
        ]
        let keys = GraphTables.strings.filter { key in key.part.map { flags.contains($0) } ?? true }
        func text(_ key: StringKey) -> String { set[key.key] ?? key.text }
        for key in keys where !key.isSingular {
            lines.append("    /// \(key.doc)")
            let placeholders = key.placeholders
            if placeholders.isEmpty {
                lines.append("    static var \(key.member): String { \(SwiftName.literal(text(key))) }")
                continue
            }
            let parameters = placeholders.map { "_ \($0): Int" }.joined(separator: ", ")
            let many = SwiftName.literal(text(key), placeholders: placeholders)
            if let one = keys.first(where: { $0.key == key.key + ".one" }), placeholders.contains("count") {
                let single = SwiftName.literal(text(one), placeholders: placeholders)
                lines.append("    static func \(key.member)(\(parameters)) -> String { count == 1 ? \(single) : \(many) }")
            } else {
                lines.append("    static func \(key.member)(\(parameters)) -> String { \(many) }")
            }
        }
        lines.append("}")
        return TemplateRender.tidy(lines)
    }
}
