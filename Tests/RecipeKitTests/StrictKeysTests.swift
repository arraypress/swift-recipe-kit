//
//  StrictKeysTests.swift
//  RecipeKitTests
//
//  Created by David Sherlock on 2026.
//

import Foundation
import Testing
import RecipeKit

struct StrictKeysTests {

    struct Design: Decodable, Equatable {
        var name: String
        var page: Page?
        var headings: [Page]?

        enum CodingKeys: String, CodingKey, CaseIterable { case name, page, headings }

        init(from decoder: Decoder) throws {
            try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
            let c = try decoder.container(keyedBy: CodingKeys.self)
            name = try c.decode(String.self, forKey: .name)
            page = try c.decodeIfPresent(Page.self, forKey: .page)
            headings = try c.decodeIfPresent([Page].self, forKey: .headings)
        }
    }

    /// An object, or a bare number standing for one.
    struct Page: Decodable, Equatable {
        var margin: Double
        var runningInset: Double?

        enum CodingKeys: String, CodingKey, CaseIterable { case margin, runningInset }

        init(from decoder: Decoder) throws {
            if let single = try? decoder.singleValueContainer().decode(Double.self) {
                margin = single
                return
            }
            try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")
            let c = try decoder.container(keyedBy: CodingKeys.self)
            margin = try c.decode(Double.self, forKey: .margin)
            runningInset = try c.decodeIfPresent(Double.self, forKey: .runningInset)
        }
    }

    func message(_ json: String) -> String? {
        do { _ = try JSONDecoder().decode(Design.self, from: Data(json.utf8)); return nil } catch {
            return (error as? RecipeError)?.message ?? "\(error)"
        }
    }

    @Test func readsWhatItKnows() throws {
        let design = try JSONDecoder().decode(Design.self, from: Data(#"{"name":"a","page":{"margin":4},"headings":[3]}"#.utf8))
        #expect(design.name == "a" && design.page?.margin == 4 && design.headings?.map(\.margin) == [3])
    }

    @Test func refusesAMisspeltKeyWithItsPath() {
        #expect(message(#"{"name":"a","nmae":"b"}"#) == "nmae is not a design field — did you mean name?")
        #expect(message(#"{"name":"a","page":{"margin":1,"runingInset":2}}"#)
                == "page.runingInset is not a design field — did you mean page.runningInset?")
        #expect(message(#"{"name":"a","headings":[1,{"margni":2}]}"#)
                == "headings.1.margni is not a design field — did you mean headings.1.margin?")
    }

    @Test func listsTheKeysWhenNoneIsClose() {
        #expect(message(#"{"name":"a","page":{"margin":1,"zebra":2}}"#)
                == "page.zebra is not a design field (page.margin, page.runningInset)")
    }

    @Test func leavesANonObjectToTheDecode() {
        // Not an object: the type's own decode reports it.
        #expect(message(#"{"name":"a","page":"wide"}"#)?.contains("wide") == false)
        #expect(message(#"{"name":"a","page":"wide"}"#) != nil)
    }
}
