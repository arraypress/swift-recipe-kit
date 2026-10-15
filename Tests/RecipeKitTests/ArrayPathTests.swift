//
//  ArrayPathTests.swift
//  RecipeKitTests
//
//  Created by David Sherlock on 2026.
//

import Foundation
import Testing
@testable import RecipeKit

/// A recipe with an array of objects, each with a section of its own.
struct Piece: Codable, Equatable {
    var piece: Int = 1
    var name: String?
    var layers: [Layer]
    struct Layer: Codable, Equatable {
        var source: String
        var gain: Double?
        var params: Params?
    }
    struct Params: Codable, Equatable {
        var drift: Double?
        var window: Double?
    }
}

struct ArrayPathTests {

    let format = RecipeFormat(versionKey: "piece", version: 1, rootKeys: ["piece", "name", "layers"], sections: [
        .init("layers.*", keys: ["source", "gain", "params"]), .init("layers.*.params", keys: ["drift", "window"]),
    ])
    let piece = Piece(layers: [.init(source: "a.wav"), .init(source: "b.wav", gain: -3, params: .init(drift: 0.1))])
    let fail: (any Error) -> RecipeError = { _ in RecipeError("bad") }

    func decode(_ text: String, format: RecipeFormat? = nil) throws(RecipeError) -> Piece {
        try RecipeJSON.decoded(Data(text.utf8), format: format ?? self.format)
    }

    @Test func everyItemIsChecked() throws {
        #expect(try decode(#"{"piece":1,"layers":[{"source":"a"},{"source":"b","params":{"drift":0.5}}]}"#).layers[1].params?.drift == 0.5)
        let cases: [(String, String)] = [
            (#"{"piece":1,"layers":[{"source":"a"},{"source":"b","gian":1}]}"#, "layers.1.gian is not a recipe field (layers.1.source, layers.1.gain, layers.1.params)"),
            (#"{"piece":1,"layers":[{"source":"a","params":{"drfit":1}}]}"#, "layers.0.params.drfit is not a recipe field (layers.0.params.drift, layers.0.params.window)"),
            (#"{"piece":1,"layers":[{"source":"a"},5]}"#, "\"layers.1\" is not an object"),
            (#"{"piece":1,"layers":[{"source":"a","params":3}]}"#, "\"layers.0.params\" is not an object"),
            (#"{"piece":1,"layers":[{"source":"a","gain":"loud"}]}"#, "layers.0.gain has the wrong type"),
        ]
        for (text, message) in cases {
            #expect(throws: RecipeError(message), "\(text)") { try decode(text) }
        }
        #expect(throws: RecipeError("a value is not one its field can hold: Number 2.5 is not representable in Swift.")) {
            try RecipeJSON.decoded(Data(#"{"dish":1,"name":"a","settings":{"seed":2.5}}"#.utf8), as: RecipeJSONTests.Recipe.self,
                                   format: RecipeJSONTests().format)
        }
        // Not an array: nothing to look into, and the decoder names the type.
        #expect(throws: RecipeError("layers has the wrong type")) { try decode(#"{"piece":1,"layers":{"source":"a"}}"#) }
    }

    @Test func suggestionsNameTheCloseKey() {
        var suggesting = format
        suggesting.suggests = true
        let cases: [(String, String)] = [
            (#"{"piece":1,"layers":[{"source":"a","params":{"drfit":1}}]}"#, "layers.0.params.drfit is not a recipe field — did you mean layers.0.params.drift?"),
            (#"{"piece":1,"nmae":"x","layers":[]}"#, "nmae is not a recipe field — did you mean name?"),
            (#"{"piece":1,"Layers":[],"layers":[]}"#, "Layers is not a recipe field — did you mean layers?"),
            (#"{"piece":1,"colour":"x","layers":[]}"#, "colour is not a recipe field (piece, name, layers)"),
        ]
        for (text, message) in cases {
            #expect(throws: RecipeError(message), "\(text)") { try decode(text, format: suggesting) }
        }
    }

    @Test func closestIsNearEnough() {
        let names = ["drift", "window", "density", "palette", "bitDepth"]
        #expect(FieldPaths.closest("drfit", among: names) == "drift")
        #expect(FieldPaths.closest("pallete", among: names) == "palette")
        #expect(FieldPaths.closest("bitdepth", among: names) == "bitDepth")
        #expect(FieldPaths.closest("windw", among: names) == "window")
        for far in ["x", "colour", "speed", ""] { #expect(FieldPaths.closest(far, among: names) == nil, "\(far)") }
        #expect(FieldPaths.edits("ab", "ba") == 1)
        #expect(FieldPaths.edits("", "abc") == 3)
    }

    @Test func setReachesAnItem() throws {
        let set = { (path: String, value: String, kind: FieldKind) throws(RecipeError) -> Piece in
            try FieldSetter.set(path, to: value, kind: kind, in: piece, failure: fail)
        }
        #expect(try set("layers.0.gain", "-6", .number).layers[0].gain == -6)
        #expect(try set("layers.0.params.drift", "0.6", .number).layers[0].params == .init(drift: 0.6))
        #expect(try set("layers.1.params.window", "0.5", .number).layers[1].params == .init(drift: 0.1, window: 0.5))
        #expect(try set("layers.1.gain", "", .number).layers[1].gain == nil)
        #expect(try set("layers.1", "", .text).layers == [piece.layers[0]])
        #expect(try set("name", "n", .text).layers == piece.layers)
        #expect(throws: RecipeError("layers.2 is not there: layers has 2 items, from 0")) { try set("layers.2.gain", "1", .number) }
        #expect(throws: RecipeError("layers.x is not there: layers has 2 items, from 0")) { try set("layers.x.gain", "1", .number) }
        #expect(throws: RecipeError("layers.-1 is not there: layers has 2 items, from 0")) { try set("layers.-1.gain", "1", .number) }
        let one = Piece(layers: [.init(source: "a")])
        #expect(throws: RecipeError("layers.1 is not there: layers has 1 item, from 0")) {
            try FieldSetter.set("layers.1.gain", to: "1", kind: .number, in: one, failure: fail)
        }
    }

    @Test func patternsResolveConcreteAndBarePaths() {
        let paths = ["name", "layers.*.gain", "layers.*.params.drift", "master.gain"]
        #expect(FieldPaths.resolve("layers.3.gain", among: paths) == "layers.3.gain")
        #expect(FieldPaths.resolve("layers.0.params.drift", among: paths) == "layers.0.params.drift")
        #expect(FieldPaths.resolve("drift", among: paths) == "layers.*.params.drift")
        #expect(FieldPaths.resolve("gain", among: paths) == "layers.*.gain")
        for bad in ["layers.x.gain", "layers..gain", "layers.0", "layers.0.gain.x", "layers.-1.gain", "layers.١.gain"] {
            #expect(FieldPaths.resolve(bad, among: paths) == nil, "\(bad)")
        }
        #expect(FieldPaths.pattern(of: "layers.12.params.drift", among: paths) == "layers.*.params.drift")
        #expect(FieldPaths.pattern(of: "master.gain", among: paths) == "master.gain")
        #expect(FieldPaths.pattern(of: "layers.a.gain", among: paths) == nil)
        #expect(FieldPaths.matches("a.0.b", pattern: "a.*.b"))
        #expect(!FieldPaths.matches("a.0", pattern: "a.*.b"))
    }
}
