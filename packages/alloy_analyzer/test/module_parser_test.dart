import 'package:alloy_analyzer/alloy_analyzer.dart';
import 'package:alloy_annotations/alloy_annotations.dart';
import 'package:test/test.dart';

import 'support.dart';

Matcher rejects(Object matcher) => throwsA(
  isA<AlloyParseError>().having((e) => e.message, 'message', matcher),
);

void main() {
  const parser = AlloyModuleParser();

  Future<List<AlloyInjectableClass>> parse(String source) async =>
      parser.parseClass(await classNamed('Module', source));

  group('members become registrations', () {
    test('a method registers its return type', () async {
      final declarations = await parse('''
class Dio {}
class Config {}

@alloyModule
class Module {
  const Module();

  @alloyInject
  Dio dio(Config config) => Dio();
}
''');

      final dio = declarations.single;
      expect(dio.type.name, 'Dio');
      expect(dio.provider!.member, 'dio');
      expect(dio.provider!.module.name, 'Module');
      expect(dio.provider!.isGetter, isFalse);
      expect(dio.constructorParameters.single.type.name, 'Config');
      expect(dio.isAsyncInit, isFalse);
    });

    test('a getter is marked as one', () async {
      final declarations = await parse('''
class Clock {}

@alloyModule
class Module {
  const Module();

  @alloyInject
  Clock get clock => Clock();
}
''');

      expect(declarations.single.provider!.isGetter, isTrue);
    });

    test('an unannotated member is not registered', () async {
      final declarations = await parse('''
class Dio {}

@alloyModule
class Module {
  const Module();

  Dio helper() => Dio();
}
''');

      expect(declarations, isEmpty);
    });

    test('Future<T> registers T as async', () async {
      final declarations = await parse('''
class Prefs {}

@alloyModule
class Module {
  const Module();

  @alloyInject
  Future<Prefs> get prefs async => Prefs();
}
''');

      final prefs = declarations.single;
      expect(prefs.type.name, 'Prefs');
      expect(prefs.isAsyncInit, isTrue);
      expect(prefs.lifetime, AlloyLifetime.lazySingleton);
    });

    test('lifetime, name and exposeAs are read from the member', () async {
      final declarations = await parse('''
class Store {}
class SqlStore implements Store {}

@alloyModule
class Module {
  const Module();

  @AlloyInject(
    lifetime: AlloyLifetime.singleton,
    name: 'primary',
    exposeAs: Store,
  )
  SqlStore store() => SqlStore();
}
''');

      final store = declarations.single;
      expect(store.lifetime, AlloyLifetime.singleton);
      expect(store.name, 'primary');
      expect(store.exposeAs!.name, 'Store');
      expect(store.exposedType.name, 'Store');
    });

    test('@Named on a parameter selects a named registration', () async {
      final declarations = await parse('''
class Dio {}
class Logger {}

@alloyModule
class Module {
  const Module();

  @alloyInject
  Dio dio(@Named('audit') Logger logger) => Dio();
}
''');

      expect(declarations.single.constructorParameters.single.name, 'audit');
    });

    test('@AlloyEnvironment restricts the member', () async {
      final declarations = await parse('''
class Dio {}

@alloyModule
class Module {
  const Module();

  @alloyInject
  @AlloyEnvironment.dev
  Dio dio() => Dio();
}
''');

      expect(declarations.single.environments, {'dev'});
    });
  });

  group('the module class', () {
    test('an abstract module is rejected', () async {
      expect(
        () => parse('''
@alloyModule
abstract class Module {}
'''),
        rejects(contains('is abstract')),
      );
    });

    test('a module without a const constructor is rejected', () async {
      expect(
        () => parse('''
@alloyModule
class Module {
  Module();
}
'''),
        rejects(contains('public const constructor taking no arguments')),
      );
    });

    test('a module whose constructor takes arguments is rejected', () async {
      expect(
        () => parse('''
@alloyModule
class Module {
  const Module(this.url);
  final String url;
}
'''),
        rejects(contains('public const constructor taking no arguments')),
      );
    });
  });

  group('the member', () {
    Future<void> expectRejected(String member, Object matcher) async {
      expect(
        () => parse('''
class Dio {}

@alloyModule
class Module {
  const Module();

$member
}
'''),
        rejects(matcher),
      );
    }

    test('a static member is rejected', () async {
      await expectRejected(
        '  @alloyInject\n  static Dio dio() => Dio();',
        contains('is static'),
      );
    });

    test('a member returning void is rejected', () async {
      await expectRejected(
        '  @alloyInject\n  void nothing() {}',
        contains('not a type Alloy can register'),
      );
    });

    test('a bare Future is rejected', () async {
      await expectRejected(
        '  @alloyInject\n  Future dio() async => Dio();',
        contains('returns a bare Future'),
      );
    });

    test('a named parameter is rejected', () async {
      await expectRejected(
        '  @alloyInject\n  Dio dio({Dio? other}) => Dio();',
        contains('named parameter'),
      );
    });

    test('an optional positional parameter is rejected', () async {
      await expectRejected(
        '  @alloyInject\n  Dio dio([Dio? other]) => Dio();',
        contains('optional parameter'),
      );
    });

    test('a generic member is rejected', () async {
      await expectRejected(
        '  @alloyInject\n  T pick<T>() => throw UnimplementedError();',
        contains('declares type parameters'),
      );
    });

    test('@AlloyInit on a member is rejected', () async {
      await expectRejected(
        '  @alloyInit\n  @alloyInject\n  Dio dio() => Dio();',
        contains('Return Future<T> instead'),
      );
    });
  });

  group('dispose', () {
    test('a top-level function is read', () async {
      final declarations = await parse('''
class Client {}

void closeClient(Client client) {}

@alloyModule
class Module {
  const Module();

  @AlloyInject(dispose: closeClient)
  Client client() => Client();
}
''');

      final dispose = declarations.single.dispose!;
      expect(dispose.name, 'closeClient');
      expect(dispose.owner, isNull);
    });

    test('a static function keeps its owner', () async {
      final declarations = await parse('''
class Client {}

class Closers {
  static void close(Client client) {}
}

@alloyModule
class Module {
  const Module();

  @AlloyInject(dispose: Closers.close)
  Client client() => Client();
}
''');

      final dispose = declarations.single.dispose!;
      expect(dispose.name, 'close');
      expect(dispose.owner, 'Closers');
    });

    test('a transient that names one is rejected', () async {
      expect(
        () => parse('''
class Client {}

void closeClient(Client client) {}

@alloyModule
class Module {
  const Module();

  @AlloyInject(lifetime: AlloyLifetime.transient, dispose: closeClient)
  Client client() => Client();
}
'''),
        rejects(contains('does not retain a transient')),
      );
    });
  });
}
