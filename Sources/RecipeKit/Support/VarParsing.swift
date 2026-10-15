//
//  VarParsing.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  `--var name=value`, repeatable, as typed on a command line. One rule
//  for every tool: the name is trimmed and lower-cased, the value kept as
//  typed (``SlotFilling/resolved(_:for:style:)`` trims it), and a name
//  given twice is refused rather than the last one quietly winning.
//

import Foundation

public enum VarParsing {

    /// Slot name → value for each `name=value`. `example` is the tool's own,
    /// shown when one is malformed: `room=kitchen`.
    public static func vars(_ typed: [String], example: String) throws(VarError) -> [String: String] {
        var values: [String: String] = [:]
        for pair in typed {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
            let name = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
            guard parts.count == 2, !name.isEmpty else { throw .malformed(pair, example: example) }
            guard values[name] == nil else { throw .repeated(name) }
            values[name] = parts[1]
        }
        return values
    }

    /// `name=value` split at the first `=`; `nil` when there is none.
    public static func pair(_ typed: String) -> (name: String, value: String)? {
        let parts = typed.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        return parts.count == 2 ? (parts[0], parts[1]) : nil
    }
}
