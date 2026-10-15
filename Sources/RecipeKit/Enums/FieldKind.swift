//
//  FieldKind.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  What a recipe field holds, so `--set name=value` can read the value as
//  typed: a tool keeps a table of its fields' kinds and ``FieldSetter``
//  does the rest. The domain's own checks (a model name, a person's name)
//  are ``choice(_:)`` or ``custom(_:)``.
//

import Foundation

/// What a field holds, and so how a typed value is read.
public enum FieldKind: Sendable {

    /// `true`/`yes`/`1` or `false`/`no`/`0`, any case.
    case bool

    /// A whole number; with a range, only one inside it.
    case integer(ClosedRange<Int>? = nil)

    /// A finite number.
    case number

    /// Finite numbers separated by commas, brackets optional: `0.97,0.76,0.5`.
    case numbers

    /// As ``numbers``, each kept as a whole number (the fraction dropped).
    case wholeNumbers

    /// The text as typed.
    case text

    /// A list of strings: a JSON array (`["a", "b"]`) or one item. An empty
    /// array clears the field.
    case list

    /// One of these exact values.
    case choice([String])

    /// The tool's own reading: given the text and the field's name, the JSON
    /// value to store, or an error that names the field.
    case custom(@Sendable (_ text: String, _ name: String) throws(RecipeError) -> Any)
}
