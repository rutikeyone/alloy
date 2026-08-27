import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  setUp(resetLogs);

  group('debugKindOf', () {
    test('names every kind of registration', () {
      final scope = alloyTestRoot()
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
      expect(alloyTestRoot().debugKindOf(const AlloyKey(Logger)), isNull);
    });

    test('answers through ancestors, like get does', () {
      final root = alloyTestRoot()
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(
        root.push('child').debugKindOf(const AlloyKey(Logger)),
        Kind.lazySingleton,
      );
    });
  });

  group('debugResolve', () {
    test('builds the same instance the typed get would', () {
      final scope = alloyTestRoot()
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(
        scope.debugResolve(const AlloyKey(Logger)),
        same(scope.get<Logger>()),
      );
    });

    test('is null for a key nothing registers', () {
      expect(alloyTestRoot().debugResolve(const AlloyKey(Logger)), isNull);
    });

    test('throws what get throws for an async singleton before init', () {
      final scope = alloyTestRoot()
        ..registerAsyncSingleton<SlowService>(const SlowFactory('db', 0));

      expect(
        () => scope.debugResolve(const AlloyKey(SlowService)),
        throwsA(isA<AlloyNotReadyError>()),
      );
    });

    test('throws for a parameterized registration', () {
      final scope = alloyTestRoot()
        ..registerParamFactory<PropertyTarget, String>(
          const TargetByNameFactory(),
        );

      expect(
        () => scope.debugResolve(const AlloyKey(PropertyTarget)),
        throwsA(isA<AlloyError>()),
      );
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
