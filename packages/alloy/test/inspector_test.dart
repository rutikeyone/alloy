import 'dart:convert';

import 'package:alloy/alloy.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  setUp(() {
    resetLogs();
    AlloyScopeRegistry.clear();
  });

  group('debugKindOf', () {
    test('names every kind of registration', () {
      final scope = AlloyScope.root()
        ..registerSingleton<Greeting>(Greeting('hi'))
        ..registerLazySingleton<Logger>(const LoggerFactory())
        ..registerFactory<ApiClient>(const ApiClientFactory())
        ..registerAsyncSingleton<SlowService>(const SlowFactory('db', 0))
        ..registerParamFactory<PropertyTarget, String>(
          const TargetByNameFactory(),
        );

      expect(scope.debugKindOf(const AlloyKey(Greeting)), Kind.singleton);
      expect(scope.debugKindOf(const AlloyKey(Logger)), Kind.lazySingleton);
      expect(scope.debugKindOf(const AlloyKey(ApiClient)), Kind.transient);
      expect(
        scope.debugKindOf(const AlloyKey(SlowService)),
        Kind.asyncSingleton,
      );
      expect(
        scope.debugKindOf(const AlloyKey(PropertyTarget)),
        Kind.parameterized,
      );
    });

    test('is null for a key nothing registers', () {
      expect(AlloyScope.root().debugKindOf(const AlloyKey(Logger)), isNull);
    });

    test('answers through ancestors, like get does', () {
      final root = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(
        root.push('child').debugKindOf(const AlloyKey(Logger)),
        Kind.lazySingleton,
      );
    });
  });

  group('debugResolve', () {
    test('builds the same instance the typed get would', () {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(
        scope.debugResolve(const AlloyKey(Logger)),
        same(scope.get<Logger>()),
      );
    });

    test('is null for a key nothing registers', () {
      expect(AlloyScope.root().debugResolve(const AlloyKey(Logger)), isNull);
    });

    test('throws what get throws for an async singleton before init', () {
      final scope = AlloyScope.root()
        ..registerAsyncSingleton<SlowService>(const SlowFactory('db', 0));

      expect(
        () => scope.debugResolve(const AlloyKey(SlowService)),
        throwsA(isA<AlloyNotReadyError>()),
      );
    });

    test('throws for a parameterized registration', () {
      final scope = AlloyScope.root()
        ..registerParamFactory<PropertyTarget, String>(
          const TargetByNameFactory(),
        );

      expect(
        () => scope.debugResolve(const AlloyKey(PropertyTarget)),
        throwsA(isA<AlloyError>()),
      );
    });
  });

  group('the live registry', () {
    test('records a root when it is created', () {
      final root = AlloyScope.root(name: 'app');

      expect(AlloyScopeRegistry.roots, [same(root)]);
    });

    test('forgets it the moment it is disposed, not when collected', () async {
      final root = AlloyScope.root(name: 'app');
      await root.dispose();

      expect(
        AlloyScopeRegistry.roots,
        isEmpty,
        reason: 'nothing here may wait on the garbage collector',
      );
    });

    test('does not record a pushed child', () {
      final root = AlloyScope.root(name: 'app');
      root.push('child');

      expect(AlloyScopeRegistry.roots.map((s) => s.name), ['app']);
    });
  });

  group('the reported tree', () {
    test('carries the shape a tool needs', () {
      final root = AlloyScope.root(name: 'app')
        ..registerLazySingleton<Logger>(const LoggerFactory());
      root
          .push('session')
          .registerLazySingleton<ApiClient>(const ApiClientFactory());

      final tree = AlloyInspector.describe(root);

      expect(tree['name'], 'app');
      expect(tree['depth'], 0);
      expect(tree['state'], 'open');
      expect(tree['keys'], ['Logger']);

      final child = (tree['children']! as List).single as Map<String, Object?>;
      expect(child['name'], 'session');
      expect(child['depth'], 1);
      expect(child['keys'], ['ApiClient']);
    });

    test('names the owner of an inherited key', () {
      final root = AlloyScope.root(name: 'app')
        ..registerLazySingleton<Logger>(const LoggerFactory());
      final child = root.push('session');

      final inherited = (AlloyInspector.describe(child)['inherited']! as List)
          .cast<Map<String, Object?>>();

      expect(inherited, [
        {'key': 'Logger', 'owner': 'app'},
      ]);
    });

    test('survives a round trip through JSON', () {
      final root = AlloyScope.root(name: 'app')
        ..registerLazySingleton<Logger>(const LoggerFactory());

      final decoded = jsonDecode(
        jsonEncode(AlloyInspector.describe(root)),
      ) as Map<String, Object?>;

      expect(decoded['name'], 'app');
      expect(decoded['keys'], ['Logger']);
    });
  });
}

typedef Kind = AlloyRegistrationKind;

class TargetByNameFactory implements AlloyParamFactory<PropertyTarget, String> {
  const TargetByNameFactory();

  @override
  PropertyTarget create(AlloyResolver resolver, String param) =>
      PropertyTarget();
}
