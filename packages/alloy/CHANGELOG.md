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
- `AlloyResolver.getOrNull` resolves an optional dependency, returning null
  only when nothing is registered — "registered but not ready" still throws.
- `AlloyScope` gained four read-only members for diagnostics: `keys`,
  `visibleKeys` (mapped to the owning scope), `root` and `debugDescribeTree`.
  None of them throws on a scope that is being torn down.
- `getWithParam` checks the value against the parameter type the factory was
  registered with, raising `AlloyParamTypeError` naming the registration and
  both types, instead of a cast error from inside the factory. A subtype of the
  registered type is accepted.
- Fixed: the resolution tracker removed a key only from the top of its stack,
  so a registration in a parallel init level that finished before the one
  entered after it stayed behind. Because one tracker serves the whole scope
  tree, the next scope registering that key was told it was a cycle.
- `debugKindOf` and `debugResolve` answer by `AlloyKey` rather than by type
  argument, which is what lets a tool walk a whole graph — `get<T>` cannot be
  called from a loop over `keys`, since Dart has no way to turn a `Type` back
  into a type argument. `debugResolveWithParam` is the parameterized twin.
- `AlloyInspector.enable()` publishes the live scope tree over the VM service as
  `ext.alloy.getScopeTree`, and `AlloyDevToolsObserver` posts every event where
  DevTools' Logging view shows it. Both are meant to sit behind an `assert`, and
  neither adds a dependency.
- `AlloyScopeRegistry` tracks live roots weakly, and is pruned as a scope is
  disposed rather than when it is collected: nothing about `WeakReference`
  promises when, and a stale entry would report a scope that is gone.

