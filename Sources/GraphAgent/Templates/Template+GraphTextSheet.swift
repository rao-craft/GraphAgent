//  WHAT: The template of `GraphTextSheet.swift`: a node's whole text, in a sheet of its own.

extension Template {
    static let graphTextSheet = ##"""
    import SwiftUI

    /// A node's whole text, its inline markdown read, under a bar with a close mark: the sheet a tap on the panel's
    /// text opens.
    struct GraphTextSheet: View {
        let text: String

        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                ScrollView {
                    Text(GraphFormat.passage(text))
                        .font(GraphLook.passage)
                        .foregroundStyle(GraphLook.foreground)
                        .offset(x: 1)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: trailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(GraphLook.accent)
                        }
                        .accessibilityLabel(GraphStrings.close)
                    }
                }
            }
        }

        private var trailing: ToolbarItemPlacement {
            #if os(iOS)
            .topBarTrailing
            #else
            .primaryAction
            #endif
        }
    }

    #Preview {
        GraphTextSheet(text: GraphSample.nodes[0].text)
    }
    """##
}
