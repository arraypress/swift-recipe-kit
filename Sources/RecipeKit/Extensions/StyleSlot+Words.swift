//
//  StyleSlot+Words.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

public extension StyleSlot {

    /// The marker the style's words use for this slot: `{room}`.
    var marker: String { SlotFilling.marker(name) }

    /// The words a value puts in: a known value's phrase (by its name or an
    /// alias; case, hyphens and spacing ignored), otherwise the value itself.
    func text(for value: String) -> String { SlotFilling.text(of: value, in: self) }

    /// The known value a typed one names, by name or alias; `nil` for a free value.
    func value(named typed: String) -> Value? { SlotFilling.known(typed, in: self) }
}

public extension StyleSlot.Value {

    /// The name and every alias.
    var names: [String] { [name] + (aliases ?? []) }

    /// The words this value puts in.
    var text: String { phrase ?? name }
}
