## 0.1.0

- Initial release.
- An `AlloyObserver` — not just a sink — so each kind of Alloy event becomes its
  own `TalkerLog` type with its own title and colour: `alloy-scope`,
  `alloy-init`, `alloy-dispose`.
- Per-instance records are off by default: on a real graph they drown the
  signal the log was opened for.
