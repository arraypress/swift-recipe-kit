//
//  RecipePaths.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  Paths inside a recipe are relative to the recipe file when the file
//  they name sits beside it (or below), so a folder of recipes and their
//  inputs moves as one; anything else is stored absolute.
//

import Foundation

public enum RecipePaths {

    /// `path` with a leading `~` expanded.
    public static func expanded(_ path: String) -> String { (path as NSString).expandingTildeInPath }

    /// `path` as a recipe in `folder` should hold it: relative when the file
    /// is inside that folder, absolute otherwise.
    public static func stored(_ path: String, from folder: URL) -> String {
        let absolute = URL(fileURLWithPath: expanded(path)).standardizedFileURL.path
        let base = folder.standardizedFileURL.path + "/"
        return absolute.hasPrefix(base) ? String(absolute.dropFirst(base.count)) : absolute
    }

    /// A path from a recipe in `folder`, made usable from anywhere: `~`
    /// expanded, a relative path taken from the recipe's folder.
    public static func usable(_ path: String, from folder: URL) -> String {
        let expanded = expanded(path)
        guard !expanded.hasPrefix("/") else { return expanded }
        return folder.appendingPathComponent(expanded).standardizedFileURL.path
    }
}
