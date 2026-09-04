## 0.1.0

- Initial release.
- `CobaltBloc` — a mixin bridging `BlocBase.close` to Cobalt's
  `AsyncDisposable`, so the scope that built a bloc is the thing that closes
  it.
- `closeBloc` — the same reach for a class a mixin cannot touch, usable as
  `@CobaltInject(dispose: closeBloc)` and at a hand-written registration.
