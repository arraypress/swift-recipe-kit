//
//  SlotFilling.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  Filling a style's `{slot}` markers, as pure functions: the caller's
//  values checked against the style (a name it does not have is refused;
//  a value it does not know goes in as typed), defaults for the rest,
//  known values turned into their phrases, the markers replaced.
//

import Foundation

public enum SlotFilling {

    // MARK: Names and markers

    /// How values compare: case, hyphens, underscores and repeated spaces
    /// ignored, so `Walk-in closet` finds `walk in closet`.
    public static func key(_ value: String) -> String {
        value.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ").joined(separator: " ")
    }

    /// Whether `text` is a slot or style name: lower-case ASCII letters,
    /// digits and hyphens, starting with a letter — `room`, `wall-colour`.
    public static func isName(_ text: String) -> Bool {
        // A scan, not a Regex: catalogues check every name each time they load.
        guard let first = text.unicodeScalars.first, ("a"..."z").contains(first) else { return false }
        return text.unicodeScalars.allSatisfy { ("a"..."z").contains($0) || ("0"..."9").contains($0) || $0 == "-" }
    }

    /// The marker for a slot name: `{room}`.
    public static func marker(_ name: String) -> String { "{\(name)}" }

    /// The names of every `{marker}` in `text`, in order: "{subject} in a {room}" → subject, room.
    public static func markers(in text: String) -> [String] {
        guard text.contains("{") else { return [] }
        var names: [String] = []
        var open: String?
        for character in text {
            if character == "{" {
                open = ""
            } else if character == "}" {
                if let name = open { names.append(name) }
                open = nil
            } else {
                open?.append(character)
            }
        }
        return names
    }

    // MARK: Values

    /// A caller's values checked against a style's slots: every name must be
    /// a slot's (case and surrounding space ignored) and every value
    /// non-empty. Returns a value for every slot — the caller's, trimmed, or
    /// the default — keyed by slot name.
    public static func resolved(_ values: [String: String], for slots: [StyleSlot], style: String)
        throws(SlotError) -> [String: String] {
        var result: [String: String] = [:]
        for (name, value) in values {
            let wanted = name.trimmingCharacters(in: .whitespaces).lowercased()
            guard let slot = slots.first(where: { $0.name == wanted }) else {
                throw .unknownSlot(style: style, slot: wanted, slots: slots.map(\.name))
            }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw .emptyValue(style: style, slot: wanted, defaultValue: slot.defaultValue)
            }
            result[wanted] = trimmed
        }
        for slot in slots where result[slot.name] == nil { result[slot.name] = slot.defaultValue }
        return result
    }

    /// The known value a typed one names — by its name or an alias — or `nil`.
    public static func known(_ value: String, in slot: StyleSlot) -> StyleSlot.Value? {
        let wanted = key(value)
        return slot.known.first { $0.names.contains { key($0) == wanted } }
    }

    /// The words a value puts in: a known value's phrase, or the value as typed.
    public static func text(of value: String, in slot: StyleSlot) -> String {
        known(value, in: slot)?.text ?? value
    }

    /// The value in use for each slot, in slot order: the given one (its name
    /// matched case-blind, its value trimmed), or the default when it is
    /// missing or empty.
    public static func inUse(_ values: [String: String], for slots: [StyleSlot]) -> [(slot: StyleSlot, value: String)] {
        slots.map { slot in
            let given = values.first { $0.key.lowercased() == slot.name }?.value
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (slot, given.flatMap { $0.isEmpty ? nil : $0 } ?? slot.defaultValue)
        }
    }

    /// Every slot's words for these values, in slot order; a missing or
    /// unknown name takes the slot's default (check names first with
    /// ``resolved(_:for:style:)``).
    public static func texts(_ values: [String: String], for slots: [StyleSlot]) -> [(name: String, text: String)] {
        inUse(values, for: slots).map { ($0.slot.name, text(of: $0.value, in: $0.slot)) }
    }

    /// The tags the values in use carry: `["outdoors"]` for a garden.
    public static func tags(_ values: [String: String], for slots: [StyleSlot]) -> Set<String> {
        Set(inUse(values, for: slots).flatMap { known($0.value, in: $0.slot)?.tags ?? [] })
    }

    /// `text` with each `{name}` replaced by its words, one slot after
    /// another in the order given.
    public static func filled(_ text: String, with texts: [(name: String, text: String)]) -> String {
        guard text.contains("{") else { return text }
        var result = text
        for (name, value) in texts { result = result.replacingOccurrences(of: marker(name), with: value) }
        return result
    }

    /// `text` with every slot filled from `values` (or its default).
    public static func filled(_ text: String, slots: [StyleSlot], values: [String: String]) -> String {
        filled(text, with: texts(values, for: slots))
    }
}
