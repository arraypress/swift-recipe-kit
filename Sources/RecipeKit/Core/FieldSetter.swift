//
//  FieldSetter.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  `--set path=value` for any Codable recipe: the value is read by its
//  field's kind (``FieldParsing``), the recipe goes to JSON, the key at the
//  dotted path is replaced (or removed, for an empty value, which clears an
//  optional field and restores a defaulted one), and the JSON is decoded
//  back. So the recipe type's own decoding — its enums, its defaults — has
//  the last word, and a tool needs only a table of its fields' kinds.
//

import Foundation

public enum FieldSetter {

    /// `root` with the field at `path` (dotted, from the top of its JSON) set
    /// from `value` as typed. `trims` as in ``FieldParsing/json(_:kind:name:trims:)``.
    /// When the changed JSON does not decode — a word an enum does not have —
    /// `failure` turns the decoding error into the message to show.
    public static func set<Root: Codable>(_ path: String, to value: String, kind: FieldKind, in root: Root,
                                          trims: Bool = true,
                                          failure: (any Error) -> RecipeError) throws(RecipeError) -> Root {
        let json = try FieldParsing.json(value, kind: kind, name: path, trims: trims)
        var object: [String: Any]
        do {
            object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(root)) as? [String: Any] ?? [:]
        } catch {
            throw RecipeError("cannot read it: \(error.localizedDescription)")
        }
        object = assigning(json, at: path.split(separator: ".").map(String.init)[...], in: object)
        do {
            return try JSONDecoder().decode(Root.self, from: JSONSerialization.data(withJSONObject: object))
        } catch {
            throw failure(error)
        }
    }

    /// `object` with `value` at `keys` (removed when `nil`), making the
    /// objects on the way when they are missing.
    static func assigning(_ value: Any?, at keys: ArraySlice<String>, in object: [String: Any]) -> [String: Any] {
        guard let key = keys.first else { return object }
        var object = object
        if keys.count == 1 {
            object[key] = value
        } else {
            object[key] = assigning(value, at: keys.dropFirst(), in: object[key] as? [String: Any] ?? [:])
        }
        return object
    }
}
