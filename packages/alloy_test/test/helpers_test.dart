import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

import 'support.dart';

class _AppScope implements AlloyScopeBuilder {
  const _AppScope();

  @override
  void build(AlloyScope scope) {
    scope
      ..registerLazySingleton<Clock>(const ValueFactory(Clock()))
      ..registerLazySingleton<Api>(FnFactory((r) => Api(r.get<Clock>())));
  }
}

void main() {
  group('scopes', () {
    late AlloyScope leaked;

    test('alloyTestScope starts the graph', () async {
      final scope = await alloyTestScope(
        root: const _AppScope(),
        rootName: 'app',
      );
      leaked = scope;

      expect(scope.name, 'app');
      expect(scope.get<Api>().clock, isA<Clock>());
    });

    test('and disposed it when the previous test ended', () {
      expect(leaked.state, AlloyScopeState.disposed);
    });

    // Ticket carries a field on purpose: a const class is canonicalised, so
    // two `const Clock()` values are the same object and the assertion would
    // pass for the wrong reason.
    test('pushForTest shadows without touching the parent', () {
      final root = alloyTestRoot()
        ..registerLazySingleton<Ticket>(FnFactory((_) => Ticket('root')));
      final child = root.pushForTest()
        ..registerSingleton<Ticket>(Ticket('override'));

      expect(child.get<Ticket>().id, 'override');
      expect(root.get<Ticket>().id, 'root');
    });
  });

  group('ownerOf', () {
    test('names the scope an override would have to beat', () {
      final root = alloyTestRoot(name: 'app')
        ..registerLazySingleton<Clock>(const ValueFactory(Clock()))
        ..registerLazySingleton<Api>(FnFactory((r) => Api(r.get<Clock>())));
      final child = root.pushForTest()..registerSingleton<Clock>(const Clock());

      expect(
        child.ownerOf<Clock>(),
        same(child),
        reason: 'the override is here',
      );
      expect(
        child.ownerOf<Api>(),
        same(root),
        reason: 'Api is owned above, so it will not see the override',
      );
    });

    test('is null for something nothing registers', () {
      expect(alloyTestRoot().ownerOf<Clock>(), isNull);
    });
  });

  group('DisposeRecorder', () {
    test('records teardown order, newest first', () async {
      final recorder = DisposeRecorder();
      final scope = AlloyScope.root()
        ..registerLazySingleton<Disposable>(recorder.factory('first'));
      scope.get<Disposable>();
      scope.adopt(recorder.value('second'));

      await scope.dispose();

      expect(recorder.entries, ['second', 'first']);
    });

    test('its log belongs to the recorder, not to the library', () {
      expect(DisposeRecorder().entries, isEmpty);
      expect(DisposeRecorder().entries, isEmpty);
    });
  });

  group('CapturingObserver', () {
    test('sees the events a graph emits', () async {
      final observer = CapturingObserver();
      final root = AlloyScope.root(name: 'app', observers: [observer]);
      root.push('child');

      expect(observer.saw(AlloyEventKind.scopePushed), isTrue);
      expect(observer.ofKind(AlloyEventKind.scopePushed), hasLength(1));

      await root.dispose();

      expect(observer.kinds, contains(AlloyEventKind.scopeDisposed));
    });
  });

  group('factories', () {
    test('ValueFactory stays lazy, unlike registerSingleton', () {
      const value = Clock();
      final scope = alloyTestRoot()
        ..registerLazySingleton<Clock>(const ValueFactory(value));

      expect(scope.keys, contains(const AlloyKey(Clock)));
      expect(scope.get<Clock>(), same(value));
    });

    test('FnFactory resolves from the scope it is given', () {
      final scope = alloyTestRoot()
        ..registerLazySingleton<Clock>(const ValueFactory(Clock()))
        ..registerFactory<Api>(FnFactory((r) => Api(r.get<Clock>())));

      expect(scope.get<Api>().clock, same(scope.get<Clock>()));
    });
  });
}
