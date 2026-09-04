# cobalt_logger example

Writes Cobalt's events into `package:logger`.

```dart
import 'package:cobalt/cobalt.dart';
import 'package:cobalt_logger/cobalt_logger.dart';

final scope = await CobaltApplication.start(
  root: const AppScope(),
  observers: [CobaltLogObserver(CobaltLoggerSink())],
);
```

Pass your own `Logger` if the defaults do not suit:

```dart
CobaltLoggerSink(logger: Logger(printer: PrettyPrinter()))
```

Do not confuse this package with `cobalt_logging`, one letter apart, which
adapts dart.dev's `package:logging` instead.
