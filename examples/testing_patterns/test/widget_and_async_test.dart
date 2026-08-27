import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing_patterns/testing_patterns.dart';

/// Two things that cost real time to learn the hard way.
void main() {
  group('building the graph', () {
    late AlloyScope app;

    // In setUp, not inside testWidgets. `testWidgets` runs its body in a
    // fake-async zone where a real Future.delayed never completes, so an async
    // initializer started in there hangs the test until the suite times out —
    // with no error pointing at the cause.
    setUp(() async {
      app = await alloyTestScope(root: const AppScope(), rootName: 'app');
    });

    AlloyScope scopeWith(String greeting, int hour) {
      return app.pushForTest()
        ..registerSingleton<Clock>(FixedClock(DateTime.utc(2026, 8, 23, hour)))
        ..registerSingleton<GreetingStore>(InMemoryGreetingStore(greeting))
        ..registerLazySingleton<Greeter>(const GreeterFactory());
    }

    Future<void> pump(WidgetTester tester, AlloyScope scope) async {
      await tester.pumpWidget(
        AlloyScopeProvider(
          scope: scope,
          child: const MaterialApp(home: GreetingScreen(name: 'Ada')),
        ),
      );
      await tester.pumpAndSettle();
    }

    String greetingOf(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('greeting'))).data!;

    testWidgets('a widget resolves what the scope above it provides', (
      tester,
    ) async {
      await pump(tester, scopeWith('Hello', 9));

      expect(greetingOf(tester), 'Hello, Ada — it is 9:00');
    });

    testWidgets('the widget never learns where its dependency came from', (
      tester,
    ) async {
      await pump(tester, scopeWith('Evening', 18));

      expect(
        greetingOf(tester),
        'Evening, Ada — it is 18:00',
        reason: 'same widget, different scope, no change to the widget',
      );
    });
  });

  // Assertions about the graph alone belong in a plain `test`: no fake-async
  // zone, so real delays behave. Keep them out of testWidgets even when the app
  // under test is a Flutter app.
  test('the graph can be asserted on without any widgets', () async {
    final app = await alloyTestScope(root: const AppScope());

    expect(app.isRegistered<Greeter>(), isTrue);
    expect(app.get<Clock>(), isA<SystemClock>());
  });
}
