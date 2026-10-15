//
//  StyleSlot.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  A named gap in a style's words — `{room}`, `{lead}` — that a caller
//  fills: one style serves a kitchen or a hallway, an acid line or a
//  supersaw, without a style per value. A slot has a default, so a style
//  always composes, and lists the values it was written for; a known value
//  can stand for a longer phrase ("kitchen" → "a kitchen with fitted
//  cabinets, …"), answer to aliases and carry tags that a style may use to
//  pick its wording. Any other value goes in as typed.
//
//  As JSON: `{"name": "lead", "default": "supersaw", "known": [{"name":
//  "acid", "phrase": "squelching acid line", "aliases": ["303"]}]}`.
//

import Foundation

/// A gap in a style's words, written `{name}`, and what may fill it.
public struct StyleSlot: Codable, Sendable, Equatable {

    /// Lower-case, as written in the style and typed: `room`.
    public let name: String

    /// The value used when none is given: one of ``known``'s names.
    public let defaultValue: String

    /// The values this slot was written for, in listing order.
    public let known: [Value]

    /// A slot from its parts.
    public init(name: String, defaultValue: String, known: [Value]) {
        self.name = name
        self.defaultValue = defaultValue
        self.known = known
    }

    /// The JSON keys: the default is written `default`.
    enum CodingKeys: String, CodingKey {
        case name
        case defaultValue = "default"
        case known
    }
}
