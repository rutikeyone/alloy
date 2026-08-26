## 0.1.0

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
