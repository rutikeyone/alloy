## 0.1.0

- `AlloyNoScopeError` and `AlloyNoAppScopeError` replace the bare `AlloyError`
  the two lookups used to throw, so a caller can catch the one it means. The
  first also explains the pushed-route case in its message.
- Initial release.
- `AlloyAppScope`: owns the root scope for the whole app. It builds the graph
  inside `runApp`, shows loading and error states with retry, exposes
  `restart()`, and disposes the root on unmount. Because it re-keys the
  provider, the subtree rebuilds against the new root after a restart.
- `AlloyScopeWidget`: a child scope whose lifetime is a widget's lifetime.
- `AlloyScopeProvider` and `context.alloy<T>()`, plus `AlloyScopedWidget` and
  `AlloyScopedStatefulWidget` as bases.
- `disposeOnExitRequest` is opt-in and only meaningful on macOS and Linux,
  where `onExitRequested` fires and the exit is actually cancellable.
