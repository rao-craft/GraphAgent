import Foundation
@testable import GraphAgent

enum Fixture {
    /// A folder of its own for one test, removed with the process's temporary files.
    static func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("graph-\(UUID().uuidString.prefix(8))", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// The package's own folder, so the tests read the examples the schema ships.
    static let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()

    /// A call in `Schema/examples/<name>.json`, as a host decodes it.
    static func example(_ name: String) throws -> GraphAgent.Input {
        let data = try Data(contentsOf: package.appendingPathComponent("Schema/examples/\(name).json"))
        return try JSONDecoder().decode(GraphAgent.Input.self, from: data)
    }

    /// The text of the file `name` among `paths`.
    static func text(_ paths: [String], _ name: String) throws -> String {
        guard let path = paths.first(where: { $0.hasSuffix("/" + name) }) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: name])
        }
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    /// Every Swift file written, joined: what the scorecard's code facts are searched over.
    static func all(_ paths: [String]) throws -> String {
        try paths.filter { $0.hasSuffix(".swift") && FileManager.default.fileExists(atPath: $0) }.sorted()
            .map { try String(contentsOfFile: $0, encoding: .utf8) }.joined(separator: "\n")
    }

    /// The `code` items of the scorecard's `atlas` area (`.work/measure/task/seer/scorecard.json`): each pattern must
    /// match somewhere in the Seer call's output.
    static let scorecard: [(id: String, all: [String])] = [
        ("B-atlas-4", ["import SceneKit", "SCNView|SceneView", "allowsCameraControl"]),
        ("B-atlas-5", ["SCNSphere", "SCNCylinder"]),
        ("B-atlas-6", [" Hub\"", "\"Leaf\"", #"\b240\b"#]),
        ("B-atlas-7", [#"\b0\.45\b"#, #"\b0\.18\b"#, #"\b1\.12\b"#]),
        ("B-atlas-8", ["Connecting(…|\\.\\.\\.)"]),
    ]

    /// B-data-8, the mock graph's node ids (`<document>#0`): `$mocks`' and the app's to write, never the kit's.
    static let mockIDs = ##"#0"|#\\\("##

    /// Every word the spec quotes for the Atlas sheet, as the code says it: the badge that carries a level is checked
    /// by its words around the level (`"L2 Hub"` is `"L\(` and ` Hub"`).
    static let quoted = ["\"Atlas\"", "\"L\\(", " Hub\"", "\"Leaf\"", "\"Connecting…\""]

    /// SeerKit as the Seer call reads it: the graph's node, in a package of its own.
    static let seerKit = """
    import Foundation

    public struct GraphNode: Codable, Sendable, Identifiable {
        public var id: String
        public var level: Int
        public var text: String
        public var neighborIds: [String]

        public init(id: String, level: Int, text: String, neighborIds: [String]) {
            self.id = id; self.level = level; self.text = text; self.neighborIds = neighborIds
        }
    }
    """

    /// The wiki's own types, as the second example maps them: pages, and the links between them kept apart.
    static let wikiModels = """
    import Foundation

    struct Page {
        var slug: String
        var depth: Int
        var summary: String?
        var title: String
    }

    struct PageLink {
        var source: String
        var target: String
    }
    """
}
