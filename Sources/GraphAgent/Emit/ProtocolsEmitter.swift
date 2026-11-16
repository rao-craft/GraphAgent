//  WHAT: `GraphProtocols.swift`, made from the role table: one protocol a role with a default for every
//        requirement, then the kit's own value types, which an app with no type of its own for a role uses as they are.

import Foundation

enum ProtocolsEmitter {
    static func emit() -> String {
        var lines = ["import Foundation"]
        for role in GraphRole.allCases {
            let name = role.protocolName(KitCatalog.base)
            lines += [
                "",
                "/// \(role.doc)",
                "///",
                "/// Every requirement has a default, so a type maps only what it has. The names start with `graph` so they",
                "/// never meet the type's own properties.",
                "protocol \(name) {",
            ]
            for property in role.properties {
                lines.append("    /// \(property.doc)")
                lines.append("    var \(property.member): \(property.kind.swiftType) { get }")
            }
            lines += ["}", "", "extension \(name) {"]
            for property in role.properties {
                lines.append("    var \(property.member): \(property.kind.swiftType) { \(property.defaultValue) }")
            }
            lines.append("}")
        }
        for role in GraphRole.allCases {
            let item = role.itemType(KitCatalog.base)
            lines += [
                "",
                "/// A\(role == .edge ? "n" : "") \(role.rawValue) of the kit's own, for an app with no type to map: "
                    + "`\(item)(" + role.properties.prefix(2).map { "\($0.key): …" }.joined(separator: ", ") + ")`.",
                "struct \(item): \(role.protocolName(KitCatalog.base)) {",
            ]
            for property in role.properties {
                lines.append("    var \(property.key): \(property.kind.swiftType) = \(property.kind.defaultValue)")
            }
            lines.append("")
            for property in role.properties {
                lines.append("    var \(property.member): \(property.kind.swiftType) { \(property.key) }")
            }
            lines.append("}")
        }
        return TemplateRender.tidy(lines)
    }
}
