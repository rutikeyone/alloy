import 'package:alloy/alloy.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  setUp(resetLogs);

  group('getOrNull', () {
    test('returns the instance when something is registered', () {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(scope.getOrNull<Logger>(), same(scope.get<Logger>()));
    });

    test('returns null instead of throwing when nothing is', () {
      expect(AlloyScope.root().getOrNull<Logger>(), isNull);
    });

    test('a name that nothing registers reads as absent', () {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(scope.getOrNull<Logger>(name: 'audit'), isNull);
      expect(scope.getOrNull<Logger>(), isNotNull);
    });

    test('resolves through ancestors like get does', () {
      final root = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());
      final child = root.push('child');

      expect(child.getOrNull<Logger>(), same(root.get<Logger>()));
    });

    test('an async singleton asked for too early still throws', () async {
      final scope = AlloyScope.root()
        ..registerAsyncSingleton<SlowService>(const SlowFactory('db', 5));

      expect(
        () => scope.getOrNull<SlowService>(),
        throwsA(isA<AlloyNotReadyError>()),
        reason: 'registered but not ready is not the same fact as absent',
      );

      await scope.init();
      expect(scope.getOrNull<SlowService>(), isNotNull);
    });

    test('a parameterized factory still throws', () {
      final scope = AlloyScope.root()
        ..registerParamFactory<Greeting, String>(const GreetingFactory());

      expect(() => scope.getOrNull<Greeting>(), throwsA(isA<AlloyError>()));
    });
  });

  group('keys', () {
    test('lists what the scope registers, in registration order', () {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory())
        ..registerLazySingleton<ApiClient>(const ApiClientFactory());

      expect(scope.keys.map((key) => key.type).toList(), [Logger, ApiClient]);
    });

    test('keeps named registrations apart from unnamed ones', () {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory())
        ..registerLazySingleton<Logger>(const LoggerFactory(), name: 'audit');

      expect(scope.keys, hasLength(2));
      expect(scope.keys, contains(const AlloyKey(Logger, name: 'audit')));
    });

    test('lists a lazy singleton nobody resolved', () {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(scope.keys, contains(const AlloyKey(Logger)));
      expect(disposeLog, isEmpty, reason: 'nothing was built');
    });

    test('does not list what only adopt owns', () {
      final scope = AlloyScope.root()..adopt(Recorder('adopted'));

      expect(scope.keys, isEmpty);
    });

    test('is empty after dispose rather than a tombstone', () async {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());
      await scope.dispose();

      expect(scope.keys, isEmpty);
    });

    test('is unmodifiable', () {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(
        () => scope.keys.add(const AlloyKey(ApiClient)),
        throwsUnsupportedError,
      );
    });
  });

  group('visibleKeys', () {
    test('includes what ancestors register', () {
      final root = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());
      final child = root.push('child')
        ..registerLazySingleton<ApiClient>(const ApiClientFactory());

      expect(child.visibleKeys.keys.map((key) => key.type), [
        ApiClient,
        Logger,
      ]);
    });

    test('names the scope that owns each key', () {
      final root = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());
      final child = root.push('child')
        ..registerLazySingleton<ApiClient>(const ApiClientFactory());

      expect(child.visibleKeys[const AlloyKey(Logger)], same(root));
      expect(child.visibleKeys[const AlloyKey(ApiClient)], same(child));
    });

    test('a child shadowing an ancestor owns the key', () {
      final root = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());
      final child = root.push('child')
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(child.visibleKeys[const AlloyKey(Logger)], same(child));
      expect(root.visibleKeys[const AlloyKey(Logger)], same(root));
    });
  });

  group('root and the tree', () {
    test('root climbs to the outermost scope', () {
      final root = AlloyScope.root(name: 'app');
      final grandchild = root.push('session').push('flow');

      expect(grandchild.root, same(root));
      expect(root.root, same(root));
    });

    test('describeTree indents children under their parent', () {
      final root = AlloyScope.root(name: 'app')
        ..registerLazySingleton<Logger>(const LoggerFactory());
      root.push('session');

      final lines = root.debugDescribeTree().split('\n');

      expect(lines, hasLength(2));
      expect(lines.first, startsWith('app  [open]  1 registration'));
      expect(lines.last, startsWith('  session'));
    });
  });

  test('diagnostics still answer on a disposed scope', () async {
    final root = AlloyScope.root(name: 'app');
    final child = root.push('child');
    await child.dispose();

    expect(child.state, AlloyScopeState.disposed);
    expect(child.keys, isEmpty);
    expect(child.debugDescribeTree(), contains('disposed'));
    expect(child.root, same(root));
  });
}
