//
//  RecipeJSON.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  Recipes as JSON: written pretty, key-sorted and with slashes left alone,
//  so a recipe diffs well and replays byte for byte; read strictly — a
//  newer format, a key the format does not have, or a value of the wrong
//  type is an error that names the field, never a quiet difference.
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
        try unknownKeys(in: root, known: format.rootKeys, at: "")
        for section in format.sections {
            guard let value = self.value(at: section.path, in: root), !(value is NSNull) else { continue }
            guard let object = value as? [String: Any] else { throw RecipeError("\"\(section.path)\" is not an object") }
            try unknownKeys(in: object, known: section.keys, at: section.path + ".")
        }
        try check?(root)
        do { return try JSONDecoder().decode(Value.self, from: data) } catch let DecodingError.typeMismatch(_, context) {
            throw RecipeError("\(path(context.codingPath)) has the wrong type")
        } catch let DecodingError.keyNotFound(key, context) {
            throw RecipeError("\(path(context.codingPath + [key])) is missing")
        } catch let DecodingError.dataCorrupted(context) {
            throw RecipeError("\(path(context.codingPath)) is not a value it can hold")
        } catch {
            throw RecipeError(error.localizedDescription)
        }
    }

    /// Refuses the first key (alphabetically) of `object` that `known` does
    /// not list, naming every key it could have been.
    public static func unknownKeys(in object: [String: Any], known: [String], at prefix: String) throws(RecipeError) {
        if let unknown = object.keys.sorted().first(where: { !known.contains($0) }) {
            throw RecipeError("\(prefix)\(unknown) is not a recipe field (\(known.map { prefix + $0 }.joined(separator: ", ")))")
        }
    }

    /// A decoding path as a dotted field name: `settings.seed`, `scenes.2`.
    public static func path(_ keys: [any CodingKey]) -> String {
        keys.map { $0.intValue.map(String.init) ?? $0.stringValue }.joined(separator: ".")
    }

    /// The value at a dotted path, or `nil` when a step is missing or not an object.
    static func value(at path: String, in root: [String: Any]) -> Any? {
        var current: Any? = root
        for key in path.split(separator: ".") {
            guard let object = current as? [String: Any] else { return nil }
            current = object[String(key)]
        }
        return current
    }
}
