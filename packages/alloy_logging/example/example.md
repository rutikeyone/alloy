# alloy_logging example

Writes Alloy's events into dart.dev's `package:logging`.

```dart
import 'package:alloy/alloy.dart';
import 'package:alloy_logging/alloy_logging.dart';
import 'package:logging/logging.dart';

Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) => print(record));

final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyLogObserver(AlloyLoggingSink())],
);
```

`AlloyLogObserver` turns typed events into `AlloyLogRecord`s, and the sink
writes them out; `package:logging` has no notion of a record type of its own,
which is why this is a sink rather than a whole observer.

Do not confuse this package with `alloy_logger`, one letter apart, which adapts
`package:logger` instead.
