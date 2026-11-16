//  WHAT: What a role property holds, and how a mapped value becomes it: its Swift type, its default, and the
//        `GraphValue` conversion a conformance wraps every right side in.
//  PIN:  EVERY RIGHT SIDE IS CONVERTED. An app's id may be a `String`, a `UUID` or a number, its level an `Int` or a
//        `Double`, its neighbours a list or a set of ids; `GraphValue` has an overload for each, so a bare path
//        compiles whatever the field's type.

import Foundation

enum GraphKind: Sendable, Equatable {
    /// Words or an id.
    case text
    /// A whole number: a node's level.
    case level
    /// Ids, in a list or a set.
    case ids

    /// The requirement's type in the protocol.
    var swiftType: String {
        switch self {
        case .text: return "String"
        case .level: return "Int"
        case .ids: return "[String]"
        }
    }

    /// What a type that does not map the property shows.
    var defaultValue: String {
        switch self {
        case .text: return "\"\""
        case .level: return "0"
        case .ids: return "[]"
        }
    }

    /// The `GraphValue` function a mapped value goes through.
    var conversion: String {
        switch self {
        case .text: return "text"
        case .level: return "level"
        case .ids: return "ids"
        }
    }

    static let integers: Set<String> = ["Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64"]

    /// The field types `GraphValue`'s overloads for this kind take, optional or not; ids are read by their brackets.
    var takes: Set<String> {
        switch self {
        case .text: return Self.integers.union(["String", "Substring", "UUID", "URL"])
        case .level: return Self.integers.union(["Double", "Float", "CGFloat"])
        case .ids: return Self.integers.union(["String", "Substring", "UUID"])
        }
    }

    /// What `takes` says, in words, for a refusal.
    var takesInWords: String {
        switch self {
        case .text: return "text (a String, a UUID, a URL or a whole number)"
        case .level: return "a level (a whole number, or a Double, rounded)"
        case .ids: return "ids (a list or a set of Strings, UUIDs or whole numbers)"
        }
    }

    /// Whether a field written as `type` (as the app declares it) can be read as this kind.
    func accepts(_ type: String) -> Bool {
        var base = type.replacingOccurrences(of: " ", with: "")
        while base.hasSuffix("?") || base.hasSuffix("!") { base.removeLast() }
        switch self {
        case .ids:
            var element = base
            if element.hasPrefix("["), element.hasSuffix("]"), !element.contains(":") {
                element = String(element.dropFirst().dropLast())
            } else if element.hasPrefix("Set<"), element.hasSuffix(">") {
                element = String(element.dropFirst(4).dropLast())
            } else {
                return false
            }
            return takes.contains(element)
        default:
            return takes.contains(base)
        }
    }

    /// A right side that says the property has nothing: what leaving it out already shows.
    func isNothing(_ value: String) -> Bool {
        let text = value.trimmingCharacters(in: .whitespaces)
        return ["nil", "[]", "\"\"", ".none"].contains(text) || text == defaultValue
    }
}
