# alloy_logging

Adapter for [package:logging](https://pub.dev/packages/logging), the dart.dev one, for
[Alloy](https://github.com/rutikeyone/alloy).

> Not `alloy_logger`. That adapts [package:logger](https://pub.dev/packages/logger), a different
> package whose name differs by one letter. This one is for the dart.dev `logging`.

```dart
Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) => print(record));

final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyLogObserver(AlloyLoggingSink())],
);
```

`package:logging` routes rather than prints, so **nothing appears until something listens** — the
two lines above are not optional decoration.

## Levels

| Alloy | logging |
|---|---|
| `trace` | `FINEST` |
| `debug` | `FINE` |
| `info` | `INFO` |
| `warning` | `WARNING` |
| `error` | `SEVERE` |

`trace` lands on `FINEST` rather than `FINE` because Alloy's trace level is per-instance, and a
graph of any size produces a lot of it. `AlloyLogObserver` also drops it by default; pass
`minimumLevel: AlloyLogLevel.trace` to let it through.
