## 0.1.0

- Each log carries its title as its `key` as well. `talker_flutter` colours a
  row by key and falls back to the log level without one, so a themed screen
  used to paint every startup entry the same blue as any other info line.
- Initial release.
- An `CobaltObserver` — not just a sink — so each kind of Cobalt event becomes its
  own `TalkerLog` type with its own title and colour: `cobalt-scope`,
  `cobalt-startup`, `cobalt-instance`, `cobalt-failure`.
- Per-instance records are off by default: on a real graph they drown the
  signal the log was opened for.
