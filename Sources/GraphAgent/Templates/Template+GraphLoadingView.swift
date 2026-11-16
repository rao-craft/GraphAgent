//  WHAT: The template of `GraphLoadingView.swift`: the spinner and its words while the graph loads.

extension Template {
    static let graphLoadingView = ##"""
    import SwiftUI

    /// A large spinner over the loading words, centred in the space the graph will take.
    struct GraphLoadingView: View {
        var body: some View {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text(GraphStrings.loading)
                    .font(GraphLook.note2)
                    .italic()
                    .foregroundStyle(GraphLook.foreground.opacity(0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    #Preview {
        GraphLoadingView()
    }
    """##
}
