# cobalt_logging

Adapter for [package:logging](https://pub.dev/packages/logging), the dart.dev one, for
[Cobalt](https://github.com/rutikeyone/cobalt).

> Not `cobalt_logger`. That adapts [package:logger](https://pub.dev/packages/logger), a different
> package whose name differs by one letter. This one is for the dart.dev `logging`.

```dart
Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) => print(record));

final scope = await CobaltApplication.start(
  root: const AppScope(),
  observers: [CobaltLogObserver(CobaltLoggingSink())],
);
```

`package:logging` routes rather than prints, so **nothing appears until something listens** — the
two lines above are not optional decoration.

## Levels

| Cobalt | logging |
|---|---|
| `trace` | `FINEST` |
| `debug` | `FINE` |
| `info` | `INFO` |
| `warning` | `WARNING` |
| `error` | `SEVERE` |

`trace` lands on `FINEST` rather than `FINE` because Cobalt's trace level is per-instance, and a
graph of any size produces a lot of it. `CobaltLogObserver` also drops it by default; pass
`minimumLevel: CobaltLogLevel.trace` to let it through.
