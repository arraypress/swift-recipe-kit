//
//  RecipeError.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Why a recipe, or one of its fields, could not be read or changed. The
/// message names the field and what it takes: `seed is a whole number
/// 0–4294967295; not -1`.
public struct RecipeError: Error, Sendable, Equatable, LocalizedError {

    /// The whole message, ready to show.
    public let message: String

    /// An error with this message.
    public init(_ message: String) { self.message = message }

    public var errorDescription: String? { message }
}
