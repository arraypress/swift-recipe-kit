//
//  FieldPaths.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

public enum FieldPaths {

    /// The full dotted path a typed one names: itself when it is one of
    /// `paths`, otherwise the first path ending in `.` + it — so `seed`
    /// finds `settings.seed` and `yue.ode_steps` finds `request.yue.ode_steps`.
    /// List paths in order of preference: the first match wins.
    public static func resolve(_ typed: String, among paths: [String]) -> String? {
        if paths.contains(typed) { return typed }
        guard !typed.isEmpty else { return nil }
        return paths.first { $0.hasSuffix("." + typed) }
    }
}
