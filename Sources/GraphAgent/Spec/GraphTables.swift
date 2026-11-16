//  WHAT: Everything a call can set by name: the look roles the views read, every word they say, every number, size,
//        symbol and motion they use, and the states the root view can open in. The one source of the schema's key
//        lists, of `Graph.md`'s tables, of what a line may name, and of what the emitted enums hold.
//  PIN:  ONE TABLE EACH. A template reads a word as `GraphStrings.member` and a number as `{{key}}`; a test holds
//        every template to these tables, so a key named here is a key the views use, and the other way round.

import Foundation

enum GraphTables {
    // MARK: Look

    static let look: [LookRole] = [
        LookRole("title", .font, ".headline", "The bar's title."),
        LookRole("note", .font, ".callout", "The empty view's words and a failure's."),
        LookRole("note2", .font, ".footnote", "The line under the spinner while the graph loads."),
        LookRole("passage", .font, ".body", "A node's text, in the panel and in its sheet."),
        LookRole("accent", .color, ".accentColor", "The bar's symbols, the text sheet's close mark, and in the scene the selected node's group: the open hub, its leaves and the edges to them."),
        LookRole("foreground", .color, ".primary", "The title (at 0.75), the passage, and the status words (at 0.6)."),
        LookRole("hubBadge", .color, ".indigo", "A hub's badge: its words, on the colour at 0.3."),
        LookRole("leafBadge", .color, ".blue", "A leaf's badge: its words, on the colour at 0.2."),
    ]

    // MARK: Strings

    static let strings: [StringKey] = [
        StringKey("title", "Graph", "The bar's title."),
        StringKey("hub", "Level {level}", "A hub's badge, `{level}` its level: `L{level} Hub` reads \"L2 Hub\"."),
        StringKey("leaf", "Leaf", "A leaf's badge."),
        StringKey("loading", "Loading…", "Under the spinner while the graph loads."),
        StringKey("empty", "Nothing to show yet.", "Under the empty view's symbol, when the graph has no nodes."),
        StringKey("retry", "Retry", "The button under a failure, which loads again."),
        StringKey("close", "Close", "The accessibility label of the panel's close mark and of the text sheet's."),
        StringKey("fit", "Show All", "The accessibility label of the button that fits the whole graph in view."),
        StringKey("previous", "Previous", "The accessibility label of the button that selects the node before."),
        StringKey("next", "Next", "The accessibility label of the button that selects the node after."),
    ]

    // MARK: Tuning

    static let tuning: [TuningKey] = [
        TuningKey("hubRadius", .number, "0.45", "A hub's radius before its level adds to it."),
        TuningKey("hubRadiusStep", .number, "0.18", "What each level adds to a hub's radius."),
        TuningKey("leafRadius", .number, "0.18", "A leaf's radius."),
        TuningKey("ringRadius", .number, "3", "The circle the hubs stand on, facing the camera, the first at the top; a lone hub stands at the centre."),
        TuningKey("leafDistance", .number, "1.8", "How far a leaf stands from its hub."),
        TuningKey("edgeRadius", .number, "0.03", "An edge's radius: a cylinder from one node's centre to the other's."),
        TuningKey("cameraDistance", .number, "14", "How far back the camera stands, looking at the centre; fitting the graph in view never comes nearer."),
        TuningKey("hubFocus", .number, "18", "How far the camera stands from a hub it centres on."),
        TuningKey("leafFocus", .number, "12", "How far the camera stands from a leaf it centres on."),
        TuningKey("fieldOfView", .number, "50", "The camera's vertical field of view, in degrees."),
        TuningKey("pulseScale", .number, "1.12", "How large the selected node grows as it pulses."),
        TuningKey("pulseDuration", .number, "1", "The seconds each way of the selected node's pulse."),
        TuningKey("excerpt", .integer, "240", "How many characters of a node's text the panel shows; a tap shows all of it."),
        TuningKey("badgeSize", .number, "12", "The badge's point size."),
        TuningKey("badgeDesign", .design, "serif", "The badge's font design."),
        TuningKey("panelRadius", .number, "20", "The panel's corner radius."),
        TuningKey("panelMaterial", .material, "ultraThin", "The panel's material."),
        TuningKey("showAnimation", .animation, ".spring(response: 0.4, dampingFraction: 0.8)", "How the panel rises and leaves."),
        TuningKey("fitSymbol", .symbol, "rectangle.expand.diagonal", "The bar's leading button, which fits the whole graph in view."),
        TuningKey("previousSymbol", .symbol, "chevron.left", "The button that selects the node before."),
        TuningKey("nextSymbol", .symbol, "chevron.right", "The button that selects the node after."),
        TuningKey("closeSymbol", .symbol, "xmark.circle.fill", "The panel's close mark."),
        TuningKey("emptySymbol", .symbol, "gyroscope", "The symbol over the empty view's words."),
        TuningKey("failedSymbol", .symbol, "wifi.exclamationmark", "The symbol over a failure."),
    ]

    // MARK: Launch

    static let launch: [LaunchState] = [
        LaunchState("graph", takesIDs: true, "The graph of these ids (the page's own when none are given), the first hub selected, its leaves out and its panel up."),
        LaunchState("text", takesIDs: true, "As `graph`, with the selected node's whole text open in its sheet."),
    ]
}
