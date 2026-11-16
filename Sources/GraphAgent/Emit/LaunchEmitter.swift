//  WHAT: `GraphLaunch.swift`: the state the root view opens in when the app is launched with `-destination <name>`,
//        and the ids it loads, from the call's `launch` lines; with none, every launch is a plain one.

import Foundation

enum LaunchEmitter {
    static func emit(_ lines: [(destination: String, state: LaunchState, ids: [String])]) -> String {
        let states = GraphTables.launch
        var out = [
            "import Foundation",
            "",
            "/// Where the graph opens when the app is launched with `-destination <name>`: how UI tests and screenshots reach",
            "/// a screen with no tap. The root view reads it as it appears: the ids it loads, and what it opens over the graph.",
            "enum GraphLaunch {",
            "    enum State: Equatable {",
        ]
        for state in states {
            out.append("        /// \(state.doc)")
            out.append("        case \(state.name)([String])")
        }
        out += [
            "",
            "        /// The ids it names; none: the page's own.",
            "        var ids: [String] {",
            "            switch self {",
            "            case " + states.map { ".\($0.name)(let ids)" }.joined(separator: ", ") + ": return ids",
            "            }",
            "        }",
            "    }",
            "",
            "    /// The state the launch asks for, or nil for a plain launch.",
            "    static var state: State? {",
        ]
        if lines.isEmpty {
            out.append("        nil")
        } else {
            out.append("        switch UserDefaults.standard.string(forKey: \"destination\") {")
            for line in lines {
                let ids = "[" + line.ids.map { SwiftName.literal($0) }.joined(separator: ", ") + "]"
                out.append("        case \(SwiftName.literal(line.destination)): return .\(line.state.name)(\(ids))")
            }
            out += ["        default: return nil", "        }"]
        }
        out += ["    }", "}"]
        return TemplateRender.tidy(out)
    }
}
