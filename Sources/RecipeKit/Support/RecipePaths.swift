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
    /// is inside that folder, absolute otherwise. Inside is decided on real
    /// locations, symlinks resolved on both sides — `/tmp` is `/private/tmp`,
    /// and a file not written yet is placed by the folder it will go in — so
    /// one path typed through a link and the other not still meet.
    public static func stored(_ path: String, from folder: URL) -> String {
        let absolute = URL(fileURLWithPath: expanded(path)).standardizedFileURL.path
        let real = resolved(absolute)
        let base = resolved(folder.standardizedFileURL.path) + "/"
        return real.hasPrefix(base) ? String(real.dropFirst(base.count)) : absolute
    }

    /// `path` (absolute, standardized) with every symlink resolved: the
    /// longest part that exists goes through `realpath`, and the rest — a
    /// file or folders not made yet — is put back after it.
    static func resolved(_ path: String) -> String {
        var existing = path
        var rest: [String] = []
        while !existing.isEmpty, existing != "/" {
            if let real = realpath(existing, nil) {
                defer { free(real) }
                let head = String(cString: real)
                return rest.isEmpty ? head : (head == "/" ? "" : head) + "/" + rest.reversed().joined(separator: "/")
            }
            rest.append((existing as NSString).lastPathComponent)
            existing = (existing as NSString).deletingLastPathComponent
        }
        return path
    }

    /// A path from a recipe in `folder`, made usable from anywhere: `~`
    /// expanded, a relative path taken from the recipe's folder.
    public static func usable(_ path: String, from folder: URL) -> String {
        let expanded = expanded(path)
        guard !expanded.hasPrefix("/") else { return expanded }
        return folder.appendingPathComponent(expanded).standardizedFileURL.path
    }
}
