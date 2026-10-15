//
//  StyleCatalogs.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  Built-in style catalogues: groups of styles as JSON compiled into a
//  library (a resource bundle beside a Homebrew binary breaks when the
//  binary is reached through a symlink), decoded once and checked — a
//  test asserts there are no problems, so a bad entry fails the build's
//  tests rather than a run. Also the checks any catalogue shares, however
//  it is written, and the "did you mean" for a name that is not one.
//

import Foundation

public enum StyleCatalogs {

    /// Every style in `groups` (each a JSON array), with every problem found:
    /// a group that is not valid JSON, a name listed twice, a name that is
    /// not kebab-case.
    public static func decoded<Style: Decodable>(_ groups: [String], as type: Style.Type = Style.self,
                                                 name: (Style) -> String) -> (styles: [Style], problems: [String]) {
        var styles: [Style] = []
        var problems: [String] = []
        var seen = Set<String>()
        for group in groups {
            let decoded: [Style]
            do { decoded = try JSONDecoder().decode([Style].self, from: Data(group.utf8)) } catch {
                problems.append("a style group is not valid JSON: \(error)")
                continue
            }
            for style in decoded {
                problems += nameProblems(name(style), seen: &seen)
                styles.append(style)
            }
        }
        return (styles, problems)
    }

    /// A style name listed twice, or not kebab-case.
    public static func nameProblems(_ name: String, seen: inout Set<String>) -> [String] {
        var problems: [String] = []
        if !seen.insert(name).inserted { problems.append("\(name): listed twice") }
        if !SlotFilling.isName(name) { problems.append("\(name): not a kebab-case name") }
        return problems
    }

    /// A style's slots against the markers its words use: a marker that is
    /// no slot, a slot no marker uses, a default the slot does not know.
    public static func slotProblems(style: String, markers: Set<String>, slots: [StyleSlot]) -> [String] {
        let names = Set(slots.map(\.name))
        return markers.subtracting(names).sorted().map { "\(style): {\($0)} is not a slot" }
            + slots.filter { !markers.contains($0.name) }.map { "\(style): slot \($0.name) is unused" }
            + slots.filter { SlotFilling.known($0.defaultValue, in: $0) == nil }
                .map { "\(style): slot \($0.name)'s default is not one of its values" }
    }

    /// Up to three of `names` containing a word (three letters or more) of `typed`.
    public static func suggestions(for typed: String, among names: [String]) -> [String] {
        let words = typed.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 2 }
        return Array(names.filter { name in words.contains { name.contains($0) } }.prefix(3))
    }
}
