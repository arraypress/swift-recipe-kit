//
//  RecipeFormat.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  The shape a recipe file must have before it is decoded: its version
//  key, the newest version this build reads, and the keys allowed at the
//  top and in each section. JSONDecoder ignores keys it does not know, so a
//  misspelt `"lightning"` would vanish without a word; ``RecipeJSON``
//  checks every key against this first.
//

import Foundation

/// The keys a recipe file may hold, and its version.
public struct RecipeFormat: Sendable, Equatable {

    /// The key holding the format version: `"song": 1`.
    public var versionKey: String

    /// The newest version this build reads; every version from 1 up is read.
    public var version: Int

    /// The keys allowed at the top.
    public var rootKeys: [String]

    /// The objects inside, by dotted path, and the keys each allows.
    public var sections: [Section]

    /// How a key it does not know is refused: `false` lists every key it
    /// could have been; `true` names the close one (`did you mean
    /// layers.0.params.drift?`) when there is one, and lists them otherwise —
    /// for sections too long to list usefully.
    public var suggests: Bool

    /// A format from its parts.
    public init(versionKey: String, version: Int, rootKeys: [String], sections: [Section], suggests: Bool = false) {
        self.versionKey = versionKey
        self.version = version
        self.rootKeys = rootKeys
        self.sections = sections
        self.suggests = suggests
    }

    /// An object in a recipe — `settings`, `request.yue`, `layers.*.params` —
    /// and its keys.
    public struct Section: Sendable, Equatable {

        /// Dotted from the top: `request.yue`. A `*` step stands for every
        /// item of an array: `layers.*` is each layer, `layers.*.params` each
        /// layer's `params`.
        public var path: String

        /// The keys it allows.
        public var keys: [String]

        /// A section from its parts.
        public init(_ path: String, keys: [String]) {
            self.path = path
            self.keys = keys
        }
    }
}
