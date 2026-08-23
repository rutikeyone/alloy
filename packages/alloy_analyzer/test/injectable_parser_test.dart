import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

Future<ClassElement> classNamed(String name, String source) async {
  final library = await resolveSource(
    '''
library test_input;

import 'package:alloy_annotations/alloy_annotations.dart';

$source
''',
    (resolver) async => (await resolver.findLibraryByName('test_input'))!,
    // The input has to live in a package that depends on alloy_annotations,
    // and the real sources have to be readable — otherwise the annotations
    // resolve to null and every matcher silently says "not annotated".
    inputId: AssetId('alloy_analyzer', 'lib/_test_input.dart'),
    readAllSourcesFromFilesystem: true,
  );
  return library.classes.firstWhere((clazz) => clazz.name == name);
}

void main() {
  const parser = AlloyInjectableParser();

  test('a class with type parameters is rejected', () async {
    final clazz = await classNamed('Cache', '''
@alloyInject
class Cache<T> {
  Cache();
}
''');

    expect(
      () => parser.parseClass(clazz),
      throwsA(
        isA<AlloyParseError>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('type parameters <T>'),
            contains('no single instantiation'),
          ),
        ),
      ),
    );
  });

  test('a generic dependency keeps its type arguments', () async {
    final clazz = await classNamed('Catalog', '''
abstract interface class Repository<T> {}

class User {}

@alloyInject
class Catalog {
  Catalog(this.users);
  final Repository<User> users;
}
''');

    final parsed = parser.parseClass(clazz);
    final dependency = parsed.constructorParameters.single.type;

    expect(dependency.name, 'Repository');
    expect(dependency.typeArguments.single.name, 'User');
    expect(dependency.toString(), 'Repository<User>');
  });
}
