import 'package:cobalt_analyzer/cobalt_analyzer.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  const parser = CobaltInjectableParser();
  const modules = CobaltModuleParser();

  group('@CobaltParam on a constructor parameter', () {
    test('is read, and the rest stay dependencies', () async {
      final clazz = await classNamed('NoteEditor', '''
class Repo {}

@cobaltInject
class NoteEditor {
  NoteEditor(this.repo, {@cobaltParam required this.id});

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

@cobaltInject
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

  group('what @CobaltParam cannot be combined with', () {
    test('an async initializer', () async {
      final clazz = await classNamed('Warmer', '''
@CobaltInit()
class Warmer implements AsyncInitializable {
  Warmer({@cobaltParam required this.id});

  final int id;

  @override
  Future<void> init() async {}
}
''');

      expect(
        () => parser.parseClass(clazz),
        throwsA(
          isA<CobaltParseError>().having(
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
@CobaltInject(lifetime: CobaltLifetime.singleton)
class Editor {
  Editor({@cobaltParam required this.id});

  final int id;
}
''');

      expect(
        () => parser.parseClass(clazz),
        throwsA(
          isA<CobaltParseError>().having(
            (error) => error.message,
            'message',
            allOf(contains('Editor'), contains('never retained')),
          ),
        ),
      );
    });

    test('an optional parameter', () async {
      final clazz = await classNamed('Editor', '''
@cobaltInject
class Editor {
  Editor({@cobaltParam this.draft = false});

  final bool draft;
}
''');

      expect(
        () => parser.parseClass(clazz),
        throwsA(
          isA<CobaltParseError>().having(
            (error) => error.message,
            'message',
            allOf(contains('draft'), contains('has no defaults')),
          ),
        ),
        reason:
            'a record carries no defaults, so the one written here would '
            'never be used',
      );
    });

    test('a nullable value is fine, and stays nullable', () async {
      final clazz = await classNamed('Editor', '''
@cobaltInject
class Editor {
  Editor({@cobaltParam required this.title});

  final String? title;
}
''');

      final parsed = parser.parseClass(clazz);

      expect(parsed.callSiteValues.single.type.isNullable, isTrue);
    });

    test('a module member', () async {
      final clazz = await classNamed('PlatformModule', '''
class Channel {}

@cobaltModule
class PlatformModule {
  const PlatformModule();

  @cobaltInject
  Channel channel(@cobaltParam int id) => Channel();
}
''');

      expect(
        () => modules.parseClass(clazz),
        throwsA(
          isA<CobaltParseError>().having(
            (error) => error.message,
            'message',
            contains('a class you did'),
          ),
        ),
      );
    });
  });
}
