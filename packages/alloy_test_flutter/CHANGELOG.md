## 0.1.0

- Initial release.
- `settle` — the two pumps a starting graph needs. `pumpAndSettle` hangs on the
  indefinite animation a `loading` builder usually shows.
- `mountedRootScope` — the graph a mounted application owns, read from the
  published provider rather than looked up from a context, and climbed to the
  root so a screen that owns a scope does not answer instead.
