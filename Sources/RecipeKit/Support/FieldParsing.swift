//
//  FieldParsing.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  A value typed on a command line (`--set steps=8`) read as the JSON
//  value its field holds. Every message names the field and what it takes,
//  in the same words in every tool.
//

import Foundation

public enum FieldParsing {

    /// The JSON value for `value` as `kind`, or `nil` when it is empty (the
    /// field is to be cleared). `name` is used in messages. With `trims`,
    /// surrounding space and newlines go first; without, the value is read
    /// exactly as typed. Either way a value of only space is empty.
    public static func json(_ value: String, kind: FieldKind, name: String, trims: Bool = true) throws(RecipeError) -> Any? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let text = trims ? trimmed : value
        switch kind {
        case .bool: return try bool(text, name: name)
        case .integer(let range): return try integer(text, name: name, in: range)
        case .number: return try number(text, name: name)
        case .numbers: return try numbers(text, name: name)
        case .wholeNumbers: return try numbers(text, name: name, whole: true)
        case .text: return text
        case .list: return try list(text, name: name)
        case .choice(let values): return try choice(text, among: values, name: name)
        case .custom(let read): return try read(text, name)
        }
    }

    /// `true`/`yes`/`1` or `false`/`no`/`0`, any case.
    public static func bool(_ text: String, name: String) throws(RecipeError) -> Bool {
        switch text.lowercased() {
        case "true", "yes", "1": return true
        case "false", "no", "0": return false
        default: throw RecipeError("\(name) is true or false; not \(text)")
        }
    }

    /// A whole number, inside `range` when one is given (and then the
    /// message always names the range).
    public static func integer(_ text: String, name: String, in range: ClosedRange<Int>? = nil) throws(RecipeError) -> Int {
        let wanted = range.map { "a whole number \($0.lowerBound)–\($0.upperBound)" } ?? "a whole number"
        guard let number = Int(text), range?.contains(number) ?? true else {
            throw RecipeError("\(name) is \(wanted); not \(text)")
        }
        return number
    }

    /// A finite number.
    public static func number(_ text: String, name: String) throws(RecipeError) -> Double {
        guard let number = Double(text), number.isFinite else { throw RecipeError("\(name) is a number; not \(text)") }
        return number
    }

    /// Finite numbers separated by commas, brackets optional; with `whole`,
    /// each with its fraction dropped.
    public static func numbers(_ text: String, name: String, whole: Bool = false) throws(RecipeError) -> Any {
        let items = text.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        let numbers = items.compactMap(Double.init).filter { $0.isFinite && (!whole || abs($0) < 9.0e15) }
        guard numbers.count == items.count, !numbers.isEmpty else {
            throw RecipeError("\(name) is a list of numbers: 0.97,0.76,0.5; not \(text)")
        }
        return whole ? numbers.map { Int($0) } : numbers
    }

    /// A JSON array of strings, or one item; `nil` for an empty array.
    public static func list(_ text: String, name: String) throws(RecipeError) -> [String]? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("[") else { return [text] }
        guard let items = try? JSONSerialization.jsonObject(with: Data(trimmed.utf8)) as? [String] else {
            throw RecipeError("\(name) takes one item or a JSON array of strings: [\"a\", \"b\"]")
        }
        return items.isEmpty ? nil : items
    }

    /// One of `values`, exactly.
    public static func choice(_ text: String, among values: [String], name: String) throws(RecipeError) -> String {
        guard values.contains(text) else {
            throw RecipeError("\(name) is \(values.joined(separator: ", ")); not \(text)")
        }
        return text
    }
}
