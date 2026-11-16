import Foundation

/// What a run says as it goes.
public enum GraphFrame: Sendable {
    /// The call was read: how many mapping lines, and how many views it writes.
    case read(mappings: Int, views: Int)
    /// The files are written.
    case written(GraphResult)

    public var result: GraphResult? {
        if case .written(let result) = self { return result }
        return nil
    }
}
