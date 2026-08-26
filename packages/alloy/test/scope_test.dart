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

    test('a value the factory cannot take names both types', () {
      final scope = AlloyScope.root()
        ..registerParamFactory<Greeting, String>(const GreetingFactory());

      expect(
        () => scope.getWithParam<Greeting, int>(42),
        throwsA(
          isA<AlloyParamTypeError>()
              .having((e) => e.expected, 'expected', String)
              .having((e) => e.actual, 'actual', int)
              .having((e) => e.key, 'key', const AlloyKey(Greeting))
              .having(
                (e) => e.message,
                'message',
                allOf(
                  contains('Greeting'),
                  contains('String'),
                  contains('int'),
                ),
              ),
        ),
      );
    });

    test('the check happens before the factory runs', () {
      final scope = AlloyScope.root()
        ..registerParamFactory<Greeting, String>(const GreetingFactory());

      expect(
        () => scope.getWithParam<Greeting, int>(42),
        throwsA(isA<AlloyError>()),
        reason: 'a TypeError from inside the factory names nothing useful',
      );
      expect(scope.getWithParam<Greeting, String>('ada').text, 'hi ada');
    });

    /// A type test, not a comparison of `Type`s: a factory registered for a
    /// supertype should take a subtype, exactly as its body would.
    test('a subtype of the registered parameter is accepted', () {
      final scope = AlloyScope.root()
        ..registerParamFactory<Greeting, Object>(const AnyGreetingFactory());

      expect(scope.getWithParam<Greeting, Object>('ada').text, 'hi ada');
      expect(scope.getWithParam<Greeting, Object>(7).text, 'hi 7');
    });

    test('a named parameterized registration is checked too', () {
      final scope = AlloyScope.root()
        ..registerParamFactory<Greeting, String>(
          const GreetingFactory(),
          name: 'formal',
        );

      expect(
        () => scope.getWithParam<Greeting, int>(1, name: 'formal'),
        throwsA(
          isA<AlloyParamTypeError>().having(
            (e) => e.key,
            'key',
            const AlloyKey(Greeting, name: 'formal'),
          ),
        ),
      );
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
