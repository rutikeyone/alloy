import 'package:alloy_generator/alloy_generator.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('@AlloyScopeRoot emission', () {
    test('defaults to "root" when nothing is annotated', () {
      final source = generate([declare('Logger')]);

      expect(source, contains(r"const String $alloyRootScopeName = 'root';"));
    });

    test('takes the name from the annotation', () {
      final source = generate(
        [declare('Logger')],
        scopeRoots: [scopeRoot('App', name: 'notes-app')],
      );

      expect(
        source,
        contains(r"const String $alloyRootScopeName = 'notes-app';"),
      );
    });

    test('emits a start function wired to the generated container', () {
      final source = generate([declare('Logger')]);

      expect(source, contains(r'$startAlloy()'));
      expect(source, contains(r'root: const $AlloyRootScope()'));
      expect(source, contains(r'rootName: $alloyRootScopeName'));
    });

    test('passes the bootstrap list only when steps exist', () {
      final withSteps = generate(
        [declare('Logger')],
        bootstrap: [step('BindPlatform')],
      );
      final withoutSteps = generate([declare('Logger')]);

      expect(withSteps, contains(r'bootstrap: $alloyBootstrap'));
      expect(withoutSteps, isNot(contains('bootstrap:')));
    });

    test('two roots in one package is a generation error', () {
      expect(
        () => generate(
          [declare('Logger')],
          scopeRoots: [
            scopeRoot('App'),
            scopeRoot('Other', name: 'other'),
          ],
        ),
        throwsA(
          isA<AlloyGenerationError>().having(
            (e) => e.message,
            'message',
            allOf(contains('App'), contains('Other'), contains('at most one')),
          ),
        ),
      );
    });

    test('no container means no start function', () {
      final source = generate(const [], bootstrap: [step('BindPlatform')]);

      expect(source, isNot(contains(r'$startAlloy')));
      expect(source, isNot(contains(r'$alloyRootScopeName')));
    });
  });
}
