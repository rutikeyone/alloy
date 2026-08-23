import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_generator/alloy_generator.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('generic registrations', () {
    test('two instantiations of one type do not collide', () {
      final source = generate([
        declare(
          'UserRepository',
          exposeAs: ref('Repository', of: [ref('User')]),
        ),
        declare(
          'OrderRepository',
          exposeAs: ref('Repository', of: [ref('Order')]),
        ),
      ]);

      expect(registrationsOf(source), hasLength(2));
      expect(source, contains('Repository<_i'));
    });

    test('a duplicate of the same instantiation is still rejected', () {
      expect(
        () => generate([
          declare('FastUsers', exposeAs: ref('Repository', of: [ref('User')])),
          declare('SlowUsers', exposeAs: ref('Repository', of: [ref('User')])),
        ]),
        throwsA(isA<AlloyGenerationError>()),
      );
    });

    test('instantiations are separate nodes in the dependency graph', () {
      final source = generate([
        declare(
          'Catalog',
          constructor: [
            AlloyInjectedProperty(
              field: 'users',
              type: ref('Repository', of: [ref('User')]),
            ),
          ],
        ),
        declare(
          'UserRepository',
          exposeAs: ref('Repository', of: [ref('User')]),
        ),
        declare(
          'OrderRepository',
          exposeAs: ref('Repository', of: [ref('Order')]),
          constructor: [
            AlloyInjectedProperty(field: 'catalog', type: ref('Catalog')),
          ],
        ),
      ]);

      expect(registrationsOf(source), hasLength(3));
    });
  });

  group('nullable dependencies', () {
    test(
      'a nullable injected field resolves the non-nullable registration',
      () {
        final source = const InjectionMixinEmitter().emit(
          declare(
            'Report',
            properties: [
              AlloyInjectedProperty(
                field: '_clock',
                type: ref('Clock', isNullable: true),
              ),
            ],
          ),
        );

        expect(source, contains('resolver.get<Clock>()'));
        expect(source, isNot(contains('Clock?')));
      },
    );
  });
}
