//  WHAT: Every file the kit can write, in the order a reader meets them: what the views read first (the protocols,
//        the conversions, the look, the words, the launch, the shared pieces, the scene), then the building blocks,
//        then the root.

import Foundation

enum KitCatalog {
    /// The name every type the kit declares starts with, which the call's `prefix` replaces.
    static let base = "Graph"

    static let parts: [KitPart] = [
        KitPart("GraphProtocols", types: ["GraphNodeRepresentable", "GraphEdgeRepresentable", "GraphNodeItem", "GraphEdgeItem"], view: false),
        KitPart("GraphValue", view: false, Template.graphValue),
        KitPart("GraphLook", view: false),
        KitPart("GraphStrings", view: false),
        KitPart("GraphLaunch", view: false),
        KitPart("GraphSupport", types: ["GraphShape", "GraphLayout", "GraphFormat", "GraphHaptic"], view: false, Template.graphSupport),
        KitPart("GraphStage", types: ["GraphStage", "GraphTone"], view: false, Template.graphStage),
        KitPart("GraphScene", Template.graphScene),
        KitPart("GraphBar", view: false, Template.graphBar),
        KitPart("GraphBadge", Template.graphBadge),
        KitPart("GraphPanel", Template.graphPanel),
        KitPart("GraphTextSheet", Template.graphTextSheet),
        KitPart("GraphLoadingView", Template.graphLoadingView),
        KitPart("GraphEmptyView", Template.graphEmptyView),
        KitPart("GraphFailedView", Template.graphFailedView),
        KitPart("GraphView", Template.graphView),
        KitPart("GraphPreviews", types: ["GraphSample"], view: false, Template.graphPreviews),
    ]

    /// Every type any call can declare, for renaming.
    static var names: [String] { parts.flatMap(\.types) }

    static func part(_ name: String) -> KitPart? { parts.first { $0.name == name } }
}
