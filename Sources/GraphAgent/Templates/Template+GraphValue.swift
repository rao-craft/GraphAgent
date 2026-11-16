//  WHAT: The template of `GraphValue.swift`: the conversions every mapped right side goes through.

extension Template {
    static let graphValue = ##"""
    import Foundation

    /// How a mapped value becomes what the graph views show: one overload a type an app's field may have, so a
    /// conformance compiles whatever the field's type (an id may be a String, a UUID, a URL or a number; a level a
    /// whole number or a Double; neighbours a list or a set of ids).
    enum GraphValue {
        static func text(_ value: String) -> String { value }
        static func text(_ value: String?) -> String { value ?? "" }
        static func text(_ value: Substring) -> String { String(value) }
        static func text(_ value: UUID) -> String { value.uuidString }
        static func text(_ value: UUID?) -> String { value?.uuidString ?? "" }
        static func text(_ value: URL) -> String { value.absoluteString }
        static func text(_ value: URL?) -> String { value?.absoluteString ?? "" }
        static func text<T: BinaryInteger>(_ value: T) -> String { String(value) }
        static func text<T: BinaryInteger>(_ value: T?) -> String { value.map { String($0) } ?? "" }

        static func level<T: BinaryInteger>(_ value: T) -> Int { Int(value) }
        static func level<T: BinaryInteger>(_ value: T?) -> Int { value.map { Int($0) } ?? 0 }
        static func level<T: BinaryFloatingPoint>(_ value: T) -> Int { value.isFinite ? Int(value.rounded()) : 0 }
        static func level<T: BinaryFloatingPoint>(_ value: T?) -> Int { value.map { level($0) } ?? 0 }

        static func ids<S: Sequence>(_ value: S) -> [String] where S.Element == String { Array(value) }
        static func ids<S: Sequence>(_ value: S?) -> [String] where S.Element == String { value.map { Array($0) } ?? [] }
        static func ids<S: Sequence>(_ value: S) -> [String] where S.Element == Substring { value.map { String($0) } }
        static func ids<S: Sequence>(_ value: S) -> [String] where S.Element == UUID { value.map { $0.uuidString } }
        static func ids<S: Sequence>(_ value: S?) -> [String] where S.Element == UUID { value.map { $0.map { $0.uuidString } } ?? [] }
        static func ids<S: Sequence>(_ value: S) -> [String] where S.Element: BinaryInteger { value.map { String($0) } }
        static func ids<S: Sequence>(_ value: S?) -> [String] where S.Element: BinaryInteger { value.map { $0.map { String($0) } } ?? [] }
    }
    """##
}
