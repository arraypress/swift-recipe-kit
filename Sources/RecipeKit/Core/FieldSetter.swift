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
//  the last word, and a tool needs only a table of its fields' kinds. A
//  step into an array is an item's index: `layers.0.params.drift`.
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
        object = try assigning(json, at: path.split(separator: ".").map(String.init)[...], in: object)
        do {
            return try JSONDecoder().decode(Root.self, from: JSONSerialization.data(withJSONObject: object))
        } catch {
            throw failure(error)
        }
    }

    /// `object` with `value` at `keys` (removed when `nil`), making the
    /// objects on the way when they are missing. A step into an array is an
    /// item's index (`layers.0.gain`), and the item must be there: an index
    /// past the end is refused, never padded. `done` is the path so far, for
    /// messages.
    static func assigning(_ value: Any?, at keys: ArraySlice<String>, in object: [String: Any],
                          done: [String] = []) throws(RecipeError) -> [String: Any] {
        guard let key = keys.first else { return object }
        var object = object
        if keys.count == 1 {
            object[key] = value
        } else {
            object[key] = try step(value, at: keys.dropFirst(), into: object[key], done: done + [key])
        }
        return object
    }

    /// `current` (the value at `done`) with `value` at `keys` inside it: an
    /// array's item by index, otherwise an object, made when missing. An
    /// empty value at an item removes the item.
    static func step(_ value: Any?, at keys: ArraySlice<String>, into current: Any?, done: [String]) throws(RecipeError) -> Any {
        guard var array = current as? [Any] else {
            return try assigning(value, at: keys, in: current as? [String: Any] ?? [:], done: done)
        }
        let key = keys.first ?? ""
        guard let index = Int(key), array.indices.contains(index) else {
            let items = array.count == 1 ? "1 item" : "\(array.count) items"
            throw RecipeError("\((done + [key]).joined(separator: ".")) is not there: \(done.joined(separator: ".")) has \(items), from 0")
        }
        if keys.count == 1 {
            if let value { array[index] = value } else { array.remove(at: index) }
        } else {
            array[index] = try step(value, at: keys.dropFirst(), into: array[index], done: done + [key])
        }
        return array
    }
}
