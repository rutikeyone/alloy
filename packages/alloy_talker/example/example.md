# alloy_talker example

Each kind of Alloy event becomes its own `TalkerLog` type, with its own title
and colour — which is the reason to reach for talker rather than a plain sink.

```dart
import 'package:alloy/alloy.dart';
import 'package:alloy_talker/alloy_talker.dart';
import 'package:talker/talker.dart';

final talker = Talker();

final scope = await AlloyApplication.start(
  root: const AppScope(),
  observers: [AlloyTalkerObserver(talker)],
);
```

The log then carries `alloy-startup`, `alloy-scope`, `alloy-init` and
`alloy-dispose` entries as separate, colour-coded types.

Per-instance records are off by default — on a real graph they drown the signal
the log was opened for. Turn them on deliberately:

```dart
AlloyTalkerObserver(talker, verbose: true)
```

With `talker_flutter`, `TalkerScreen` shows the whole thing live; that is what
[`examples/logging`](https://github.com/rutikeyone/alloy/tree/main/examples/logging) does.
