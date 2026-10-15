//
//  RecipeJSON.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  Recipes as JSON: written pretty, key-sorted and with slashes left alone,
//  so a recipe diffs well and replays byte for byte; read strictly — a
//  newer format, a key the format does not have, or a value of the wrong
//  type is an error that names the field, never a quiet difference. A
//  section can sit in every item of an array (`layers.*.params`).
//

import Foundation

public enum RecipeJSON {

    /// Pretty, key-sorted JSON with slashes left alone.
    public static func encoded<Value: Encodable>(_ value: Value) throws(RecipeError) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        do { return try encoder.encode(value) } catch { throw RecipeError(error.localizedDescription) }
    }

    /// A recipe from JSON, refusing a newer format and any key `format` does
    /// not list. `check` sees the parsed object after the keys pass and
    /// before decoding — for a rule a type cannot say (a seed's range).
    public static func decoded<Value: Decodable>(
        _ data: Data, as type: Value.Type = Value.self, format: RecipeFormat,
        check: (([String: Any]) throws(RecipeError) -> Void)? = nil
    ) throws(RecipeError) -> Value {
        let object: Any
        do { object = try JSONSerialization.jsonObject(with: data) } catch { throw RecipeError("it is not JSON") }
        guard let root = object as? [String: Any] else { throw RecipeError("it is not a JSON object") }
        guard let version = root[format.versionKey] as? Int else {
            throw RecipeError("it has no \"\(format.versionKey)\": \(format.version) — the format version")
        }
        guard (1...max(1, format.version)).contains(version) else {
            throw RecipeError("it is format \(version); this reads format \(format.version)")
        }
        try unknownKeys(in: root, known: format.rootKeys, at: "", suggests: format.suggests)
        for section in format.sections {
            for (path, value) in values(at: section.path, in: root) where !(value is NSNull) {
                guard let object = value as? [String: Any] else { throw RecipeError("\"\(path)\" is not an object") }
                try unknownKeys(in: object, known: section.keys, at: path + ".", suggests: format.suggests)
            }
        }
        try check?(root)
        do { return try JSONDecoder().decode(Value.self, from: data) } catch let DecodingError.typeMismatch(_, context) {
            throw RecipeError("\(path(context.codingPath)) has the wrong type")
        } catch let DecodingError.keyNotFound(key, context) {
            throw RecipeError("\(path(context.codingPath + [key])) is missing")
        } catch let DecodingError.dataCorrupted(context) {
            // A number the field's type cannot hold (-7 for a UInt64) comes
            // with no path; the underlying error says which number.
            guard context.codingPath.isEmpty else { throw RecipeError("\(path(context.codingPath)) is not a value it can hold") }
            let detail = (context.underlyingError as NSError?)?.userInfo["NSDebugDescription"] as? String ?? context.debugDescription
            throw RecipeError("a value is not one its field can hold: \(detail)")
        } catch {
            throw RecipeError(error.localizedDescription)
        }
    }

    /// Refuses the first key (alphabetically) of `object` that `known` does
    /// not list, naming every key it could have been — or, with `suggests`,
    /// only the one it was most likely meant to be, when one is close.
    /// `noun` says what kind of file the field belongs to: `a recipe field`,
    /// `a design field`.
    public static func unknownKeys(in object: [String: Any], known: [String], at prefix: String,
                                   suggests: Bool = false, noun: String = "recipe") throws(RecipeError) {
        try unknownKeys(Array(object.keys), known: known, at: prefix, suggests: suggests, noun: noun)
    }

    /// ``unknownKeys(in:known:at:suggests:noun:)`` for the keys alone.
    static func unknownKeys(_ keys: [String], known: [String], at prefix: String,
                            suggests: Bool, noun: String) throws(RecipeError) {
        guard let unknown = keys.sorted().first(where: { !known.contains($0) }) else { return }
        if suggests, let close = FieldPaths.closest(unknown, among: known) {
            throw RecipeError("\(prefix)\(unknown) is not a \(noun) field — did you mean \(prefix)\(close)?")
        }
        throw RecipeError("\(prefix)\(unknown) is not a \(noun) field (\(known.map { prefix + $0 }.joined(separator: ", ")))")
    }

    /// A decoding path as a dotted field name: `settings.seed`, `scenes.2`.
    public static func path(_ keys: [any CodingKey]) -> String {
        keys.map { $0.intValue.map(String.init) ?? $0.stringValue }.joined(separator: ".")
    }

    /// The values at a dotted path, each with its own path: one, or none when
    /// a step is missing or not an object. A `*` step goes into every item of
    /// an array — `layers.*.params` is each layer's `params`, at
    /// `layers.0.params`, `layers.1.params` — and finds nothing in anything else.
    static func values(at path: String, in root: [String: Any]) -> [(path: String, value: Any)] {
        var found: [(path: [String], value: Any)] = [([], root)]
        for key in path.split(separator: ".").map(String.init) {
            found = found.flatMap { step -> [(path: [String], value: Any)] in
                if key == "*" {
                    guard let array = step.value as? [Any] else { return [] }
                    return array.enumerated().map { (step.path + [String($0.offset)], $0.element) }
                }
                guard let value = (step.value as? [String: Any])?[key] else { return [] }
                return [(step.path + [key], value)]
            }
        }
        return found.map { ($0.path.joined(separator: "."), $0.value) }
    }
}
