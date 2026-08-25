import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  const parser = AlloyScopeRootParser();

  test('a root that promises nothing provides nothing', () async {
    final clazz = await classNamed('AppScope', '''
@AlloyScopeRoot(name: 'app')
class AppScope {
  const AppScope();
}
''');

    expect(parser.parseClass(clazz).provides, isEmpty);
  });

  test('a bare type is read as an unnamed registration', () async {
    final clazz = await classNamed('AppScope', '''
class SessionManager {}

@AlloyScopeRoot(name: 'app', provides: [SessionManager])
class AppScope {
  const AppScope();
}
''');

    final provided = parser.parseClass(clazz).provides.single;

    expect(provided.type.name, 'SessionManager');
    expect(provided.name, isNull);
  });

  test('AlloyProvided carries the qualifier', () async {
    final clazz = await classNamed('AppScope', '''
class Logger {}

@AlloyScopeRoot(name: 'app', provides: [AlloyProvided(Logger, name: 'audit')])
class AppScope {
  const AppScope();
}
''');

    final provided = parser.parseClass(clazz).provides.single;

    expect(provided.type.name, 'Logger');
    expect(provided.name, 'audit');
  });

  test('type arguments are kept, since they are part of the key', () async {
    final clazz = await classNamed('AppScope', '''
class User {}
class Repository<T> {}

@AlloyScopeRoot(name: 'app', provides: [Repository<User>])
class AppScope {
  const AppScope();
}
''');

    final provided = parser.parseClass(clazz).provides.single;

    expect(provided.type.name, 'Repository');
    expect(provided.type.typeArguments.single.name, 'User');
  });

  test(
    'something that is neither a type nor AlloyProvided is rejected',
    () async {
      final clazz = await classNamed('AppScope', '''
@AlloyScopeRoot(name: 'app', provides: ['SessionManager'])
class AppScope {
  const AppScope();
}
''');

      expect(
        () => parser.parseClass(clazz),
        throwsA(
          isA<AlloyParseError>().having(
            (e) => e.message,
            'message',
            contains('neither a type nor an AlloyProvided'),
          ),
        ),
      );
    },
  );
}
