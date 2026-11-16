# Testing GraphAgent

How `graph` is tested: its own suite, and its gated build of real output.

## The suite

```
swift test                                          # the record, the schema, the lines, the templates, the files, a call through the roster
GRAPH_BUILD=1 swift test --filter GraphBuildTests   # the output built and rendered for real (gated, a few minutes)
```

- **The record and the schema.** The package is found through Granite's roster with nothing listed; the schema, the
  field notes and the guide are what a model is shown; `Schema/graph.input.schema.json` describes every field in the
  words the model sees, and `Schema/Graph.md` lists every field, word, look role, string key, tuning key and launch
  state.
- **The lines.** Every kind of line (mappings, look, strings, tuning, launch), accepted and refused, each refusal with
  its reason; the field types each kind of property takes; every key documented, unique and with a default that reads.
- **The templates.** Every template renders with every set of flags, with no marker and no placeholder left; every
  `{{key}}` is a tuning key and every tuning key is used (a layout or a leaf rule as the flags it sets); every word a template says is a string key and every key is
  said; every look role is read; every requirement a template reads is a role's, and every one is read; every type a
  part declares is listed for the prefix; the root opens every launch state; the scene holds nothing but spheres and
  cylinders.
- **The files.** Which files and names a call writes; the Seer call's output (its file set, its conformance, its
  words, its numbers, its look, its launch, the scorecard's code facts, and none of the mock graph's ids); the bytes a
  call that names no later key has always written (the spec's Seer call, the wiki's and the least, pinned by SHA-256);
  the same bytes on a second call; a later call that takes away a conformance it no longer maps; the prefix; the app's types
  checked against the lines; a node line without its id and an edge line without both ends refused; the notes.
- **A call through the roster.** The Seer call as a host makes it, JSON in and JSON out, and its answer is
  `Schema/examples/seer.answer.json` (`GRAPH_EXAMPLES=1` writes it again).

## The gated build

`GraphBuildTests` writes four calls into a package of apps and builds them:

- **Seer, in Swift 6 and in Swift 5:** the Seer call (`Schema/examples/seer.json`) beside a SeerKit module with
  Seer's `GraphNode` (`id`, `level`, `text`, `neighborIds`), DesignAgent's names stood in (`Font.brandTitle`,
  `Font.brandNote`, `Font.brandNote2`, `Color.accent`), the mock graph stood in (a hub `<id>#0` a document and a leaf
  a sentence), and the page written as the prompt gives it, its relay stood in by a class of the same shape.
- **A wiki:** `Schema/examples/wiki-pages.json`, its own `Page` and `PageLink` in the same module, the links kept
  apart from the pages, the prefix `Wiki`.
- **The least call:** no mapping, the kit's own values.

It builds the package with `swift build` for the Mac with no warning in what the kit wrote, and runs a check that
reads every conformance, word, link and launch state back, the leaves a hub names, the force layout (every node
standing, the same for the seed, another for another seed, centred, kept when nothing is new) and, for the least call,
the circle, and draws every view offscreen in light and dark. On the Mac the check also renders Seer's scene with
SceneKit in light and in dark and reads its pixels where the layout stands each node: the first hub selected and
centred, it and its leaves in the accent's bronze, nothing behind them; then the whole graph fitted with nothing
open, every hub plain (near white in light, mid grey in dark) and no leaf showing; the clay shader must compile
(`GRAPH_SHOTS=<folder>` keeps the renders). Then it builds the package with `xcodebuild -destination 'generic/platform=iOS Simulator'`. No simulator is
booted.

## Conformance on Seer

The call a model should write for Seer's Atlas, `Schema/examples/seer.json`, sent with no model:

- it writes 18 files (17 of the kit, 1 conformance) and leaves the app no note;
- its output builds for the iPhone simulator in Swift 6 and Swift 5 beside SeerKit and the page body
  `GraphView(nodes: graph.state.nodes, load: { try await graph.load(ids: $0) })`;
- every `code` item of the scorecard's `atlas` area (`.work/measure/task/seer/scorecard.json` in Craft) matches it,
  B-atlas-4 to B-atlas-8; B-data-8 is the mock graph's ids, which are `$mocks`' to write, and the kit never writes them;
- every word the spec quotes for the Atlas sheet is in it but the title: "L2 Hub" (as `"L\(level) Hub"`), "Leaf",
  "Connecting…"; the original's bar has no title, so the call says `title =`.

The views mirror the original's subviews (the scene's lights, camera, materials and motion, the card, the text sheet,
the bar, the status views), each value a string, look or tuning key the call sets. Where Seer's spec departs from the
original the reference wins, through lines the call adds: the force layout (`layout = force`, `layoutSeed = 417352`),
only the leaves a hub names (`hubLeaves = named`), the bodies' draw (`bodySeed = 19106`), leaves of varied size
(`leafRadiusSpread = 0.04`), the clay's octaves (`clayDetail = 0.63`), the thin links (`edgeRadius = 0.022`), the fit
floor (`cameraDistance = 12`) and no title (`title =`). The original draws its layout and its bodies at random each
launch; the two seeds were chosen against the reference shot. The built-in camera control stays, as the spec asks.
