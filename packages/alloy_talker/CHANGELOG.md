## 0.1.0

- Each log carries its title as its `key` as well. `talker_flutter` colours a
  row by key and falls back to the log level without one, so a themed screen
  used to paint every startup entry the same blue as any other info line.
- Initial release.
- An `AlloyObserver` — not just a sink — so each kind of Alloy event becomes its
  own `TalkerLog` type with its own title and colour: `alloy-scope`,
  `alloy-init`, `alloy-dispose`.
- Per-instance records are off by default: on a real graph they drown the
  signal the log was opened for.
