//
//  StyleSlot+Value.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

extension StyleSlot {

    /// One value a slot knows.
    public struct Value: Codable, Sendable, Equatable {

        /// As typed: `home office`, `acid`.
        public let name: String

        /// What goes into the words when it says more than the name:
        /// "squelching acid line".
        public let phrase: String?

        /// Other names that mean this value: `garden` for `outdoor garden`.
        public let aliases: [String]?

        /// What kind of value it is — `outdoors` — for a style that words
        /// such values its own way.
        public let tags: [String]?

        /// A value from its parts.
        public init(name: String, phrase: String? = nil, aliases: [String]? = nil, tags: [String]? = nil) {
            self.name = name
            self.phrase = phrase
            self.aliases = aliases
            self.tags = tags
        }
    }
}
