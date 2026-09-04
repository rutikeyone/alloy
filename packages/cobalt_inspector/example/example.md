# cobalt_inspector example

Install the log where the graph is built, then open the screen from a debug menu.

```dart
import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:cobalt_inspector/cobalt_inspector.dart';
import 'package:flutter/material.dart';

final log = CobaltInspectorLog();

Future<void> main() async {
  final scope = await CobaltApplication.start(
    root: const AppScope(),
    rootName: 'app',
    observers: [log],
  );

  runApp(
    MaterialApp(
      home: CobaltScopeProvider(scope: scope, child: const HomeScreen()),
    ),
  );
}

class DebugMenuButton extends StatelessWidget {
  const DebugMenuButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.account_tree_outlined),
    // Read the scope here, at the button: a pushed route is built by the
    // navigator, which sits above the provider.
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CobaltInspectorScreen(log: log, scope: context.cobaltScope),
      ),
    ),
  );
}
```

The log cannot be attached later: a scope fixes its observers when it is constructed and passes them
to every child it pushes.

The screens take their colours from the host's `Theme` and their language from the host's locale,
so nothing above is required for either. To choose them, pass `theme:` or put an
`CobaltInspectorTheme` above the debug menu, and add `CobaltInspectorL10n.delegate` to the app's
`localizationsDelegates`.
