//  WHAT: The template of `GraphEmptyView.swift`: what shows when the graph has no nodes.

extension Template {
    static let graphEmptyView = ##"""
    import SwiftUI

    /// A large symbol over the empty words, centred in the space the graph would take.
    struct GraphEmptyView: View {
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "{{emptySymbol}}")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text(GraphStrings.empty)
                    .font(GraphLook.note)
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(GraphLook.foreground.opacity(0.6))
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    #Preview {
        GraphEmptyView()
    }
    """##
}
