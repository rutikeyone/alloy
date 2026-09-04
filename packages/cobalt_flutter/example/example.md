# cobalt_flutter example

`CobaltAppScope` owns the root scope for as long as the app is mounted. Its
usual home is `MaterialApp.builder`, where the loading and error screens are
rendered with the app's own theme.

```dart
import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(
  MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    builder: CobaltAppScope.builder(
      root: const AppScope(),
      rootName: 'app',
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
      errorBuilder: (context, error, retry) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$error'),
              FilledButton(onPressed: retry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    ),
    home: const HomeScreen(),
  ),
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('${context.cobalt<Database>()}')));
}
```

A scope that lives as long as one screen is `CobaltScopeWidget`; a full app with
one screen per capability is
[`examples/notes_app`](https://github.com/rutikeyone/cobalt/tree/main/examples/notes_app).
