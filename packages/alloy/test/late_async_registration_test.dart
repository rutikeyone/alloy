import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

class Late {}

class Plain {}

void main() {
  group('an async registration added too late', () {
    test(
      'is refused once init() has run, not accepted and left unbuildable',
      () async {
        final scope = alloyTestRoot(name: 'app');
        await scope.init();

        expect(
          () => scope.registerAsyncSingleton<Late>(
            AsyncFnFactory((_) async => Late()),
          ),
          throwsA(
            isA<AlloyScopeStateError>().having(
              (error) => error.toString(),
              'message',
              allOf(
                contains('Late'),
                contains('would never be built'),
                contains('push a child scope'),
              ),
            ),
          ),
        );
      },
    );

    /// The same hole from the other side: init() takes its list when it
    /// starts, so a registration made while it runs is just as unbuildable.
    test('is refused while init() is still running', () async {
      final scope = alloyTestRoot(name: 'app')
        ..registerAsyncSingleton<Plain>(
          AsyncFnFactory((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return Plain();
          }),
        );

      final running = scope.init();
      expect(
        () => scope.registerAsyncSingleton<Late>(
          AsyncFnFactory((_) async => Late()),
        ),
        throwsA(isA<AlloyScopeStateError>()),
      );
      await running;
    });

    test('a sync registration after init() is still fine', () async {
      final scope = alloyTestRoot(name: 'app');
      await scope.init();

      scope.registerLazySingleton<Plain>(FnFactory((_) => Plain()));

      expect(scope.get<Plain>(), isA<Plain>());
    });

    /// The way out the message names.
    test('a child scope initialized on its own builds it', () async {
      final root = alloyTestRoot(name: 'app');
      await root.init();

      final child = root.push('session')
        ..registerAsyncSingleton<Late>(AsyncFnFactory((_) async => Late()));
      await child.init();

      expect(child.get<Late>(), isA<Late>());
    });
  });
}
