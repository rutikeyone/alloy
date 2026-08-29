## 0.1.0

- Initial release.
- `AlloyBloc` — a mixin bridging `BlocBase.close` to Alloy's
  `AsyncDisposable`, so the scope that built a bloc is the thing that closes
  it.
- `closeBloc` — the same reach for a class a mixin cannot touch, usable as
  `@AlloyInject(dispose: closeBloc)` and at a hand-written registration.
