# alloy_logger example

Writes Alloy's events into `package:logger`.

```dart
import 'package:alloy/alloy.dart';
import 'package:alloy_logger/alloy_logger.dart';

final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyLogObserver(AlloyLoggerSink())],
);
```

Pass your own `Logger` if the defaults do not suit:

```dart
AlloyLoggerSink(Logger(printer: PrettyPrinter()))
```

Do not confuse this package with `alloy_logging`, one letter apart, which
adapts dart.dev's `package:logging` instead.
