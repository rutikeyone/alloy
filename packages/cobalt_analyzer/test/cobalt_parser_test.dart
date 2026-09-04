import 'package:cobalt_analyzer/cobalt_analyzer.dart';
import 'package:test/test.dart';

import 'support.dart';

/// The one parser that reads a whole library rather than a class, and the one
/// this package's own suite never called: it was reached only through the
/// generator's tests and the compat stand, which left it hostage to somebody
/// else's coverage.
void main() {
  const parser = CobaltParser();

  test('collects each kind of declaration from one library', () async {
    final library = await libraryFrom('''
@CobaltScopeRoot(name: 'app')
class AppScope {
  const AppScope();
}

@cobaltBootstrap
class BindPlatform {
  BindPlatform();
  void run() {}
}

@cobaltInject
class Logger {
  Logger();
}

class Channel {}

@cobaltModule
class PlatformModule {
  const PlatformModule();

  @cobaltInject
  Channel channel() => Channel();
}
''');

    final declarations = parser.parseLibrary(library);

    expect(declarations.scopeRoots.single.name, 'app');
    expect(declarations.bootstrapSteps.single.type.name, 'BindPlatform');
    expect(
      declarations.injectables.map((each) => each.type.name),
      ['Logger', 'Channel'],
      reason:
          'classes first, then what modules provide — a module is the one '
          'declaration that yields several',
    );
    expect(declarations.injectables.last.provider?.member, 'channel');
  });

  test('a library that declares nothing is empty, not null', () async {
    final library = await libraryFrom('''
class Plain {
  Plain();
}
''');

    final declarations = parser.parseLibrary(library);

    expect(declarations.isEmpty, isTrue);
    expect(declarations.injectables, isEmpty);
    expect(declarations.bootstrapSteps, isEmpty);
    expect(declarations.scopeRoots, isEmpty);
  });

  test('one bad declaration fails the whole library', () async {
    final library = await libraryFrom('''
@cobaltInject
class Fine {
  Fine();
}

@cobaltInject
abstract class Store {}
''');

    expect(
      () => parser.parseLibrary(library),
      throwsA(
        isA<CobaltParseError>().having(
          (error) => error.message,
          'message',
          allOf(contains('Store'), contains('abstract')),
        ),
      ),
      reason:
          'partial IR would make the container reject a graph that is only '
          'half read',
    );
  });
}
