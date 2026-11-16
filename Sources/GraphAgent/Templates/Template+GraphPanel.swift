//  WHAT: The template of `GraphPanel.swift`: the card of the selected node, over the bottom of the scene.

extension Template {
    static let graphPanel = ##"""
    import SwiftUI

    /// The card of the selected node: its badge, its id and a close mark, a divider, then the start of its text; a
    /// tap on the text opens all of it in a sheet. Frosted and rounded, it floats over the bottom of the scene.
    struct GraphPanel<Node: GraphNodeRepresentable>: View {
        let node: Node
        @Binding var showsText: Bool
        let close: @MainActor () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    GraphBadge(level: node.graphNodeLevel)
                    Text(node.graphNodeID)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        close()
                    } label: {
                        Image(systemName: "{{closeSymbol}}")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(GraphStrings.close)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Divider()
                    .padding(.vertical, 10)

                Button {
                    showsText = true
                } label: {
                    Text(GraphFormat.excerpt(node.graphNodeText))
                        .font(GraphLook.passage)
                        .foregroundStyle(GraphLook.foreground)
                        .multilineTextAlignment(.leading)
                        .offset(x: 1)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 16)
            }
            .background(.{{panelMaterial}})
            .clipShape(RoundedRectangle(cornerRadius: {{panelRadius}}, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 4)
            .padding(.horizontal, 8)
            .sheet(isPresented: $showsText) {
                GraphTextSheet(text: node.graphNodeText)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    #Preview {
        GraphPanel(node: GraphSample.nodes[0], showsText: .constant(false), close: {})
            .padding(.horizontal, 16)
    }
    """##
}
