## 0.1.0

- Initial release.
- `alloyTestScope` / `alloyTestRoot` build a graph and dispose it with the
  test; `pushForTest` does the same for an override scope.
- `checkGraph` / `expectGraphResolves` resolve everything a scope can see and
  report every hole at once. This is the only way to check a hand-written
  graph, since a factory never declares what it will ask for. It is terminal:
  resolving is the check, so afterwards every lazy singleton is built.
- `ownerOf<T>` names the scope that owns a registration, which is what decides
  whether an override will actually be seen.
- `DisposeRecorder` keeps its log per instance rather than globally, because
  teardown is not awaited and a shared list fails the wrong test.
- `CapturingObserver`, plus `FnFactory` / `ValueFactory` / `AsyncFnFactory`.
