//
//  FieldPaths.swift
//  RecipeKit
//
//  Created by David Sherlock on 2026.
//
//  Field names as typed against a tool's table of paths. A path in the
//  table may hold `*` for an array index (`layers.*.params.drift`); a typed
//  path names the item (`layers.0.params.drift`).
//

import Foundation

public enum FieldPaths {

    /// The full dotted path a typed one names: itself when it is one of
    /// `paths` or fits one with its `*` steps given as indices
    /// (`layers.1.gain` fits `layers.*.gain`); otherwise the first path ending
    /// in `.` + it — so `seed` finds `settings.seed` and `yue.ode_steps` finds
    /// `request.yue.ode_steps`. List paths in order of preference: the first
    /// match wins. A suffix match can still hold `*` (`drift` finds
    /// `layers.*.params.drift`): a bare name cannot say which item, so the
    /// caller picks one or asks.
    public static func resolve(_ typed: String, among paths: [String]) -> String? {
        if paths.contains(typed) { return typed }
        guard !typed.isEmpty else { return nil }
        if paths.contains(where: { matches(typed, pattern: $0) }) { return typed }
        return paths.first { $0.hasSuffix("." + typed) }
    }

    /// The path in `patterns` a full path fits: itself, or the one whose `*`
    /// steps its indices fill — the key to look its kind up by.
    public static func pattern(of path: String, among patterns: [String]) -> String? {
        patterns.contains(path) ? path : patterns.first { matches(path, pattern: $0) }
    }

    /// Whether `path` is `pattern` with every `*` step a whole number (0 up).
    public static func matches(_ path: String, pattern: String) -> Bool {
        let steps = path.split(separator: ".", omittingEmptySubsequences: false)
        let wanted = pattern.split(separator: ".", omittingEmptySubsequences: false)
        guard steps.count == wanted.count else { return false }
        return zip(steps, wanted).allSatisfy { step, want in
            want == "*" ? !step.isEmpty && step.allSatisfy(\.isASCII) && step.allSatisfy(\.isNumber) : step == want
        }
    }

    /// The one of `names` that `typed` most likely meant: the nearest by
    /// edits (a swapped pair of letters counts as one, case ignored), when
    /// it is near enough — one edit in a short name, up to three in a long
    /// one. The first of equals wins.
    public static func closest(_ typed: String, among names: [String]) -> String? {
        let allowed = max(1, min(3, (typed.count + 2) / 4))
        let scored = names.map { ($0, edits(typed.lowercased(), $0.lowercased())) }.filter { $0.1 <= allowed }
        return scored.min { $0.1 < $1.1 }?.0
    }

    /// Edits from `a` to `b`: insertions, deletions, substitutions and swaps
    /// of neighbours (optimal string alignment).
    static func edits(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }
        var d = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { d[i][0] = i }
        for j in 0...b.count { d[0][j] = j }
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                d[i][j] = min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] { d[i][j] = min(d[i][j], d[i - 2][j - 2] + 1) }
            }
        }
        return d[a.count][b.count]
    }
}
