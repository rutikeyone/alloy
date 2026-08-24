# alloy example

The runtime, with no code generation — Manual Mode. The generator writes
exactly this, using only what is exported here.

```dart
import 'package:alloy/alloy.dart';

class Database {
  var isOpen = false;
}

final class DatabaseFactory implements AlloyFactory<Database> {
  const DatabaseFactory();

  @override
  Database create(AlloyResolver resolver) => Database();
}

class AppScope implements AlloyScopeBuilder {
  const AppScope();

  @override
  void build(AlloyScope scope) =>
      scope.registerLazySingleton<Database>(const DatabaseFactory());
}

Future<void> main() async {
  final app = await AlloyApplication.start(
    root: const AppScope(),
    rootName: 'app',
  );

  print(app.get<Database>());

  // A child scope: everything built inside dies with it, in reverse order of
  // creation. This is what makes sign-out a single call.
  final session = app.push('session:42');
  await session.init();
  await session.dispose();

  await app.dispose();
}
```

More: [`examples/manual_mode`](https://github.com/rutikeyone/alloy/tree/main/examples/manual_mode).
