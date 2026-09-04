## 0.1.0

- `CobaltNoScopeError` and `CobaltNoAppScopeError` replace the bare `CobaltError`
  the two lookups used to throw, so a caller can catch the one it means. The
  first also explains the pushed-route case in its message.
- Initial release.
- `CobaltAppScope`: owns the root scope for the whole app. It builds the graph
  inside `runApp`, shows loading and error states with retry, exposes
  `restart()`, and disposes the root on unmount. Because it re-keys the
  provider, the subtree rebuilds against the new root after a restart.
- `CobaltScopeWidget`: a child scope whose lifetime is a widget's lifetime.
- `CobaltScopeProvider` and `context.cobalt<T>()`, plus `CobaltScopedWidget` and
  `CobaltScopedStatefulWidget` as bases.
- `disposeOnExitRequest` is opt-in and only meaningful on macOS and Linux,
  where `onExitRequested` fires and the exit is actually cancellable.
