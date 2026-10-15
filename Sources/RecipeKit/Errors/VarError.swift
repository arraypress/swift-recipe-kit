//
//  VarError.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Why `--var` values could not be read.
public enum VarError: Error, Sendable, Equatable, LocalizedError {

    /// Not `name=value`; `example` is the tool's own (`room=kitchen`).
    case malformed(String, example: String)

    /// The same name twice (case ignored).
    case repeated(String)

    public var errorDescription: String? {
        switch self {
        case .malformed(let pair, let example): "--var takes name=value, e.g. --var \(example); not \(pair)"
        case .repeated(let name): "--var \(name) is given twice"
        }
    }
}
