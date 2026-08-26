# alloy_inspector example

Install the log where the graph is built, then open the screen from a debug menu.

```dart
import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_inspector/alloy_inspector.dart';
import 'package:flutter/material.dart';

final log = AlloyInspectorLog();

Future<void> main() async {
  final scope = await AlloyApplication.start(
    root: const AppScope(),
    rootName: 'app',
    observers: [log],
  );

  runApp(
    MaterialApp(
      home: AlloyScopeProvider(scope: scope, child: const HomeScreen()),
    ),
  );
}

class DebugMenuButton extends StatelessWidget {
  const DebugMenuButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.account_tree_outlined),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AlloyInspectorScreen(log: log)),
    ),
  );
}
```

The log cannot be attached later: a scope fixes its observers when it is constructed and passes them
to every child it pushes.
