import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('@AlloyInit emission', () {
    test('emits an async factory that awaits init()', () {
      final source = generate([declare('Database', isAsyncInit: true)]);

      expect(source, contains('AlloyAsyncFactory<_i'));
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

    test('dependsOn becomes a const set of AlloyKey', () {
      final source = generate([
        declare('Database', isAsyncInit: true),
        declare('Cache', isAsyncInit: true, dependsOn: [ref('Database')]),
      ]);

      expect(source, contains('dependsOn: {'));
      expect(source, contains('const _i'));
      expect(source, contains('.AlloyKey(_i'));
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
        throwsA(isA<AlloyCycleError>()),
      );
    });

    test('sync and async registrations coexist in one container', () {
      final source = generate([
        declare('Logger'),
        declare('Database', isAsyncInit: true, dependsOn: [ref('Logger')]),
      ]);

      final order = registrationsOf(source);
      expect(order.first, startsWith('scope.registerLazySingleton<'));
      expect(order.last, startsWith('scope.registerAsyncSingleton<'));
    });
  });
}
