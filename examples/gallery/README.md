# gallery

Every Alloy example in one app, organised by capability rather than by project.

```bash
flutter run
```

Thirteen entries in six sections. Each one that has a UI opens with a graph **of its own** — built
when you open it, disposed when you leave — so opening two gives you two unrelated scope trees.
That is the thing the gallery is really demonstrating, which is why there is no container above the
entries.

Three entries have no UI at all (`Teardown`, `Manual mode`, `Testing patterns`): they show their
console output instead of a button. A gallery that offered to "open" a command-line program would
be lying about what happens next.

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
