import 'package:cobalt_analyzer/cobalt_analyzer.dart';
import 'package:cobalt_generator/src/emitters/injection_mixin_emitter.dart';
import 'package:cobalt_generator/src/errors/cobalt_generation_error.dart';
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
        throwsA(isA<CobaltGenerationError>()),
      );
    });

    test('instantiations are separate nodes in the dependency graph', () {
      final source = generate([
        declare(
          'Catalog',
          constructor: [
            CobaltInjectedProperty(
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
            CobaltInjectedProperty(field: 'catalog', type: ref('Catalog')),
          ],
        ),
      ]);

      expect(registrationsOf(source), hasLength(3));
    });
  });

  group('nullable dependencies', () {
    String mixinFor({required bool isNullable}) =>
        const InjectionMixinEmitter().emit(
          declare(
            'Report',
            properties: [
              CobaltInjectedProperty(
                field: '_clock',
                type: ref('Clock', isNullable: isNullable),
              ),
            ],
          ),
        );

    test('a nullable injected field reads through getOrNull', () {
      final source = mixinFor(isNullable: true);

      expect(source, contains('resolver.getOrNull<Clock>()'));
    });

    test('its setter accepts null, or the assignment would not compile', () {
      final source = mixinFor(isNullable: true);

      expect(source, contains('set _clock(Clock? value)'));
    });

    test('the type argument stays non-nullable, since T extends Object', () {
      final source = mixinFor(isNullable: true);

      expect(source, isNot(contains('<Clock?>')));
    });

    test('a required field is untouched', () {
      final source = mixinFor(isNullable: false);

      expect(source, contains('resolver.get<Clock>()'));
      expect(source, contains('set _clock(Clock value)'));
      expect(source, isNot(contains('getOrNull')));
    });
  });
}
