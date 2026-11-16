//  WHAT: What a call writes: the parts, the template flags, and the value of every `{{key}}`.

import Foundation

struct KitPlan: Sendable {
    /// The tuning, every key: the call's value or the default, made regular.
    let tuning: [String: String]
    /// The launch states some launch line opens.
    let launched: Set<String>
    /// The call's words: whether the title says anything decides whether the bar shows one.
    var strings: [String: String] = [:]

    /// The parts written, in the catalog's order.
    var parts: [KitPart] { KitCatalog.parts.filter { $0.flag.map { flags.contains($0) } ?? true } }

    /// `launch.X` for each state a line opens; `key.word` for each key that chooses among words (`layout.force`,
    /// `hubLeaves.joined`); `leafSpread` when a leaf's radius varies; `bodySeed` when the bodies are drawn from more
    /// than their ids; `title` unless a line sets the title to nothing.
    var flags: Set<String> {
        var flags = Set(launched.map { "launch." + $0 })
        for key in GraphTables.tuning where key.kind.choices != nil { flags.insert(key.key + "." + setting(key.key)) }
        if let spread = Double(setting("leafRadiusSpread")), spread > 0 { flags.insert("leafSpread") }
        if let seed = Int(setting("bodySeed")), seed != 0 { flags.insert("bodySeed") }
        if strings["title"] != "" { flags.insert("title") }
        return flags
    }

    /// Each template placeholder's text: `hubRadius` is `0.45`, `panelMaterial` is `ultraThinMaterial`, and
    /// `clayDetail.total` what the clay's three octaves weigh together, so its noise stays between 0 and 1.
    var values: [String: String] {
        var values: [String: String] = [:]
        for key in GraphTables.tuning {
            for (name, text) in TuningLine.placeholders(key, value: setting(key.key)) { values[name] = text }
        }
        let detail = Double(setting("clayDetail")) ?? 0.5
        values["clayDetail.total"] = Self.decimal(0.5 * (1 + detail + detail * detail))
        return values
    }

    /// The view types written, the root first.
    var views: [String] {
        let views = parts.filter(\.isView).map(\.name)
        return ["GraphView"] + views.filter { $0 != "GraphView" }
    }

    /// A tuning key's value: the call's, else the default.
    private func setting(_ key: String) -> String {
        tuning[key] ?? GraphTables.tuning.first { $0.key == key }?.value ?? ""
    }

    /// `number` as a decimal of up to four places, with no trailing zeros and always a point: `0.875`, `1.0`.
    static func decimal(_ number: Double) -> String {
        var text = String(format: "%.4f", number)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text += "0" }
        return text
    }
}
