## 0.1.0

- English, Russian and Chinese, chosen from the host app's locale. Installing
  `AlloyInspectorL10n.delegate` is the documented path; with no delegate the
  ambient locale still decides, and English is the floor. Lifetimes, levels and
  the records themselves stay in Alloy's own words.
- `AlloyInspectorThemeData` and `AlloyInspectorTheme`: the screens take their
  colours from the host application, and an app can name its own.
- The log carries the time each record arrived, is searchable, filters by
  family, opens a record whole and copies it, and can be paused.
- The tree searches registrations and folds every node at once; the built list
  groups by scope or by lifetime.
- Initial release.
- `AlloyInspectorScreen` — three views over a running graph: the live scope
  tree, what was built, and the event log.
- The tree walks live scopes rather than replaying events, because
  `AlloyScopeRef` cannot tell two same-named siblings apart. Each registration
  shows its lifetime from `debugKindOf`, and an inherited one names the scope
  that owns it.
- Nothing is resolved in order to display it: building an instance is a
  separate action that states it changes the graph.
- `AlloyInspectorLog` records what the graph reports and notifies on the next
  turn, since observer callbacks arrive mid-frame. It must be passed where the
  graph is built — observers are fixed at construction.
