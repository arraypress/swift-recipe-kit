//
//  RecipeFiles.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  Recipes on disk: written as ``RecipeJSON`` writes them, refused rather
//  than overwritten unless asked, read through the tool's own strict
//  decoder.
//

import Foundation

public enum RecipeFiles {

    /// Writes `recipe` to `url` — unless a file is there and `overwrites` is false.
    public static func save<Recipe: Encodable>(_ recipe: Recipe, to url: URL, overwrites: Bool) throws(RecipeFileError) {
        if FileManager.default.fileExists(atPath: url.path), !overwrites {
            throw .exists(file: url.lastPathComponent)
        }
        do { try RecipeJSON.encoded(recipe).write(to: url, options: .atomic) } catch {
            throw .unwritable(file: url.lastPathComponent, reason: error.localizedDescription)
        }
    }

    /// The recipe at `url`, read by `decode` (the tool's strict reader).
    public static func load<Recipe>(_ url: URL, decode: (Data) throws -> Recipe) throws(RecipeFileError) -> Recipe {
        guard FileManager.default.fileExists(atPath: url.path) else { throw .missing(path: url.path) }
        do { return try decode(Data(contentsOf: url)) } catch {
            throw .unreadable(file: url.lastPathComponent, reason: error.localizedDescription)
        }
    }
}
