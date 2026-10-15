//
//  StrictKeys.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  Strict reading for a file with no version key and no fixed outline — a
//  design, a theme — whose types decode themselves: each `init(from:)`
//  asks its decoder to refuse a key the type does not have, before it
//  reads the ones it does. JSONDecoder ignores a key it does not know, so a
//  misspelt `"nameSzie"` in a hand-written design would vanish without a
//  word; this names it, with its whole path and the key it was probably
//  meant to be. The check lives where the type does, so it holds however
//  the type is reached: a bare string shorthand, an item of an array, a
//  value inside a dictionary.
//

import Foundation

extension Decoder {

    /// Refuses a key of this object that `keys` does not have: `masthead.nameSzie
    /// is not a design field — did you mean masthead.nameSize?`, or, with no
    /// close key, the list of keys it could have been. Not an object: nothing
    /// to check, and the decode that follows says what it is instead.
    public func refuseUnknownKeys<Key: CodingKey & CaseIterable>(_ keys: Key.Type, noun: String) throws(RecipeError) {
        try refuseUnknownKeys(keys.allCases.map(\.stringValue), noun: noun)
    }

    /// ``refuseUnknownKeys(_:noun:)`` with the keys spelt out.
    public func refuseUnknownKeys(_ known: [String], noun: String) throws(RecipeError) {
        guard let object = try? container(keyedBy: AnyKey.self) else { return }
        let prefix = codingPath.isEmpty ? "" : RecipeJSON.path(codingPath) + "."
        try RecipeJSON.unknownKeys(object.allKeys.map(\.stringValue), known: known, at: prefix, suggests: true, noun: noun)
    }
}

/// Any key at all: what an object holds, read before the type's own keys
/// filter it.
private struct AnyKey: CodingKey {
    let stringValue: String
    let intValue: Int?
    init(stringValue: String) { self.stringValue = stringValue; intValue = nil }
    init?(intValue: Int) { stringValue = String(intValue); self.intValue = intValue }
}
