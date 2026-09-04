# cobalt_logging example

Writes Cobalt's events into dart.dev's `package:logging`.

```dart
import 'package:cobalt/cobalt.dart';
import 'package:cobalt_logging/cobalt_logging.dart';
import 'package:logging/logging.dart';

Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) => print(record));

final scope = await CobaltApplication.start(
  root: const AppScope(),
  observers: [CobaltLogObserver(CobaltLoggingSink())],
);
```

`CobaltLogObserver` turns typed events into `CobaltLogRecord`s, and the sink
writes them out; `package:logging` has no notion of a record type of its own,
which is why this is a sink rather than a whole observer.

Do not confuse this package with `cobalt_logger`, one letter apart, which adapts
`package:logger` instead.
