import 'package:alloy/alloy.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  setUp(resetLogs);

  group('registration and resolution', () {
    test('lazy singleton returns the same instance', () {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(scope.get<Logger>(), same(scope.get<Logger>()));
    });

    test('factory returns a new instance every time', () {
      final scope = AlloyScope.root()
        ..registerFactory<Logger>(const LoggerFactory());

      expect(scope.get<Logger>(), isNot(same(scope.get<Logger>())));
    });

    test('missing registration names the key and the scope', () {
      final scope = AlloyScope.root(name: 'app');

      expect(
        () => scope.get<Logger>(),
        throwsA(isA<AlloyNotRegisteredError>()),
      );
    });

    test('duplicate registration in one scope throws', () {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(
        () => scope.registerLazySingleton<Logger>(const LoggerFactory()),
        throwsA(isA<AlloyDuplicateRegistrationError>()),
      );
    });

    test('named registrations coexist with unnamed ones', () {
      final primary = Logger();
      final backup = Logger();
      final scope = AlloyScope.root()
        ..registerSingleton<Logger>(primary)
        ..registerSingleton<Logger>(backup, name: 'backup');

      expect(scope.get<Logger>(), same(primary));
      expect(scope.get<Logger>(name: 'backup'), same(backup));
    });

    test('parameterized factory receives the argument', () {
      final scope = AlloyScope.root()
        ..registerParamFactory<Greeting, String>(const GreetingFactory());

      expect(scope.getWithParam<Greeting, String>('alloy').text, 'hi alloy');
    });

    test('parameterized registration rejects plain get', () {
      final scope = AlloyScope.root()
        ..registerParamFactory<Greeting, String>(const GreetingFactory());

      expect(() => scope.get<Greeting>(), throwsA(isA<AlloyError>()));
    });
  });

  group('hierarchy', () {
    test('child resolves through the parent', () {
      final root = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());
      final child = root.push('session');

      expect(child.get<Logger>(), same(root.get<Logger>()));
    });

    test('child shadows the parent without touching it', () {
      final rootLogger = Logger();
      final childLogger = Logger();
      final root = AlloyScope.root()..registerSingleton<Logger>(rootLogger);
      final child = root.push('session')
        ..registerSingleton<Logger>(childLogger);

      expect(child.get<Logger>(), same(childLogger));
      expect(root.get<Logger>(), same(rootLogger));
    });

    test('dependencies resolve in the scope that owns them', () {
      final root = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory());
      final child = root.push('session')
        ..registerLazySingleton<ApiClient>(const ApiClientFactory());

      expect(child.get<ApiClient>().logger, same(root.get<Logger>()));
    });

    test('two sibling scopes are independent subtrees', () {
      final root = AlloyScope.root();
      final a = root.push('a')
        ..registerLazySingleton<Logger>(const LoggerFactory());
      final b = root.push('b')
        ..registerLazySingleton<Logger>(const LoggerFactory());

      expect(a.get<Logger>(), isNot(same(b.get<Logger>())));
      expect(root.children, hasLength(2));
    });
  });

  group('multi-injection', () {
    test('getAll collects every registration of a type', () {
      final scope = AlloyScope.root()
        ..registerSingleton<Logger>(Logger())
        ..registerSingleton<Logger>(Logger(), name: 'second')
        ..registerSingleton<Logger>(Logger(), name: 'third');

      expect(scope.getAll<Logger>(), hasLength(3));
    });

    test('getAll walks ancestors and lets the child shadow', () {
      final rootDefault = Logger();
      final rootExtra = Logger();
      final childDefault = Logger();

      final root = AlloyScope.root()
        ..registerSingleton<Logger>(rootDefault)
        ..registerSingleton<Logger>(rootExtra, name: 'extra');
      final child = root.push('session')
        ..registerSingleton<Logger>(childDefault);

      expect(child.getAll<Logger>(), [childDefault, rootExtra]);
    });
  });

  group('property injection', () {
    test('onInject runs immediately after construction', () {
      final scope = AlloyScope.root()
        ..registerLazySingleton<Logger>(const LoggerFactory())
        ..registerFactory<PropertyTarget>(const PropertyTargetFactory());

      final injected = scope.get<PropertyTarget>();

      expect(injected.injected, isTrue);
      expect(injected.logger, same(scope.get<Logger>()));
    });
  });
}
