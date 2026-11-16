//  WHAT: The template of `GraphBadge.swift`: a node's level, as a capsule.

extension Template {
    static let graphBadge = ##"""
    import SwiftUI

    /// A node's badge: a hub's level on its colour (`GraphStrings.hub`), or a leaf's word.
    struct GraphBadge: View {
        let level: Int

        var body: some View {
            let hub = level > 0
            Text(hub ? GraphStrings.hub(level) : GraphStrings.leaf)
                .font(.system(size: {{badgeSize}}, weight: .regular, design: .{{badgeDesign}}))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(hub ? GraphLook.hubBadge.opacity(0.3) : GraphLook.leafBadge.opacity(0.2))
                .foregroundStyle(hub ? GraphLook.hubBadge : GraphLook.leafBadge)
                .clipShape(Capsule())
        }
    }

    #Preview {
        HStack {
            GraphBadge(level: 2)
            GraphBadge(level: 0)
        }
        .padding()
    }
    """##
}
