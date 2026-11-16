# craft-agent/1 · graph

Writes a 3D graph of how things connect as plain SwiftUI and SceneKit (hubs and their leaves as spheres joined by thin cylinders, the selected node pulsing, a card with its badge and the start of its text), made to show the app's own types from one mapping line a type.

graph's copy of Craft's agent standard (`craft-agent/1`, Craft's `Schema/Agent.md`), with the reference of every
line it reads. Everything above **Changes** describes the agent as it is; Changes is graph's own log.

| File | What it holds |
| --- | --- |
| [`graph.input.schema.json`](graph.input.schema.json) | What it takes, as JSON Schema |
| [`graph.answer.schema.json`](graph.answer.schema.json) | What it answers: `granite-answer/1` with its own kinds |
| [`examples/seer.json`](examples/seer.json) | The call that writes Seer's Atlas: its node type, its words, its numbers |
| [`examples/seer.answer.json`](examples/seer.answer.json) | What that call answers |
| [`examples/wiki-pages.json`](examples/wiki-pages.json) | A call for another app: a wiki's pages, their links kept apart, with a prefix |

## What it takes

| Field | Required | What it is |
| --- | --- | --- |
| `into` | no | the folder for the views, relative to the project; Components/Graph when left out |
| `mappings` | no | one line a role (node, edge): `node: GraphNode id=id level=level text=text neighbours=neighborIds`, `edge: Link from=source to=target`; a bare path is read off the value, anything else is Swift that may name `value` |
| `imports` | no | modules the conformances import, such as the package a mapped type is declared in |
| `look` | no | look roles mapped to the app's names, one a line: `title = Font.brandTitle`; roles title, note, note2, passage (Font), accent, foreground, hubBadge, leafBadge (Color); an unmapped role is the system's |
| `strings` | no | the words, one a line, `key = words` (quotes optional): `title = Atlas`, `hub = L{level} Hub`, `loading = Connecting…`; every key and its default in Graph.md |
| `tuning` | no | numbers, symbols and motion, one a line: `hubRadius = 0.45`, `excerpt = 240`, `pulseScale = 1.12`, `showAnimation = .spring(response: 0.4, dampingFraction: 0.8)`; every key in Graph.md |
| `launch` | no | the state the root opens in for a launch with `-destination <name>`, one a line: `atlas = graph(space-001, space-002)`; states graph and text, each with the ids it loads in parentheses (none: the page's own) |
| `prefix` | no | what the kit's names start with instead of Graph, when the app already has those names: `Wiki` writes WikiView |

`directory` is filled by Craft with the project folder. The person's request and the host's model are offered
beside the call, never in it.

## The lines

Every list field takes one line a thing. A line it cannot read is refused with the reason, every bad line at once, and nothing is written.

### `mappings`: `role: Type word=value …`

A role, a colon, the app's type, then `word=value` for each thing the views show, spaces or commas between. A value that is a bare path (`id`, `document.id`, `owner?.slug`) is read off the value; anything else is Swift that may name `value` (`neighbours=value.links.map(\.id)`). Every value goes through `GraphValue`, so an id may be a String, a UUID, a URL or a whole number, a level a whole number or a Double, and neighbours a list or a set of ids. A word left out takes the default. A node line maps `id`, an edge line `from` and `to`. A role no line maps uses the kit's own value (`GraphNodeItem`, `GraphEdgeItem`). The links are the nodes' neighbours and the edges together, each pair once whichever side names it, and only between nodes that are there.

**node** (a line may also start vertex, point, partition, passage, item; it maps `id`)

| Word | Requirement | Type | Left out | What it is | Takes | Also read as |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `graphNodeID` | `String` | `""` | Its id: what the edges and the neighbours name it by, in small type in the panel. | a String, a UUID, a URL or a whole number, optional or not | identifier, key, partitionId, uid, slug |
| `level` | `graphNodeLevel` | `Int` | `0` | Its level: above 0 a hub, sized by it; 0 a leaf. | a whole number or a Double (rounded), optional or not | layer, depth, tier, rank |
| `text` | `graphNodeText` | `String` | `""` | Its text: the panel shows its start, its sheet all of it. | a String, a UUID, a URL or a whole number, optional or not | body, content, passage, summary |
| `neighbours` | `graphNodeNeighbours` | `[String]` | `[]` | The ids of the nodes it is joined to; an edge line can say the same. | a list or a set of Strings, UUIDs or whole numbers | neighbors, neighbourIds, neighborIds, links, connections, children |

**edge** (a line may also start link, connection, pair, relation; it maps `from` and `to`)

| Word | Requirement | Type | Left out | What it is | Takes | Also read as |
| --- | --- | --- | --- | --- | --- | --- |
| `from` | `graphEdgeFrom` | `String` | `""` | The id of the node at one end. | a String, a UUID, a URL or a whole number, optional or not | source, start, parent, a |
| `to` | `graphEdgeTo` | `String` | `""` | The id of the node at the other end. | a String, a UUID, a URL or a whole number, optional or not | target, end, child, b |

### `imports`

Module names, one an item: what the conformances import, such as the package a mapped type is declared in (`SeerKit`). A type found in a local package of the project is imported without being named.

### `look`: `role = expression`

Maps a look role to the app's own name for it. A font role takes a `Font` expression, a colour role a `Color`. An unmapped role is the system's value below, so the views build in any app. In the scene, `accent` tints the open hub, its leaves and the selected node (darker in light mode, lighter in dark), their glow and the links; every other sphere is near white in light mode and mid grey in dark.

| Role | Type | When unmapped | What it styles |
| --- | --- | --- | --- |
| `title` | Font | `.headline` | The bar's title. |
| `note` | Font | `.callout` | The empty view's words and a failure's. |
| `note2` | Font | `.footnote` | The line under the spinner while the graph loads. |
| `passage` | Font | `.body` | A node's text, in the panel and in its sheet. |
| `accent` | Color | `.accentColor` | The bar's symbols, the text sheet's close mark, and in the scene the selected node's group: the open hub, its leaves and the edges to them. |
| `foreground` | Color | `.primary` | The title (at 0.75), the passage, and the status words (at 0.6). |
| `hubBadge` | Color | `.indigo` | A hub's badge: its words, on the colour at 0.3. |
| `leafBadge` | Color | `.blue` | A leaf's badge: its words, on the colour at 0.2. |

### `strings`: `key = words`

Sets any word the views say. Quotes are optional; a quoted value reads `\n` and `\"`. `{level}` stands for a hub's level; a line must say the same `{…}` as the default.

| Key | Default | What it is |
| --- | --- | --- |
| `title` | Graph | The bar's title. |
| `hub` | Level {level} | A hub's badge, `{level}` its level: `L{level} Hub` reads "L2 Hub". |
| `leaf` | Leaf | A leaf's badge. |
| `loading` | Loading… | Under the spinner while the graph loads. |
| `empty` | Nothing to show yet. | Under the empty view's symbol, when the graph has no nodes. |
| `retry` | Retry | The button under a failure, which loads again. |
| `close` | Close | The accessibility label of the panel's close mark and of the text sheet's. |
| `fit` | Show All | The accessibility label of the button that fits the whole graph in view. |
| `previous` | Previous | The accessibility label of the button that selects the node before. |
| `next` | Next | The accessibility label of the button that selects the node after. |

### `tuning`: `key = value`

Sets any number, symbol or motion the views use. A number is a decimal (`0.45`), a whole number an integer, a symbol an SF Symbol's name, a design one of default, serif, rounded or monospaced, a material one of ultraThin, thin, regular, thick or ultraThick, and a motion an animation as SwiftUI writes it (`.spring(response: 0.4, dampingFraction: 0.8)`). Each is written into the views where a person would write the number: `SCNSphere(radius: 0.18)`, `text.prefix(240)`.

| Key | Kind | Default | What it sets |
| --- | --- | --- | --- |
| `hubRadius` | number | `0.45` | A hub's radius before its level adds to it. |
| `hubRadiusStep` | number | `0.18` | What each level adds to a hub's radius. |
| `leafRadius` | number | `0.18` | A leaf's radius. |
| `ringRadius` | number | `3` | The circle the hubs stand on, facing the camera, the first at the top; a lone hub stands at the centre. |
| `leafDistance` | number | `1.8` | How far a leaf stands from its hub. |
| `edgeRadius` | number | `0.03` | An edge's radius: a cylinder from one node's centre to the other's. |
| `cameraDistance` | number | `14` | How far back the camera stands, looking at the centre; fitting the graph in view never comes nearer. |
| `hubFocus` | number | `18` | How far the camera stands from a hub it centres on. |
| `leafFocus` | number | `12` | How far the camera stands from a leaf it centres on. |
| `fieldOfView` | number | `50` | The camera's vertical field of view, in degrees. |
| `pulseScale` | number | `1.12` | How large the selected node grows as it pulses. |
| `pulseDuration` | number | `1` | The seconds each way of the selected node's pulse. |
| `excerpt` | integer | `240` | How many characters of a node's text the panel shows; a tap shows all of it. |
| `badgeSize` | number | `12` | The badge's point size. |
| `badgeDesign` | design | `serif` | The badge's font design. |
| `panelRadius` | number | `20` | The panel's corner radius. |
| `panelMaterial` | material | `ultraThin` | The panel's material. |
| `showAnimation` | animation | `.spring(response: 0.4, dampingFraction: 0.8)` | How the panel rises and leaves. |
| `fitSymbol` | symbol | `rectangle.expand.diagonal` | The bar's leading button, which fits the whole graph in view. |
| `previousSymbol` | symbol | `chevron.left` | The button that selects the node before. |
| `nextSymbol` | symbol | `chevron.right` | The button that selects the node after. |
| `closeSymbol` | symbol | `xmark.circle.fill` | The panel's close mark. |
| `emptySymbol` | symbol | `gyroscope` | The symbol over the empty view's words. |
| `failedSymbol` | symbol | `wifi.exclamationmark` | The symbol over a failure. |

### `launch`: `destination = state(ids)`

Maps a `-destination <name>` launch argument (read as `UserDefaults.standard.string(forKey: "destination")`) to the state the root view opens in, and the ids it loads, in parentheses after the state (`atlas = graph(space-001, space-002)`); with none, the page's own `ids`. `load` is called with those ids as the view appears; once the nodes are there the first hub is selected, and a state's sheet is put up without animation 600 ms later. The app's navigation opens the graph itself for the destination; with no line, every launch is a plain one.

| State | What is on screen |
| --- | --- |
| `graph` | The graph of these ids (the page's own when none are given), the first hub selected, its leaves out and its panel up. |
| `text` | As `graph`, with the selected node's whole text open in its sheet. |


## What it writes

Into `into` (`Components/Graph` when left out), every file parsed with `swiftc -parse` before any lands:

| File | What it is |
| --- | --- |
| `GraphProtocols.swift` | The two protocols the views read, a default for every requirement, and the kit's own value types |
| `GraphValue.swift` | The conversions every mapped value goes through |
| `GraphLook.swift`, `GraphStrings.swift`, `GraphLaunch.swift` | The look roles, every word and the launch state, from the call |
| `GraphSupport.swift` | The graph as the scene draws it (each node and link once, which leaves are out, which nodes glow), where each node stands, how a node's text reads, the light tap |
| `GraphStage.swift` | The SceneKit scene: the camera and its lights, a clay sphere for every node (a hub's with two or three lumps, hovering), a cylinder for every link, and how they show the open hub, the selection, the theme and the accent |
| `GraphScene.swift` | The SCNView with the built-in camera control, and the tap that picks a node |
| `GraphView.swift` | The root a page shows: the scene, the card of the selected node, the bar, loading, empty and failure |
| `GraphBar.swift` | The bar: the title, fit the whole graph in view, the node before and after |
| `GraphPanel.swift`, `GraphBadge.swift`, `GraphTextSheet.swift` | The selected node's card, its level badge, and its whole text in a sheet |
| `GraphLoadingView.swift`, `GraphEmptyView.swift`, `GraphFailedView.swift` | The spinner and its words, no nodes, and a failure with Retry |
| `GraphPreviews.swift` | The sample graph every `#Preview` draws |
| `Conformances/<Type>+<Role>.swift` | One extension a mapping line |

A later call into the same folder writes the kit again; a conformance the new call no longer maps is removed.

The root, as the answer's `roots` gives it:

```swift
GraphView(ids: [String] = [], nodes: [GraphNode], load: (([String]) async throws -> Void)? = nil)
// with an `edge:` line:
GraphView(ids: [String] = [], nodes: [Page], edges: [PageLink], load: (([String]) async throws -> Void)? = nil)
```

`load` is called with `ids` (or the launch's) as the view appears; a spinner over `loading` shows until there are
nodes, a throw shows the failure and Retry, and no nodes after a load shows `empty`. Once nodes are there the first
in the stepping order (the higher levels first, then by id) is selected and its hub opened. A tap on a hub opens or
closes it and selects it; a tap on a leaf selects it; a tap elsewhere, or on the card's close mark, selects none. The
root wears its own bar (the title inline, in `title`) and needs a navigation stack around it, which a sheet's host
gives it. The views never route: the app presents the graph, and the kit presents only the text sheet.

## What it makes

| Kind | What | Into | Never |
| --- | --- | --- | --- |
| `view` | a 3D graph of how things connect as reusable SwiftUI and SceneKit views (GraphView, the root a page shows, and its scene, panel, badge, text sheet and status views); a page shows it with GraphView(nodes:load:) | `Components/Graph/*` | routes; never a page, a service, a client or a model type |
| `conformance` | the app's own types made the graph's: one extension a mapping line | `Components/Graph/Conformances/*` | a change to the app's types themselves |

## What it answers

A `granite-answer/1` answer (Granite's `Schema/GraniteAgent.md` §4.2): `paths`, `made` against `expected` by kind and
name, `problems` for what it could only do in part, and its own keys beside them: `views` (the root first),
`conformances`, `roots` (the root's initializer, for the page body that calls it) and `notes` (what the app still has
to do).

## How it refuses

With an `AgentRefusal` of kind `call`: every reason at once, each naming the field, the line and what it accepts, and
nothing written. A line it cannot read, a key it does not know, a value of the wrong kind, a role mapped twice, a
node line with no `id` or an edge line without both ends, a field the app's type does not have or holds the wrong
kind, a launch state it does not know.

## Changes

Newest first.

### 2026-11-15 · first version

The Atlas of Seer's original, mirrored subview by subview: the scene's lights, camera, clay bodies, lumps, hover,
string links and their swell, the open hub's group in the accent and its glow, the selected node's pulse, the camera
easing to a hub or a leaf; the frosted card with its badge, id, close mark, divider and passage; the full-text sheet;
the bar's fit and step buttons; the loading, empty and failure views. Where Seer's spec departs from the original it
follows the spec: a title in the bar, the built-in camera control, the hubs on a circle facing the camera and the
leaves round them, the camera 14 back. Measured: the Seer call builds for the iPhone simulator in Swift 6 and Swift 5
(`GRAPH_BUILD=1`), its scene renders bronze over plain in light and dark, and every `code` item of the scorecard's
atlas area matches its output; B-data-8, the mock graph's ids, is `$mocks`'.
