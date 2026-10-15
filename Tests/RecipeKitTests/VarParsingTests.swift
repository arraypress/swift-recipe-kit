//
//  VarParsingTests.swift
//  RecipeKitTests
//
//  Created by David Sherlock on 2026.
//

import Foundation
import Testing
@testable import RecipeKit

struct VarParsingTests {

    @Test func namesLowerCasedValuesAsTyped() throws {
        #expect(try VarParsing.vars([" Room = Kitchen ", "lead=a=b", "x="], example: "room=kitchen")
                == ["room": " Kitchen ", "lead": "a=b", "x": ""])
        #expect(try VarParsing.vars([], example: "e").isEmpty)
    }

    @Test func malformedAndRepeatedRefused() {
        for bad in ["room", "=kitchen", " =x"] {
            #expect(throws: VarError.malformed(bad, example: "lead=acid")) { try VarParsing.vars([bad], example: "lead=acid") }
        }
        #expect(throws: VarError.repeated("room")) { try VarParsing.vars(["room=a", "ROOM=b"], example: "e") }
        #expect(VarError.malformed("room", example: "room=kitchen").errorDescription
                == "--var takes name=value, e.g. --var room=kitchen; not room")
        #expect(VarError.repeated("lead").errorDescription == "--var lead is given twice")
    }

    @Test func pairSplitsAtFirstEquals() {
        #expect(VarParsing.pair("a=b=c")! == ("a", "b=c"))
        #expect(VarParsing.pair("a=")! == ("a", ""))
        #expect(VarParsing.pair("abc") == nil)
    }
}
