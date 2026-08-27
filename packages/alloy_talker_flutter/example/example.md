# alloy_talker_flutter example

```dart
import 'package:alloy_talker/alloy_talker.dart';
import 'package:alloy_talker_flutter/alloy_talker_flutter.dart';
import 'package:talker/talker.dart';

final talker = Talker();

final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyTalkerObserver(talker)],
);

// …and, from a debug menu:
Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => AlloyTalkerScreen(talker: talker)),
);
```

The screen takes its colours from `AlloyInspectorTheme` when one is above it, and from the
application's own `Theme` when none is. A full example lives in
[`examples/graph_events`](https://github.com/rutikeyone/alloy/tree/main/examples/graph_events).
