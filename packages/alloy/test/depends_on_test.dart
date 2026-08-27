import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

class Logger {}

class Database {}

class Index {}

class Ticket {
  Ticket(this.id);

  final String id;
}

void main() {
  group('dependsOn', () {
    test('naming a registration that is not async fails init', () async {
      final scope = alloyTestRoot(name: 'app')
        ..registerLazySingleton<Logger>(FnFactory((_) => Logger()))
        ..registerAsyncSingleton<Index>(
          AsyncFnFactory((_) async => Index()),
          dependsOn: {const AlloyKey(Logger)},
        );

      await expectLater(
        scope.init(),
        throwsA(
          isA<AlloyDependsOnError>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('Index'),
              contains('Logger'),
              contains('not as an async singleton'),
            ),
          ),
        ),
      );
    });

    test('naming something nothing registers fails init', () async {
      final scope = alloyTestRoot(name: 'app')
        ..registerAsyncSingleton<Index>(
          AsyncFnFactory((_) async => Index()),
          dependsOn: {const AlloyKey(Database)},
        );

      await expectLater(
        scope.init(),
        throwsA(
          isA<AlloyDependsOnError>().having(
            (e) => e.toString(),
            'message',
            contains('nothing registers'),
          ),
        ),
      );
    });

    test(
      'naming an async registration in the same scope still works',
      () async {
        final built = <String>[];
        final scope = alloyTestRoot(name: 'app')
          ..registerAsyncSingleton<Database>(
            AsyncFnFactory((_) async {
              built.add('database');
              return Database();
            }),
          )
          ..registerAsyncSingleton<Index>(
            AsyncFnFactory((_) async {
              built.add('index');
              return Index();
            }),
            dependsOn: {const AlloyKey(Database)},
          );

        await scope.init();

        expect(built, ['database', 'index']);
      },
    );

    /// The one innocent way to be outside this scope's async set.
    ///
    /// A parent's phase 1 is its own, and a child pushed onto a live parent
    /// finds it already built — so the edge is dropped, not rejected.
    test('naming an async registration in an ancestor is allowed', () async {
      final root = alloyTestRoot(name: 'app')
        ..registerAsyncSingleton<Database>(
          AsyncFnFactory((_) async => Database()),
        );
      await root.init();

      final child = root.push('session')
        ..registerAsyncSingleton<Index>(
          AsyncFnFactory((_) async => Index()),
          dependsOn: {const AlloyKey(Database)},
        );

      await child.init();

      expect(child.state, AlloyScopeState.active);
    });
  });

  group('a parameterized registration', () {
    test('resolved without its argument says which call to use', () {
      final scope = alloyTestRoot(name: 'app')
        ..registerParamFactory<Ticket, String>(
          FnParamFactory((_, id) => Ticket(id)),
        );

      expect(
        () => scope.get<Ticket>(),
        throwsA(
          isA<AlloyParamRequiredError>().having(
            (e) => e.toString(),
            'message',
            contains('getWithParam'),
          ),
        ),
      );
    });

    test('is the only thing getWithParam accepts', () {
      final scope = alloyTestRoot(name: 'app')
        ..registerLazySingleton<Logger>(FnFactory((_) => Logger()));

      expect(
        () => scope.getWithParam<Logger, String>('x'),
        throwsA(
          isA<AlloyNotParameterizedError>().having(
            (e) => e.key.type,
            'key.type',
            Logger,
          ),
        ),
      );
    });
  });
}
