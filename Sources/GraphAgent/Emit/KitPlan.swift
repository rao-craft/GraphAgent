//  WHAT: What a call writes: the parts, the template flags, and the value of every `{{key}}`.

import Foundation

struct KitPlan: Sendable {
    /// The tuning, every key: the call's value or the default, made regular.
    let tuning: [String: String]
    /// The launch states some launch line opens.
    let launched: Set<String>

    /// The parts written, in the catalog's order.
    var parts: [KitPart] { KitCatalog.parts.filter { $0.flag.map { flags.contains($0) } ?? true } }

    /// `launch.X` for each state a line opens.
    var flags: Set<String> { Set(launched.map { "launch." + $0 }) }

    /// Each template placeholder's text: `hubRadius` is `0.45`, `panelMaterial` is `ultraThinMaterial`.
    var values: [String: String] {
        var values: [String: String] = [:]
        for key in GraphTables.tuning {
            for (name, value) in TuningLine.placeholders(key, value: tuning[key.key] ?? key.value) { values[name] = value }
        }
        return values
    }

    /// The view types written, the root first.
    var views: [String] {
        let views = parts.filter(\.isView).map(\.name)
        return ["GraphView"] + views.filter { $0 != "GraphView" }
    }
}
