import 'package:alloy/alloy.dart';
import 'package:test/test.dart';

class Late {}

class Plain {}

void main() {
  group('an async registration added too late', () {
    test(
      'is refused once init() has run, not accepted and left unbuildable',
      () async {
        final scope = AlloyScope.root(name: 'app');
        addTearDown(scope.dispose);
        await scope.init();

        expect(
          () =>
              scope.registerAsyncSingleton<Late>(_AsyncFn((_) async => Late())),
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
      final scope = AlloyScope.root(name: 'app')
        ..registerAsyncSingleton<Plain>(
          _AsyncFn((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return Plain();
          }),
        );
      addTearDown(scope.dispose);

      final running = scope.init();
      expect(
        () => scope.registerAsyncSingleton<Late>(_AsyncFn((_) async => Late())),
        throwsA(isA<AlloyScopeStateError>()),
      );
      await running;
    });

    test('a sync registration after init() is still fine', () async {
      final scope = AlloyScope.root(name: 'app');
      addTearDown(scope.dispose);
      await scope.init();

      scope.registerLazySingleton<Plain>(_Fn((_) => Plain()));

      expect(scope.get<Plain>(), isA<Plain>());
    });

    /// The way out the message names.
    test('a child scope initialized on its own builds it', () async {
      final root = AlloyScope.root(name: 'app');
      addTearDown(root.dispose);
      await root.init();

      final child = root.push('session')
        ..registerAsyncSingleton<Late>(_AsyncFn((_) async => Late()));
      await child.init();

      expect(child.get<Late>(), isA<Late>());
    });
  });
}

final class _Fn<T extends Object> implements AlloyFactory<T> {
  const _Fn(this.build);

  final T Function(AlloyResolver resolver) build;

  @override
  T create(AlloyResolver resolver) => build(resolver);
}

final class _AsyncFn<T extends Object> implements AlloyAsyncFactory<T> {
  const _AsyncFn(this.build);

  final Future<T> Function(AlloyResolver resolver) build;

  @override
  Future<T> create(AlloyResolver resolver) => build(resolver);
}
