import 'package:cobalt_analyzer/cobalt_analyzer.dart';
import 'package:cobalt_generator/src/errors/cobalt_generation_error.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('@CobaltInit emission', () {
    test('emits an async factory that awaits init()', () {
      final source = generate([declare('Database', isAsyncInit: true)]);

      expect(source, contains('CobaltAsyncFactory<_i'));
      expect(source, contains('Future<_i'));
      expect(source, contains('await instance.init();'));
      expect(source, contains('return instance;'));
    });

    test('registers as an async singleton', () {
      final source = generate([declare('Database', isAsyncInit: true)]);

      expect(
        registrationsOf(source).single,
        startsWith('scope.registerAsyncSingleton<'),
      );
    });

    test('dependsOn becomes a const set of CobaltKey', () {
      final source = generate([
        declare('Database', isAsyncInit: true),
        declare('Cache', isAsyncInit: true, dependsOn: [ref('Database')]),
      ]);

      expect(source, contains('dependsOn: {'));
      expect(source, contains('const _i'));
      expect(source, contains('.CobaltKey(_i'));
      expect(source, contains('.Database)'));
    });

    test('dependsOn is omitted when empty', () {
      final source = generate([declare('Database', isAsyncInit: true)]);

      expect(source, isNot(contains('dependsOn')));
    });

    test('dependsOn orders registration, not just runtime waiting', () {
      final source = generate([
        declare('Cache', isAsyncInit: true, dependsOn: [ref('Database')]),
        declare('Database', isAsyncInit: true),
      ]);

      final order = registrationsOf(source);
      expect(order.first, contains('Database'));
      expect(order.last, contains('Cache'));
    });

    test('a cycle through dependsOn is rejected', () {
      expect(
        () => generate([
          declare('A', isAsyncInit: true, dependsOn: [ref('B')]),
          declare('B', isAsyncInit: true, dependsOn: [ref('A')]),
        ]),
        throwsA(isA<CobaltCycleError>()),
      );
    });

    test('waiting for a registration that is not async fails the build', () {
      expect(
        () => generate([
          declare('Logger'),
          declare('Database', isAsyncInit: true, dependsOn: [ref('Logger')]),
        ]),
        throwsA(
          isA<CobaltGenerationError>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('Database waits for Logger'),
              contains('only wait for an async registration'),
            ),
          ),
        ),
      );
    });

    test('waiting for an async registration is fine', () {
      final source = generate([
        declare('Logger', isAsyncInit: true),
        declare('Database', isAsyncInit: true, dependsOn: [ref('Logger')]),
      ]);

      expect(source, contains('dependsOn: {'));
    });

    test('sync and async registrations coexist in one container', () {
      // The dependency is a constructor parameter, not a dependsOn. Waiting
      // for a plain registration is now a build failure, and this test never
      // meant to assert one — it is about the two kinds sitting in one
      // container, ordered by what actually depends on what.
      final source = generate([
        declare('Logger'),
        declare('Database', isAsyncInit: true, constructor: [dep('Logger')]),
      ]);

      final order = registrationsOf(source);
      expect(order.first, startsWith('scope.registerLazySingleton<'));
      expect(order.last, startsWith('scope.registerAsyncSingleton<'));
    });
  });
}
