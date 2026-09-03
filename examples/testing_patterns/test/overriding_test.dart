import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing_patterns/testing_patterns.dart';

/// Overriding a dependency: push a child scope and register it again.
///
/// Registering twice in *one* scope is an error — that catches a real mistake.
/// Shadowing from a child is the supported way, and it is the same mechanism
/// production code uses for session and flow scopes. Tests get no special path.
void main() {
  late AlloyScope app;

  setUp(() async {
    app = await alloyTestScope(root: const AppScope(), rootName: 'app');
  });

  AlloyScope underTest() => app.pushForTest();

  group('what shadowing does and does not reach', () {
    test('a child registration wins for whoever asks the child', () {
      final scope = underTest()
        ..registerSingleton<Clock>(FixedClock(DateTime.utc(2026, 8, 23, 9)));

      expect(scope.get<Clock>(), isA<FixedClock>());
    });

    test('the parent keeps the real one', () {
      underTest().registerSingleton<Clock>(FixedClock(DateTime.utc(2026)));

      expect(app.get<Clock>(), isA<SystemClock>());
    });

    test(
      'but a service registered in the parent does NOT see the override',
      () async {
        // The sharp edge, and the reason this example exists. A factory is called
        // with the scope that *owns* the registration, not the scope you asked
        // from. Greeter lives in the root, so it resolves GreetingStore from the
        // root — the child's fake is invisible to it.
        final scope = underTest()
          ..registerSingleton<GreetingStore>(
            const InMemoryGreetingStore('Hello'),
          );

        await expectLater(
          scope.get<Greeter>().greet('Ada'),
          throwsUnsupportedError,
          reason: 'it reached the real store, not the fake one in the child',
        );

        // And this is how to see it coming instead of debugging it: the consumer
        // is owned higher up than the override, so the override cannot reach it.
        expect(scope.ownerOf<Greeter>(), same(app));
        expect(scope.ownerOf<GreetingStore>(), same(scope));
      },
    );

    test(
      'so override the consumer too, and it resolves from the child',
      () async {
        final scope = underTest()
          ..registerSingleton<Clock>(FixedClock(DateTime.utc(2026, 8, 23, 9)))
          ..registerSingleton<GreetingStore>(
            const InMemoryGreetingStore('Hello'),
          )
          ..registerLazySingleton<Greeter>(const GreeterFactory());

        expect(
          await scope.get<Greeter>().greet('Ada'),
          'Hello, Ada — it is 9:00',
        );
      },
    );
  });

  test('overriding twice in one scope is an error, on purpose', () {
    final scope = underTest()
      ..registerSingleton<Clock>(FixedClock(DateTime.utc(2026)));

    expect(
      () => scope.registerSingleton<Clock>(FixedClock(DateTime.utc(2027))),
      throwsA(isA<AlloyDuplicateRegistrationError>()),
      reason: 'two registrations of one key in one scope is always a mistake',
    );
  });

  test(
    'each test builds its own graph, so nothing leaks between them',
    () async {
      final first = await alloyTestScope(root: const AppScope());
      final second = await alloyTestScope(root: const AppScope());

      expect(
        identical(first.get<Greeter>(), second.get<Greeter>()),
        isFalse,
        reason: 'there is no global container to share state through',
      );
    },
  );
}
