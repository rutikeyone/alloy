# alloy_test example

Build the graph once per test, override what the test needs, and check the whole thing resolves.

```dart
import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

void main() {
  late AlloyScope app;

  setUp(() async {
    app = await alloyTestScope(root: const AppScope(), rootName: 'app');
  });

  test('the graph is complete', () async {
    await expectGraphResolves(app);
  });

  test('a fake clock reaches the greeter', () {
    final scope = app.pushForTest()
      ..registerSingleton<Clock>(FixedClock(DateTime.utc(2026)))
      ..registerLazySingleton<Greeter>(const GreeterFactory());

    expect(scope.get<Greeter>().greet(), contains('2026'));
  });
}
```

`Greeter` is re-registered on purpose: it is owned by the root, so without that line it would
resolve the real `Clock` and never see the fake. `scope.ownerOf<Greeter>()` is how you find that out
rather than guessing.

Checking the graph is terminal — it builds every lazy singleton — so keep it in its own test.
