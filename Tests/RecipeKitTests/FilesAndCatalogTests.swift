//
//  FilesAndCatalogTests.swift
//  RecipeKitTests
//
//  Created by David Sherlock on 2026.
//

import Foundation
import Testing
@testable import RecipeKit

struct FilesAndCatalogTests {

    struct Note: Codable, Equatable { var text: String }

    func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("recipekit-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func savesRefusesToOverwriteAndLoads() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("n.json")
        try RecipeFiles.save(Note(text: "a"), to: file, overwrites: false)
        #expect(throws: RecipeFileError.exists(file: "n.json")) { try RecipeFiles.save(Note(text: "b"), to: file, overwrites: false) }
        try RecipeFiles.save(Note(text: "b"), to: file, overwrites: true)
        #expect(try RecipeFiles.load(file) { try JSONDecoder().decode(Note.self, from: $0) } == Note(text: "b"))
        #expect(String(decoding: try Data(contentsOf: file), as: UTF8.self) == "{\n  \"text\" : \"b\"\n}")
    }

    @Test func loadNamesWhatWentWrong() throws {
        let dir = try folder()
        defer { try? FileManager.default.removeItem(at: dir) }
        let missing = dir.appendingPathComponent("none.json")
        #expect(throws: RecipeFileError.missing(path: missing.path)) { try RecipeFiles.load(missing) { $0 } }
        let file = dir.appendingPathComponent("bad.json")
        try Data("{}".utf8).write(to: file)
        #expect(throws: RecipeFileError.unreadable(file: "bad.json", reason: "nope")) {
            try RecipeFiles.load(file) { _ throws -> Data in throw RecipeError("nope") }
        }
        #expect(RecipeFileError.unreadable(file: "a.json", reason: "x").errorDescription == "a.json is not a recipe this version reads: x")
        #expect(RecipeFileError.missing(path: "/p").errorDescription == "No recipe at /p")
        #expect(RecipeFileError.exists(file: "a").errorDescription == "a already exists")
        #expect(RecipeFileError.unwritable(file: "a", reason: "r").errorDescription == "could not write a: r")
    }

    @Test func pathsRelativeInsideTheFolderAbsoluteOutside() {
        let folder = URL(fileURLWithPath: "/tmp/recipes")
        #expect(RecipePaths.stored("/tmp/recipes/in/a.png", from: folder) == "in/a.png")
        #expect(RecipePaths.stored("/tmp/recipes-other/a.png", from: folder) == "/tmp/recipes-other/a.png")
        #expect(RecipePaths.stored("/tmp/recipes/../x.png", from: folder) == "/tmp/x.png")
        #expect(RecipePaths.usable("in/a.png", from: folder) == "/tmp/recipes/in/a.png")
        #expect(RecipePaths.usable("/abs/a.png", from: folder) == "/abs/a.png")
        #expect(RecipePaths.usable("~/a.png", from: folder) == NSHomeDirectory() + "/a.png")
        #expect(RecipePaths.stored("~/a.png", from: URL(fileURLWithPath: NSHomeDirectory())) == "a.png")
    }

    @Test func pathsThroughASymlinkStillMeetTheFolder() throws {
        let real = FileManager.default.temporaryDirectory.appendingPathComponent("recipe-real-\(UUID().uuidString)")
        let link = FileManager.default.temporaryDirectory.appendingPathComponent("recipe-link-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: real.appendingPathComponent("in"), withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)
        defer {
            try? FileManager.default.removeItem(at: link)
            try? FileManager.default.removeItem(at: real)
        }
        // The folder through the link, a file not written yet through the real path — and the other way round.
        #expect(RecipePaths.stored(real.path + "/in/new.png", from: link) == "in/new.png")
        #expect(RecipePaths.stored(link.path + "/in/new.png", from: real) == "in/new.png")
        #expect(RecipePaths.stored(link.path + "/not/made/yet.png", from: real) == "not/made/yet.png")
        // /tmp is /private/tmp: one side typed each way, the file not there yet.
        let folder = URL(fileURLWithPath: "/private/tmp/recipe-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let typed = "/tmp/" + folder.lastPathComponent + "/oct.png"
        #expect(RecipePaths.stored(typed, from: folder) == "oct.png")
        #expect(RecipePaths.stored(folder.path + "/oct.png", from: URL(fileURLWithPath: "/tmp/" + folder.lastPathComponent)) == "oct.png")
        // Outside stays absolute, as typed.
        #expect(RecipePaths.stored(link.path + "-elsewhere/a.png", from: real) == link.path + "-elsewhere/a.png")
    }

    struct Style: Codable { var name: String; var words: String; var slots: [StyleSlot]? }

    @Test func catalogueDecodesAndReportsProblems() {
        let groups = [
            #"[{"name":"night-drive","words":"{lead}","slots":[{"name":"lead","default":"sax","known":[{"name":"sax"},{"name":"acid","phrase":"acid line","aliases":["303"]}]}]}]"#,
            #"[{"name":"night-drive","words":"x"},{"name":"Bad Name","words":"y"}]"#,
            "not json",
        ]
        let result = StyleCatalogs.decoded(groups, as: Style.self, name: \.name)
        #expect(result.styles.count == 3)
        #expect(result.styles[0].slots?[0].known[1] == StyleSlot.Value(name: "acid", phrase: "acid line", aliases: ["303"]))
        #expect(result.problems.count == 3)
        #expect(result.problems[0] == "night-drive: listed twice")
        #expect(result.problems[1] == "Bad Name: not a kebab-case name")
        #expect(result.problems[2].hasPrefix("a style group is not valid JSON"))
    }

    @Test func slotProblems() {
        let slots = [StyleSlot(name: "lead", defaultValue: "sax", known: [.init(name: "sax")]),
                     StyleSlot(name: "mood", defaultValue: "odd", known: [.init(name: "calm")])]
        #expect(StyleCatalogs.slotProblems(style: "s", markers: ["lead", "zzz", "aaa"], slots: slots) == [
            "s: {aaa} is not a slot", "s: {zzz} is not a slot", "s: slot mood is unused", "s: slot mood's default is not one of its values",
        ])
        #expect(StyleCatalogs.slotProblems(style: "s", markers: ["lead"], slots: Array(slots.prefix(1))).isEmpty)
    }

    @Test func suggestionsShareAWord() {
        let names = ["uplifting-trance", "psy-trance", "deep-house", "trance-pop", "tech-trance"]
        #expect(StyleCatalogs.suggestions(for: "Trance anthem", among: names) == ["uplifting-trance", "psy-trance", "trance-pop"])
        #expect(StyleCatalogs.suggestions(for: "a b", among: names).isEmpty)
    }

    @Test func slotJSONUsesDefaultAndSummaryKeepsItsKeys() throws {
        let slot = StyleSlot(name: "lead", defaultValue: "sax", known: [.init(name: "sax", tags: ["warm"])])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        #expect(String(decoding: try encoder.encode(slot), as: UTF8.self)
                == #"{"default":"sax","known":[{"name":"sax","tags":["warm"]}],"name":"lead"}"#)
        #expect(String(decoding: try encoder.encode(SlotSummary(slot, value: "acid")), as: UTF8.self)
                == #"{"defaultValue":"sax","known":[{"name":"sax","tags":["warm"]}],"name":"lead","value":"acid"}"#)
    }
}
