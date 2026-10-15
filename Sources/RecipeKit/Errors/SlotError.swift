//
//  SlotError.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Why a caller's slot values do not fit a style.
public enum SlotError: Error, Sendable, Equatable, LocalizedError {

    /// `slot` is not one of the style's; `slots` are the ones it has.
    case unknownSlot(style: String, slot: String, slots: [String])

    /// `slot` was given with nothing in it; `defaultValue` is what the style would use.
    case emptyValue(style: String, slot: String, defaultValue: String)

    public var errorDescription: String? {
        switch self {
        case .unknownSlot(let style, let slot, let slots):
            slots.isEmpty ? "\(style) has no slots to fill; \(slot) is not one"
                : "\(style) has no slot \"\(slot)\"; its slots: \(slots.joined(separator: ", "))"
        case .emptyValue(let style, let slot, let defaultValue):
            "\(slot) needs a value; \(style)'s default is \(defaultValue)"
        }
    }
}
