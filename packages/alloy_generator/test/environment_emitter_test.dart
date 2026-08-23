import 'package:alloy_generator/alloy_generator.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('a graph without environments', () {
    test('keeps the const root scope and the plain start function', () {
      final source = generate(
        [declare('Logger')],
        scopeRoots: [scopeRoot('AppScope', name: 'app')],
      );

      expect(source, contains(r'const $AlloyRootScope();'));
      expect(source, contains(r'$startAlloy() =>'));
      expect(source, isNot(contains('environment')));
    });
  });

  group('a graph with environments', () {
    String sourceOf() => generate([
      declare('Logger'),
      declare(
        'SqlNotes',
        exposeAs: ref('Notes'),
        environments: {'prod', 'stage'},
      ),
      declare('FakeNotes', exposeAs: ref('Notes'), environments: {'dev'}),
    ]);

    test('takes the chosen environment through the whole chain', () {
      final source = sourceOf();

      expect(
        source,
        matches(
          RegExp(
            r'const \$AlloyRootScope\(\{\s*this\.environment\s*=\s*'
            r'_i\d+\.AlloyEnvironment\.defaultEnvironment,?\s*\}\)',
          ),
        ),
      );
      expect(
        source,
        matches(RegExp(r'final _i\d+\.AlloyEnvironment environment;')),
      );
      expect(
        source,
        matches(
          RegExp(
            r'\$startAlloy\(\{\s*_i\d+\.AlloyEnvironment environment\s*=\s*'
            r'_i\d+\.AlloyEnvironment\.defaultEnvironment,?\s*\}\)',
          ),
        ),
        reason: 'environments are opt-in, so startup still works without one',
      );
      expect(
        source,
        contains(r'root: $AlloyRootScope(environment: environment),'),
      );
    });

    test('guards only the restricted registrations', () {
      final source = sourceOf();

      expect(source, contains("environment.matches(const <String>{'dev'})"));
      expect(
        source,
        contains("environment.matches(const <String>{'prod', 'stage'})"),
      );
      expect(
        registrationsOf(source).where((l) => l.contains('.Logger>')),
        hasLength(1),
        reason: 'an unrestricted registration stays unguarded',
      );
    });

    test('the same graph emits the same source twice', () {
      expect(sourceOf(), equals(sourceOf()));
    });
  });

  group('bootstrap steps', () {
    test('stay a getter while no step names an environment', () {
      final source = generate(
        [declare('Logger')],
        bootstrap: [step('BindPlatform')],
      );

      expect(source, contains(r'get $alloyBootstrap'));
      expect(source, contains(r'bootstrap: $alloyBootstrap,'));
    });

    test('become a function of the environment once one does', () {
      final source = generate(
        [declare('Logger')],
        bootstrap: [
          step('BindPlatform'),
          step('ReportCrashes', order: 1, environments: {'prod'}),
        ],
      );

      expect(source, isNot(contains(r'get $alloyBootstrap')));
      expect(
        source,
        matches(
          RegExp(
            r'\$alloyBootstrap\(\s*_i\d+\.AlloyEnvironment environment,?\s*\)',
          ),
        ),
      );
      expect(source, contains(r'bootstrap: $alloyBootstrap(environment),'));
      expect(
        source,
        contains("if (environment.matches(const <String>{'prod'}))"),
      );
    });
  });

  group('conflicting registrations', () {
    test('two unrestricted registrations of one type are rejected', () {
      expect(
        () => generate([
          declare('SqlNotes', exposeAs: ref('Notes')),
          declare('FakeNotes', exposeAs: ref('Notes')),
        ]),
        throwsA(
          isA<AlloyGenerationError>().having(
            (e) => e.message,
            'message',
            allOf(contains('SqlNotes'), contains('FakeNotes')),
          ),
        ),
      );
    });

    test('overlapping environments are rejected and name the overlap', () {
      expect(
        () => generate([
          declare(
            'SqlNotes',
            exposeAs: ref('Notes'),
            environments: {'prod', 'stage'},
          ),
          declare(
            'FakeNotes',
            exposeAs: ref('Notes'),
            environments: {'dev', 'stage'},
          ),
        ]),
        throwsA(
          isA<AlloyGenerationError>().having(
            (e) => e.message,
            'message',
            contains('in stage'),
          ),
        ),
      );
    });

    test('an unrestricted registration conflicts with a restricted one', () {
      expect(
        () => generate([
          declare('SqlNotes', exposeAs: ref('Notes')),
          declare('FakeNotes', exposeAs: ref('Notes'), environments: {'dev'}),
        ]),
        throwsA(
          isA<AlloyGenerationError>().having(
            (e) => e.message,
            'message',
            contains('names no environment'),
          ),
        ),
      );
    });

    test('disjoint environments are allowed', () {
      expect(
        () => generate([
          declare('SqlNotes', exposeAs: ref('Notes'), environments: {'prod'}),
          declare('FakeNotes', exposeAs: ref('Notes'), environments: {'dev'}),
        ]),
        returnsNormally,
      );
    });

    test('the same type under different names is not a conflict', () {
      expect(
        () => generate([
          declare('SqlNotes', exposeAs: ref('Notes'), name: 'sql'),
          declare('FakeNotes', exposeAs: ref('Notes'), name: 'fake'),
        ]),
        returnsNormally,
      );
    });
  });
}
