# cobalt_talker_flutter example

```dart
import 'package:cobalt_talker/cobalt_talker.dart';
import 'package:cobalt_talker_flutter/cobalt_talker_flutter.dart';
import 'package:talker/talker.dart';

final talker = Talker();

final scope = await CobaltApplication.start(
  root: const AppScope(),
  observers: [CobaltTalkerObserver(talker)],
);

// …and, from a debug menu:
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => CobaltTalkerScreen(talker: talker)),
);
```

The screen takes its colours from `CobaltInspectorTheme` when one is above it, and from the
application's own `Theme` when none is. A full example lives in
[`examples/graph_events`](https://github.com/rutikeyone/alloy/tree/main/examples/graph_events).
