//  WHAT: The template of `GraphBar.swift`: the graph's bar, its title and its three buttons.

extension Template {
    static let graphBar = ##"""
    import SwiftUI

    /// The graph's bar: its title inline in the look's title, a leading button that fits the whole graph in view, and
    /// two trailing ones that step through the nodes, level by level. The app's own bar items stay where it put them.
    struct GraphBar: ViewModifier {
        let title: String
        let enabled: Bool
        let fit: @MainActor () -> Void
        let previous: @MainActor () -> Void
        let next: @MainActor () -> Void

        func body(content: Content) -> some View {
            content
                .navigationTitle(title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(title)
                            .font(GraphLook.title)
                            .foregroundStyle(GraphLook.foreground.opacity(0.75))
                            .lineLimit(1)
                    }
                    ToolbarItem(placement: leading) {
                        button("{{fitSymbol}}", GraphStrings.fit) { fit() }
                    }
                    ToolbarItem(placement: trailing) {
                        button("{{previousSymbol}}", GraphStrings.previous) { previous() }
                    }
                    ToolbarItem(placement: trailing) {
                        button("{{nextSymbol}}", GraphStrings.next) { next() }
                    }
                }
        }

        private var leading: ToolbarItemPlacement {
            #if os(iOS)
            .topBarLeading
            #else
            .navigation
            #endif
        }

        private var trailing: ToolbarItemPlacement {
            #if os(iOS)
            .topBarTrailing
            #else
            .primaryAction
            #endif
        }

        private func button(_ symbol: String, _ label: String, action: @escaping @MainActor () -> Void) -> some View {
            Button {
                GraphHaptic.light()
                action()
            } label: {
                Image(systemName: symbol)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(GraphLook.accent)
            }
            .disabled(!enabled)
            .accessibilityLabel(label)
        }
    }

    #Preview {
        NavigationStack {
            Color.clear
                .modifier(GraphBar(title: GraphStrings.title, enabled: true, fit: {}, previous: {}, next: {}))
        }
    }
    """##
}
