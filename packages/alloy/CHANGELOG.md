## 0.1.0

- Initial release.
- `AlloyScope`: a hierarchy of scopes, `O(1)` resolution, lazy and eager
  singletons, transients, named registrations, `getAll` and parameterized
  factories.
- Disposal is LIFO by **creation** order, not declaration order. Teardown is
  best-effort under a global deadline: a step that fails or times out is
  recorded in `AlloyDisposeError` and the rest still run.
- `AlloyApplication`: two-phase startup. Phase 0 runs `@AlloyBootstrap` steps
  before the container exists; the root scope adopts them, so a step holding a
  resource is released last.
- Kahn's algorithm layer by layer, so independent async initializers run
  concurrently through `Future.wait`. Cycles raise `AlloyCycleError` naming the
  path — at build time in generated code, and at runtime through
  `AlloyResolutionTracker` for hand-written factories.
- Observability without dependencies: `AlloyObserver` with typed events,
  `AlloyLogObserver` turning them into records, and sinks —
  `AlloyDeveloperLogSink`, `AlloyPrintLogSink`, `AlloyMultiSink`, and
  `AlloyLogSink.from` to adapt any logger in one line.
- A retained registration can name a `dispose` callback, so the scope can
  close a type that implements neither `Disposable` nor `AsyncDisposable` —
  a client from another package, say. `adopt` takes one too. Absent from
  `registerFactory` and `registerParamFactory`, which retain nothing.
