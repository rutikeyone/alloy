# alloy_logger

Adapter for [package:logger](https://pub.dev/packages/logger) — the one with the boxed console
output — for [Alloy](https://github.com/rutikeyone/alloy).

> Not `alloy_logging`. That adapts [package:logging](https://pub.dev/packages/logging), the
> dart.dev package whose name differs by one letter.

```dart
final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyLogObserver(AlloyLoggerSink())],
);
```

Unlike `package:logging`, this one prints by itself: the default `Logger` already has a console
output and `PrettyPrinter`. Pass your own if you have configured one.

## Levels

Alloy's five map one-to-one onto `trace`, `debug`, `info`, `warning`, `error`. None of them can
land on `Level.all`, `Level.off` or `Level.nothing`, which matters because `Logger.log` throws
`ArgumentError` on those — a test in this package pins it.
