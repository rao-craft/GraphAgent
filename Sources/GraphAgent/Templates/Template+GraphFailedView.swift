//  WHAT: The template of `GraphFailedView.swift`: what shows when the graph could not be loaded.

extension Template {
    static let graphFailedView = ##"""
    import SwiftUI

    /// A large red symbol over why the graph could not be loaded, and a button that loads it again.
    struct GraphFailedView: View {
        let message: String
        let retry: @MainActor () -> Void

        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "{{failedSymbol}}")
                    .font(.system(size: 56))
                    .foregroundStyle(.red.opacity(0.8))
                Text(message)
                    .font(GraphLook.note)
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(GraphLook.foreground.opacity(0.6))
                    .padding(.horizontal, 40)
                Button(GraphStrings.retry) {
                    retry()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    #Preview {
        GraphFailedView(message: "The graph could not be reached.", retry: {})
    }
    """##
}
