//
//  RecipeFileError.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Why a recipe file could not be written or read.
public enum RecipeFileError: Error, Sendable, Equatable, LocalizedError {

    /// The file is there and overwriting was not asked for.
    case exists(file: String)

    /// Writing failed.
    case unwritable(file: String, reason: String)

    /// Nothing at that path.
    case missing(path: String)

    /// There, but not a recipe this version reads.
    case unreadable(file: String, reason: String)

    public var errorDescription: String? {
        switch self {
        case .exists(let file): "\(file) already exists"
        case .unwritable(let file, let reason): "could not write \(file): \(reason)"
        case .missing(let path): "No recipe at \(path)"
        case .unreadable(let file, let reason): "\(file) is not a recipe this version reads: \(reason)"
        }
    }
}
