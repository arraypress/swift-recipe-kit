//
//  SlotSummary.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  A style's slot as a `styles NAME` listing shows it: its default, the
//  value the words shown were composed with, and the values it knows.
//

import Foundation

/// One slot of a style, for a listing.
public struct SlotSummary: Codable, Sendable, Equatable {

    /// The slot's name, as `--var` takes it.
    public let name: String

    /// The value used when none is given.
    public let defaultValue: String

    /// The value the words shown were composed with.
    public let value: String

    /// What the slot was written for; a known value puts its phrase in.
    public let known: [StyleSlot.Value]

    /// The summary of `slot`, shown with `value`.
    public init(_ slot: StyleSlot, value: String) {
        name = slot.name
        defaultValue = slot.defaultValue
        self.value = value
        known = slot.known
    }
}
