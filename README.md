# swift-recipe-kit

The rules two generators share, so they stop drifting apart: style slots, `--var`,
strict versioned recipe JSON, a `--set key=value` engine driven by a table of field
kinds, recipe files on disk, and checks for built-in style catalogues. Foundation only —
no command-line kit, no AppKit — so the same rules run in an iOS app.

Used by [swift-image-generation](https://github.com/arraypress/swift-image-generation)
(`imagine`), [swift-music-generation](https://github.com/arraypress/swift-music-generation)
(`song`), `gradients` and `stretch`. Each keeps its own domain: imagine's scenes, tags and
slot line format; song's YuE2 section and its field table; stretch's layers.

```swift
.package(url: "https://github.com/arraypress/swift-recipe-kit.git", from: "0.2.0")
```

macOS 14 / iOS 17, Swift 6.2 tools, no dependencies.

## What is in it

| Part | What it does |
| --- | --- |
| `StyleSlot` | A `{slot}` in a style's words: a default, known values with phrases, aliases and tags. JSON: `{"name", "default", "known"}` |
| `SlotFilling` | Check a caller's values against the slots, fill defaults, turn known values into phrases, replace markers |
| `VarParsing` | `--var name=value`: names trimmed and lower-cased, a name given twice refused |
| `RecipeJSON` + `RecipeFormat` | Write pretty and key-sorted; read strictly — version gate, every key checked per section (in every item of an array too: `layers.*.params`), wrong types named by path, "did you mean" on request |
| `refuseUnknownKeys` | Strict reading for a file with no version and no fixed outline — a design, a theme — whose types decode themselves: each `init(from:)` refuses a key it does not have, by its whole path, with "did you mean" |
| `FieldSetter` + `FieldKind` | `--set path=value` on any `Codable` recipe: read the value by its kind, set it in the JSON, decode back; `layers.0.gain` reaches into an array |
| `FieldPaths` | `seed` finds `settings.seed`: exact path, else the first path ending in it; `layers.1.gain` fits `layers.*.gain`; the closest name for a typo |
| `RecipeFiles` + `RecipePaths` | Save (never overwriting unasked), load through a strict reader; paths stored relative to the recipe |
| `StyleCatalogs` | Decode JSON style groups; report duplicate or non-kebab names, markers without slots, unused slots, bad defaults; "did you mean" |
| `SlotSummary` | One slot for a `styles NAME` listing |

## Slots

```swift
let lead = StyleSlot(name: "lead", defaultValue: "supersaw", known: [
    .init(name: "supersaw", phrase: "huge supersaw lead"),
    .init(name: "acid", phrase: "squelching acid line", aliases: ["303"]),
])
let values = try SlotFilling.resolved(["LEAD": "303"], for: [lead], style: "uplifting-trance")
SlotFilling.filled("uplifting trance with a {lead}", slots: [lead], values: values)
// "uplifting trance with a squelching acid line"
```

A value the slot does not know goes in as typed. Values compare with case, hyphens,
underscores and repeated spaces ignored. Markers are filled slot by slot, in the slots'
order.

## `--set`

A tool keeps a table of its fields' kinds; the engine does the rest:

```swift
let kinds: [String: FieldKind] = [
    "settings.seed": .integer(0...Int(UInt32.max)),
    "settings.steps": .integer(),
    "settings.model": .choice(["flux2-klein-4b", "sana-sprint-1.6b"]),
    "prompt.details": .list,
]
let path = FieldPaths.resolve("seed", among: Array(kinds.keys))!       // "settings.seed"
recipe = try FieldSetter.set(path, to: "42", kind: kinds[path]!, in: recipe) { _ in
    RecipeError("\(path) cannot be 42")
}
```

The recipe goes to JSON, the key is replaced (an empty value removes it, clearing an
optional field or restoring a default), and the JSON decodes back — so the recipe type's
own decoding, its enums and defaults, has the last word.

| Kind | Takes | Refuses with |
| --- | --- | --- |
| `bool` | `true`/`yes`/`1`, `false`/`no`/`0`, any case | `X is true or false; not on` |
| `integer()` | a whole number | `X is a whole number; not 4.0` |
| `integer(range)` | a whole number in the range | `X is a whole number 0–4294967295; not -1` |
| `number` | a finite number | `X is a number; not inf` |
| `numbers`, `wholeNumbers` | `0.97,0.76,0.5`, brackets optional | `X is a list of numbers: …` |
| `text` | anything | — |
| `list` | a JSON array of strings, or one item; `[]` clears | `X takes one item or a JSON array of strings` |
| `choice([…])` | one of the values, exactly | `X is a, b; not c` |
| `custom` | the tool's own check | the tool's message |

## Recipes

```swift
let format = RecipeFormat(versionKey: "imagine", version: 1, rootKeys: ["imagine", "prompt", "settings"],
                          sections: [.init("prompt", keys: ["text", "subject"]), .init("settings", keys: ["seed"])])
let recipe = try RecipeJSON.decoded(data, as: ImageRecipe.self, format: format)
```

Refused, each with a message naming the field: not JSON, not an object, no version, a
newer version, a key the format does not list (`settings.sed is not a recipe field
(settings.seed)`), a section that is not an object, a wrong type, a missing field. A
`check` closure runs before decoding for rules a type cannot say.

## Arrays

A section path takes `*` for every item of an array, and a `--set` path takes the item's
index:

```swift
let format = RecipeFormat(versionKey: "stretch", version: 1, rootKeys: ["stretch", "length", "layers"],
                          sections: [.init("layers.*", keys: ["source", "gain", "params"]),
                                     .init("layers.*.params", keys: ["drift", "window"])],
                          suggests: true)
// {"stretch":1,"layers":[{"source":"a","params":{"drfit":1}}]}
// → layers.0.params.drfit is not a recipe field — did you mean layers.0.params.drift?

let paths = ["length", "layers.*.gain", "layers.*.params.drift"]
FieldPaths.resolve("layers.1.gain", among: paths)        // "layers.1.gain"
FieldPaths.pattern(of: "layers.1.gain", among: paths)    // "layers.*.gain" — the kind's key
FieldPaths.resolve("drift", among: paths)                // "layers.*.params.drift" — the caller picks the item
recipe = try FieldSetter.set("layers.1.gain", to: "-6", kind: .number, in: recipe) { _ in RecipeError("…") }
// layers.5.gain on a two-layer recipe → "layers.5 is not there: layers has 2 items, from 0"
```

An index past the end is refused, never padded; an empty value at an item removes it.
`suggests: true` swaps the list of every key for the one close key when there is one
(`FieldPaths.closest`: edits with a swapped pair counting as one, case ignored, one edit in
a short name up to three in a long one) — for sections too long to list usefully. It is
off by default, so 0.1 callers read the same messages.

## Files with no version

A design or a theme is hand-written, nested, and has shapes a section list cannot say — a
bare string standing for an object, an item of an array, a value in a dictionary. Its
types decode themselves, so each refuses what it does not have before reading what it
does:

```swift
init(from decoder: Decoder) throws {
    try decoder.refuseUnknownKeys(CodingKeys.self, noun: "design")   // CodingKeys: CaseIterable
    let c = try decoder.container(keyedBy: CodingKeys.self)
    …
}
// {"page": {"marign": 40}} → page.marign is not a design field — did you mean page.margin?
// {"headings": [{}, {"sise": 14}]} → headings.1.sise is not a design field — did you mean headings.1.size?
```

The error is a `RecipeError`, thrown through `JSONDecoder` unchanged. A value that is not
an object is left to the decode that follows. Used by the document libraries
(swift-markdown-pdf, swift-resume-pdf, swift-deck-kit, swift-document-theme).

## Tests

`swift test`: 42 tests, no network, no model.

## Licence

MIT.
