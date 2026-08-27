import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  const parser = AlloyInjectableParser();
  const modules = AlloyModuleParser();

  group('@AlloyParam on a constructor parameter', () {
    test('is read, and the rest stay dependencies', () async {
      final clazz = await classNamed('NoteEditor', '''
class Repo {}

@alloyInject
class NoteEditor {
  NoteEditor(this.repo, {@alloyParam required this.id});

  final Repo repo;
  final int id;
}
''');

      final parsed = parser.parseClass(clazz);

      expect(parsed.takesCallSiteValues, isTrue);
      expect(parsed.callSiteValues.map((each) => each.field), ['id']);
      expect(
        parsed.constructorParameters.first.isParam,
        isFalse,
        reason: 'the repository still comes from the graph',
      );
    });

    test('records whether the constructor takes it named', () async {
      final clazz = await classNamed('Api', '''
class Logger {}

@alloyInject
class Api {
  Api(this.clock, {required this.logger});

  final int clock;
  final Logger logger;
}
''');

      final parsed = parser.parseClass(clazz);

      expect(parsed.constructorParameters.map((each) => each.isNamed), [
        false,
        true,
      ]);
    });
  });

  group('what @AlloyParam cannot be combined with', () {
    test('an async initializer', () async {
      final clazz = await classNamed('Warmer', '''
@AlloyInit()
class Warmer implements AsyncInitializable {
  Warmer({@alloyParam required this.id});

  final int id;

  @override
  Future<void> init() async {}
}
''');

      expect(
        () => parser.parseClass(clazz),
        throwsA(
          isA<AlloyParseError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Warmer'),
              contains('no asynchronous parameterized factory'),
            ),
          ),
        ),
      );
    });

    test('a singleton lifetime', () async {
      final clazz = await classNamed('Editor', '''
@AlloyInject(lifetime: AlloyLifetime.singleton)
class Editor {
  Editor({@alloyParam required this.id});

  final int id;
}
''');

      expect(
        () => parser.parseClass(clazz),
        throwsA(
          isA<AlloyParseError>().having(
            (error) => error.message,
            'message',
            allOf(contains('Editor'), contains('never retained')),
          ),
        ),
      );
    });

    test('a module member', () async {
      final clazz = await classNamed('PlatformModule', '''
class Channel {}

@alloyModule
class PlatformModule {
  const PlatformModule();

  @alloyInject
  Channel channel(@alloyParam int id) => Channel();
}
''');

      expect(
        () => modules.parseClass(clazz),
        throwsA(
          isA<AlloyParseError>().having(
            (error) => error.message,
            'message',
            contains('a class you did'),
          ),
        ),
      );
    });
  });
}
