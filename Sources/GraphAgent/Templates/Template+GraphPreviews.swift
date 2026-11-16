//  WHAT: The template of `GraphPreviews.swift`: the sample graph every preview draws.

extension Template {
    static let graphPreviews = ##"""
    import Foundation

    /// A small graph for the views' previews, made of the kit's own values, so every preview works before the app
    /// maps its own types: three documents, each a hub holding its text and a leaf a sentence, joined to it.
    enum GraphSample {
        static var nodes: [GraphNodeItem] {
            document("tides", level: 2, "Tides rise and fall twice a day. The Moon pulls the near side of the ocean toward it. The Sun adds a smaller pull of its own.")
                + document("bees", level: 1, "A honeybee dances to tell the hive where flowers are. The angle of the dance points the way.")
                + document("lighthouses", level: 1, "The first lighthouses burned wood on open fires.")
        }

        /// A hub, `<name>/0`, holding the whole text, and a leaf a sentence when there are several, `<name>/1`, …
        private static func document(_ name: String, level: Int, _ text: String) -> [GraphNodeItem] {
            let sentences = text.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            let leaves = sentences.count > 1 ? sentences.indices.map { "\(name)/\($0 + 1)" } : []
            let hub = GraphNodeItem(id: "\(name)/0", level: level, text: text, neighbours: leaves)
            return [hub] + zip(leaves, sentences).map { id, sentence in
                GraphNodeItem(id: id, level: 0, text: sentence + ".", neighbours: [hub.id])
            }
        }
    }
    """##
}
