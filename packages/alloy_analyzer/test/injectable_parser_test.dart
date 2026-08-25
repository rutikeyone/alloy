import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:test/test.dart';

import 'support.dart';

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
