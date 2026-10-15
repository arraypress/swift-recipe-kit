//
//  RecipeJSONTests.swift
//  RecipeKitTests
//
//  Created by David Sherlock on 2026.
//

import Foundation
import Testing
@testable import RecipeKit

struct RecipeJSONTests {

    struct Recipe: Codable, Equatable {
        var dish: Int
        var name: String
        var settings: Settings?
        struct Settings: Codable, Equatable {
            var seed: Int?
            var deep: Deep?
        }
        struct Deep: Codable, Equatable { var x: Int? }
    }

    let format = RecipeFormat(versionKey: "dish", version: 2, rootKeys: ["dish", "name", "settings"], sections: [
        .init("settings", keys: ["seed", "deep"]), .init("settings.deep", keys: ["x"]),
    ])

    func decode(_ text: String, check: (([String: Any]) throws(RecipeError) -> Void)? = nil) throws(RecipeError) -> Recipe {
        try RecipeJSON.decoded(Data(text.utf8), format: format, check: check)
    }

    @Test func roundTripsPrettyAndSorted() throws {
        let recipe = Recipe(dish: 1, name: "a/b", settings: .init(seed: 3, deep: nil))
        let text = String(decoding: try RecipeJSON.encoded(recipe), as: UTF8.self)
        #expect(text == "{\n  \"dish\" : 1,\n  \"name\" : \"a/b\",\n  \"settings\" : {\n    \"seed\" : 3\n  }\n}")
        #expect(try decode(text) == recipe)
    }

    @Test func refusesWhatItCannotRead() {
        let cases: [(String, String)] = [
            ("{ no", "it is not JSON"),
            ("[1]", "it is not a JSON object"),
            (#"{"name":"a"}"#, "it has no \"dish\": 2 — the format version"),
            (#"{"dish":"1","name":"a"}"#, "it has no \"dish\": 2 — the format version"),
            (#"{"dish":3,"name":"a"}"#, "it is format 3; this reads format 2"),
            (#"{"dish":0,"name":"a"}"#, "it is format 0; this reads format 2"),
            (#"{"dish":1,"name":"a","zz":1,"aa":2}"#, "aa is not a recipe field (dish, name, settings)"),
            (#"{"dish":1,"name":"a","settings":{"sed":1}}"#, "settings.sed is not a recipe field (settings.seed, settings.deep)"),
            (#"{"dish":1,"name":"a","settings":{"deep":{"y":1}}}"#, "settings.deep.y is not a recipe field (settings.deep.x)"),
            (#"{"dish":1,"name":"a","settings":5}"#, "\"settings\" is not an object"),
            (#"{"dish":1,"name":"a","settings":{"deep":5}}"#, "\"settings.deep\" is not an object"),
            (#"{"dish":1,"name":5}"#, "name has the wrong type"),
            (#"{"dish":1}"#, "name is missing"),
            (#"{"dish":1,"name":"a","settings":{"seed":"x"}}"#, "settings.seed has the wrong type"),
        ]
        for (text, message) in cases {
            #expect(throws: RecipeError(message), "\(text)") { try decode(text) }
        }
    }

    @Test func nullSectionsAreSkippedAndCheckRuns() throws {
        #expect(try decode(#"{"dish":2,"name":"a","settings":null}"#).settings == nil)
        #expect(throws: RecipeError("no")) {
            try decode(#"{"dish":1,"name":"a"}"#) { root throws(RecipeError) in
                if root["name"] as? String == "a" { throw RecipeError("no") }
            }
        }
    }

    @Test func codingPathsAsDottedNames() {
        struct Key: CodingKey {
            var stringValue: String
            var intValue: Int?
            init(stringValue: String) { self.stringValue = stringValue }
            init(intValue: Int) { stringValue = "\(intValue)"; self.intValue = intValue }
        }
        #expect(RecipeJSON.path([Key(stringValue: "scenes"), Key(intValue: 2), Key(stringValue: "who")]) == "scenes.2.who")
    }
}
