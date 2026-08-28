# gallery

Every Alloy example in one app, organised by capability rather than by project.

```bash
flutter run
```

Fourteen entries in six sections. Each one that has a UI opens with a graph **of its own** — built
when you open it, disposed when you leave — so opening two gives you two unrelated scope trees.
That is the thing the gallery is really demonstrating, which is why there is no container above the
entries.

Three entries have no UI at all (`Teardown`, `Manual mode`, `Testing patterns`): they show their
console output instead of a button. A gallery that offered to "open" a command-line program would
be lying about what happens next.

## Three languages

English, Russian and Chinese, switched from the chips at the top of the hub. Every string the
gallery owns — the catalog's titles, one-liners and bullet points, the section headings, the
chrome — comes from `l10n/gallery_*.arb`; `buildCatalog` takes a `GalleryL10n` and holds no prose
of its own, which is what a test checks by building the catalog twice and insisting the two
disagree.

`AlloyInspectorL10n.delegate` is registered here beside the gallery's own, so the inspector entry
follows the switch too. It would follow it without the delegate — that is the fallback the package
ships — but the gallery shows the documented path rather than the one you get for free.

What is **not** translated: the screens mounted from `notes_app`, `flow_scopes`, `graph_events` and
`codegen_basics`. They belong to those packages, and dragging four more `l10n` setups behind a
language switcher would be a poor trade for a demo.

## Where the screens come from

The gallery owns its design and its catalog, and nothing else. The screens are mounted from the
example packages next door:

| Package | Supplies |
|---|---|
| `notes_app` | seven entries across Startup, Injection and Scopes |
| `flow_scopes` | Navigation flows |
| `graph_events` | Graph events |
| `codegen_basics` | Generated container |

Those stay separate packages for a reason that is not tidiness: `alloy_container` aggregates a
whole package into a single `$AlloyRootScope`, and two `@AlloyScopeRoot` classes in one package is
a generation error. Merged, `notes_app` and `codegen_basics` would share one graph — which is
exactly what a gallery of independent examples must not do.

## The icons

One family, drawn as nodes and edges on a 24px grid — the same primitives the framework is about.
They are a `CustomPainter` rather than an SVG dependency, because circles and lines are all they
ever were; dashes are cut from the path by hand, since Flutter's `Paint` has none.
