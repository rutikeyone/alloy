# cobalt_talker example

Each kind of Cobalt event becomes its own `TalkerLog` type, with its own title
and colour — which is the reason to reach for talker rather than a plain sink.

```dart
import 'package:cobalt/cobalt.dart';
import 'package:cobalt_talker/cobalt_talker.dart';
import 'package:talker/talker.dart';

final talker = Talker();

final scope = await CobaltApplication.start(
  root: const AppScope(),
  observers: [CobaltTalkerObserver(talker)],
);
```

The log then carries `cobalt-scope`, `cobalt-startup`, `cobalt-instance` and
`cobalt-failure` entries as separate, colour-coded types. Those four titles are
also the keys `talker_flutter` colours rows by, which is what lets
[`cobalt_talker_flutter`](https://pub.dev/packages/cobalt_talker_flutter) dress
its screen in the same palette as the inspector.

Per-instance records are off by default — on a real graph they drown the signal
the log was opened for. Turn them on deliberately:

```dart
CobaltTalkerObserver(talker, verbose: true)
```

With `talker_flutter`, `TalkerScreen` shows the whole thing live; that is what
[`examples/graph_events`](https://github.com/rutikeyone/alloy/tree/main/examples/graph_events) does.
