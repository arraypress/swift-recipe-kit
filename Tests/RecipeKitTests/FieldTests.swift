//
//  FieldTests.swift
//  RecipeKitTests
//
//  Created by David Sherlock on 2026.
//

import Foundation
import Testing
@testable import RecipeKit

/// A small recipe with every kind of field, nested one level.
struct Sample: Codable, Equatable {
    var title: String
    var settings: Settings
    var extra: Extra?

    struct Settings: Codable, Equatable {
        var seed: UInt32?
        var steps: Int = 4
        var strength: Double?
        var loud: Bool?
        var mode: Mode = .fast
        var tags: [String]?
        var weights: [Double]?
        var codes: [Int]?

        init() {}
        init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            seed = try c.decodeIfPresent(UInt32.self, forKey: .seed)
            steps = try c.decodeIfPresent(Int.self, forKey: .steps) ?? 4
            strength = try c.decodeIfPresent(Double.self, forKey: .strength)
            loud = try c.decodeIfPresent(Bool.self, forKey: .loud)
            mode = try c.decodeIfPresent(Mode.self, forKey: .mode) ?? .fast
            tags = try c.decodeIfPresent([String].self, forKey: .tags)
            weights = try c.decodeIfPresent([Double].self, forKey: .weights)
            codes = try c.decodeIfPresent([Int].self, forKey: .codes)
        }
    }
    struct Extra: Codable, Equatable { var note: String? }
    enum Mode: String, Codable { case fast, slow }
}

struct FieldTests {

    let sample = Sample(title: "t", settings: .init(), extra: nil)
    let fail: (any Error) -> RecipeError = { _ in RecipeError("bad") }

    func set(_ path: String, _ value: String, _ kind: FieldKind, trims: Bool = true) throws(RecipeError) -> Sample {
        try FieldSetter.set(path, to: value, kind: kind, in: sample, trims: trims, failure: fail)
    }

    @Test func boolWords() throws {
        for (word, value) in [("true", true), ("YES", true), ("1", true), ("false", false), ("No", false), ("0", false)] {
            #expect(try set("settings.loud", word, .bool).settings.loud == value)
        }
        #expect(throws: RecipeError("settings.loud is true or false; not on")) { try set("settings.loud", "on", .bool) }
    }

    @Test func integersWholeAndInRange() throws {
        #expect(try set("settings.steps", " 8 ", .integer()).settings.steps == 8)
        #expect(throws: RecipeError("settings.steps is a whole number; not 4.0")) { try set("settings.steps", "4.0", .integer()) }
        #expect(throws: RecipeError("settings.steps is a whole number; not inf")) { try set("settings.steps", "inf", .integer()) }
        let seed = FieldKind.integer(0...Int(UInt32.max))
        #expect(try set("settings.seed", "4294967295", seed).settings.seed == UInt32.max)
        #expect(throws: RecipeError("settings.seed is a whole number 0–4294967295; not -1")) { try set("settings.seed", "-1", seed) }
        #expect(throws: RecipeError("settings.seed is a whole number 0–4294967295; not abc")) { try set("settings.seed", "abc", seed) }
    }

    @Test func emptyClearsOrRestoresTheDefault() throws {
        var start = sample
        start.settings.steps = 9
        start.settings.seed = 3
        let cleared = try FieldSetter.set("settings.seed", to: "  ", kind: .integer(), in: start, failure: fail)
        #expect(cleared.settings.seed == nil)
        #expect(try FieldSetter.set("settings.steps", to: "\n", kind: .integer(), in: start, failure: fail).settings.steps == 4)
    }

    @Test func numbersFiniteOnly() throws {
        #expect(try set("settings.strength", "0.85", .number).settings.strength == 0.85)
        for bad in ["inf", "nan", "x", "-infinity"] {
            #expect(throws: RecipeError("settings.strength is a number; not \(bad)")) { try set("settings.strength", bad, .number) }
        }
    }

    @Test func numberLists() throws {
        #expect(try set("settings.weights", "[0.5, 0.25]", .numbers).settings.weights == [0.5, 0.25])
        #expect(try set("settings.codes", "1.9,2,3", .wholeNumbers).settings.codes == [1, 2, 3])
        for bad in ["1,x", "[]", "inf", "1,nan", "1e300"] {
            let kind: FieldKind = bad == "1e300" ? .wholeNumbers : .numbers
            #expect(throws: RecipeError("settings.weights is a list of numbers: 0.97,0.76,0.5; not \(bad)")) {
                try set("settings.weights", bad, kind)
            }
        }
    }

    @Test func listsTakeAnArrayOrOneItem() throws {
        #expect(try set("settings.tags", #"["a", "b"]"#, .list).settings.tags == ["a", "b"])
        #expect(try set("settings.tags", " one, two ", .list, trims: false).settings.tags == [" one, two "])
        #expect(try set("settings.tags", "[]", .list).settings.tags == nil)
        #expect(throws: RecipeError(#"settings.tags takes one item or a JSON array of strings: ["a", "b"]"#)) {
            try set("settings.tags", "[1]", .list)
        }
    }

    @Test func textTrimmedOrAsTyped() throws {
        #expect(try set("title", "  new  ", .text).title == "new")
        #expect(try set("title", "  new  ", .text, trims: false).title == "  new  ")
    }

    @Test func choicesAndCustom() throws {
        #expect(try set("settings.mode", "slow", .choice(["fast", "slow"])).settings.mode == .slow)
        #expect(throws: RecipeError("settings.mode is fast, slow; not Slow")) { try set("settings.mode", "Slow", .choice(["fast", "slow"])) }
        let upper = FieldKind.custom { text, name throws(RecipeError) in
            guard text.allSatisfy(\.isLetter) else { throw RecipeError("\(name) is letters; not \(text)") }
            return text.uppercased()
        }
        #expect(try set("title", "abc", upper).title == "ABC")
        #expect(throws: RecipeError("title is letters; not a1")) { try set("title", "a1", upper) }
    }

    @Test func decodeFailureGoesThroughTheToolsMessage() {
        #expect(throws: RecipeError("bad")) { try set("settings.mode", "medium", .text) }
    }

    @Test func missingObjectsAreMade() throws {
        #expect(try set("extra.note", "hi", .text).extra == Sample.Extra(note: "hi"))
        #expect(try set("extra.note", "", .text).extra == Sample.Extra(note: nil))
    }

    @Test func pathsResolveExactlyThenBySuffix() {
        let paths = ["request.seed", "request.retake_seed", "request.guidance", "request.yue.guidance", "request.yue.ode_steps"]
        #expect(FieldPaths.resolve("request.seed", among: paths) == "request.seed")
        #expect(FieldPaths.resolve("seed", among: paths) == "request.seed")
        #expect(FieldPaths.resolve("guidance", among: paths) == "request.guidance")
        #expect(FieldPaths.resolve("yue.guidance", among: paths) == "request.yue.guidance")
        #expect(FieldPaths.resolve("ode_steps", among: paths) == "request.yue.ode_steps")
        for bad in ["", "eed", "quest.seed", "yue", "request", "nope"] { #expect(FieldPaths.resolve(bad, among: paths) == nil, "\(bad)") }
    }
}
