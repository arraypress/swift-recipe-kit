//
//  SlotFillingTests.swift
//  RecipeKitTests
//
//  Created by David Sherlock on 2026.
//

import Foundation
import Testing
@testable import RecipeKit

struct SlotFillingTests {

    let room = StyleSlot(name: "room", defaultValue: "living room", known: [
        .init(name: "living room", phrase: "a living room with a deep sofa"),
        .init(name: "outdoor garden", phrase: "a garden with a lawn", aliases: ["garden", "yard"], tags: ["outdoors"]),
        .init(name: "kitchen"),
    ])
    let mood = StyleSlot(name: "mood", defaultValue: "calm", known: [.init(name: "calm"), .init(name: "tense", phrase: "tense, uneasy")])

    @Test func keyIgnoresCaseHyphensUnderscoresAndSpaces() {
        #expect(SlotFilling.key("Walk-in_closet") == "walk in closet")
        #expect(SlotFilling.key("  living   ROOM ") == "living room")
    }

    @Test func namesAreLowerCaseKebab() {
        #expect(SlotFilling.isName("room"))
        #expect(SlotFilling.isName("wall-colour2"))
        for bad in ["", "Room", "2room", "-room", "room colour", "ròom", "room_x"] { #expect(!SlotFilling.isName(bad), "\(bad)") }
    }

    @Test func markersInOrder() {
        #expect(SlotFilling.markers(in: "{subject} in a {room}, {room}") == ["subject", "room", "room"])
        #expect(SlotFilling.markers(in: "no markers") == [])
        #expect(SlotFilling.markers(in: "{open {inner} close}") == ["inner"])
        #expect(SlotFilling.marker("lead") == "{lead}")
    }

    @Test func resolvedFillsDefaultsAndChecksNames() throws {
        let values = try SlotFilling.resolved([" ROOM ": " kitchen\n"], for: [room, mood], style: "japandi")
        #expect(values == ["room": "kitchen", "mood": "calm"])
        #expect(try SlotFilling.resolved([:], for: [room], style: "s") == ["room": "living room"])
    }

    @Test func resolvedRefusesUnknownAndEmpty() {
        #expect(throws: SlotError.unknownSlot(style: "japandi", slot: "nope", slots: ["room", "mood"])) {
            try SlotFilling.resolved(["nope": "x"], for: [room, mood], style: "japandi")
        }
        #expect(throws: SlotError.emptyValue(style: "japandi", slot: "room", defaultValue: "living room")) {
            try SlotFilling.resolved(["room": "  "], for: [room], style: "japandi")
        }
        #expect(SlotError.unknownSlot(style: "pop", slot: "x", slots: []).errorDescription == "pop has no slots to fill; x is not one")
        #expect(SlotError.unknownSlot(style: "pop", slot: "x", slots: ["a", "b"]).errorDescription
                == "pop has no slot \"x\"; its slots: a, b")
        #expect(SlotError.emptyValue(style: "pop", slot: "a", defaultValue: "d").errorDescription == "a needs a value; pop's default is d")
    }

    @Test func knownByNameOrAliasAndText() {
        #expect(SlotFilling.known("Garden", in: room)?.name == "outdoor garden")
        #expect(SlotFilling.known("OUTDOOR-garden", in: room)?.name == "outdoor garden")
        #expect(SlotFilling.known("attic", in: room) == nil)
        #expect(SlotFilling.text(of: "yard", in: room) == "a garden with a lawn")
        #expect(SlotFilling.text(of: "kitchen", in: room) == "kitchen")
        #expect(SlotFilling.text(of: "attic", in: room) == "attic")
        #expect(room.text(for: "garden") == "a garden with a lawn")
        #expect(room.value(named: "yard")?.tags == ["outdoors"])
        #expect(room.known[1].names == ["outdoor garden", "garden", "yard"])
        #expect(room.marker == "{room}")
    }

    @Test func inUseTextsAndTags() {
        let use = SlotFilling.inUse(["Room": " garden ", "mood": ""], for: [room, mood])
        #expect(use.map(\.value) == ["garden", "calm"])
        #expect(SlotFilling.texts(["room": "garden"], for: [room, mood]).map(\.text) == ["a garden with a lawn", "calm"])
        #expect(SlotFilling.tags(["room": "garden"], for: [room, mood]) == ["outdoors"])
        #expect(SlotFilling.tags([:], for: [room, mood]).isEmpty)
    }

    @Test func filledReplacesEveryMarkerInSlotOrder() {
        #expect(SlotFilling.filled("{room}, feeling {mood}; {room}", slots: [room, mood], values: ["mood": "tense"])
                == "a living room with a deep sofa, feeling tense, uneasy; a living room with a deep sofa")
        #expect(SlotFilling.filled("{subject} here", slots: [room], values: [:]) == "{subject} here")
        // A value holding a later slot's marker is filled by that slot, as the
        // slots come in order (and a value holding an earlier one is not).
        #expect(SlotFilling.filled("{room}/{mood}", slots: [room, mood], values: ["room": "{mood}", "mood": "tense"])
                == "tense, uneasy/tense, uneasy")
        #expect(SlotFilling.filled("{room}/{mood}", slots: [room, mood], values: ["mood": "{room}"]) == "a living room with a deep sofa/{room}")
    }
}
