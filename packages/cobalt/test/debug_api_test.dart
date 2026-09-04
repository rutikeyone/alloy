import 'package:cobalt/cobalt.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  setUp(resetLogs);

  group('debugKindOf', () {
    test('names every kind of registration', () {
      final scope = cobaltTestRoot()
        ..registerSingleton<Greeting>(Greeting('hi'))
        ..registerLazySingleton<Logger>(const LoggerFactory())
        ..registerFactory<ApiClient>(const ApiClientFactory())
        ..registerAsyncSingleton<SlowService>(const SlowFactory('db', 0))
        ..registerParamFactory<PropertyTarget, String>(
          const TargetByNameFactory(),
        );

      expect(scope.debugKindOf(const CobaltKey(Greeting)), Kind.singleton);
      expect(scope.debugKindOf(const CobaltKey(Logger)), Kind.lazySingleton);
      expect(scope.debugKindOf(const CobaltKey(ApiClient)), Kind.transient);
      expect(
        scope.debugKindOf(const CobaltKey(SlowService)),
        Kind.asyncSingleton,
      );
      expect(
        scope.debugKindOf(const CobaltKey(PropertyTarget)),
        Kind.parameterized,
      );
    });

    test('is null for a key nothing registers', () {
      expect(cobaltTestRoot().debugKindOf(const CobaltKey(Logger)), isNull);
    });

    test('answers through ancestors, like get does', () {
      final root = cobaltTestRoot()
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(
        root.push('child').debugKindOf(const CobaltKey(Logger)),
        Kind.lazySingleton,
      );
    });
  });

  group('debugResolve', () {
    test('builds the same instance the typed get would', () {
      final scope = cobaltTestRoot()
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(
        scope.debugResolve(const CobaltKey(Logger)),
        same(scope.get<Logger>()),
      );
    });

    test('is null for a key nothing registers', () {
      expect(cobaltTestRoot().debugResolve(const CobaltKey(Logger)), isNull);
    });

    test('throws what get throws for an async singleton before init', () {
      final scope = cobaltTestRoot()
        ..registerAsyncSingleton<SlowService>(const SlowFactory('db', 0));

      expect(
        () => scope.debugResolve(const CobaltKey(SlowService)),
        throwsA(isA<CobaltNotReadyError>()),
      );
    });

    test('throws for a parameterized registration', () {
      final scope = cobaltTestRoot()
        ..registerParamFactory<PropertyTarget, String>(
          const TargetByNameFactory(),
        );

      expect(
        () => scope.debugResolve(const CobaltKey(PropertyTarget)),
        throwsA(isA<CobaltError>()),
      );
    });
  });
}

typedef Kind = CobaltRegistrationKind;

class TargetByNameFactory
    implements CobaltParamFactory<PropertyTarget, String> {
  const TargetByNameFactory();

  @override
  PropertyTarget create(CobaltResolver resolver, String param) =>
      PropertyTarget();
}
