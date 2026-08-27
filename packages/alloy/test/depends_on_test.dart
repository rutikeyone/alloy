import 'package:alloy/alloy.dart';
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
      final scope = AlloyScope.root(name: 'app')
        ..registerLazySingleton<Logger>(_Fn((_) => Logger()))
        ..registerAsyncSingleton<Index>(
          _AsyncFn((_) async => Index()),
          dependsOn: {const AlloyKey(Logger)},
        );
      addTearDown(scope.dispose);

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
      final scope = AlloyScope.root(name: 'app')
        ..registerAsyncSingleton<Index>(
          _AsyncFn((_) async => Index()),
          dependsOn: {const AlloyKey(Database)},
        );
      addTearDown(scope.dispose);

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
        final scope = AlloyScope.root(name: 'app')
          ..registerAsyncSingleton<Database>(
            _AsyncFn((_) async {
              built.add('database');
              return Database();
            }),
          )
          ..registerAsyncSingleton<Index>(
            _AsyncFn((_) async {
              built.add('index');
              return Index();
            }),
            dependsOn: {const AlloyKey(Database)},
          );
        addTearDown(scope.dispose);

        await scope.init();

        expect(built, ['database', 'index']);
      },
    );

    /// The one innocent way to be outside this scope's async set.
    ///
    /// A parent's phase 1 is its own, and a child pushed onto a live parent
    /// finds it already built — so the edge is dropped, not rejected.
    test('naming an async registration in an ancestor is allowed', () async {
      final root = AlloyScope.root(name: 'app')
        ..registerAsyncSingleton<Database>(_AsyncFn((_) async => Database()));
      addTearDown(root.dispose);
      await root.init();

      final child = root.push('session')
        ..registerAsyncSingleton<Index>(
          _AsyncFn((_) async => Index()),
          dependsOn: {const AlloyKey(Database)},
        );

      await child.init();

      expect(child.state, AlloyScopeState.active);
    });
  });

  group('a parameterized registration', () {
    test('resolved without its argument says which call to use', () {
      final scope = AlloyScope.root(name: 'app')
        ..registerParamFactory<Ticket, String>(_ParamFn((_, id) => Ticket(id)));
      addTearDown(scope.dispose);

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
      final scope = AlloyScope.root(name: 'app')
        ..registerLazySingleton<Logger>(_Fn((_) => Logger()));
      addTearDown(scope.dispose);

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

final class _Fn<T extends Object> implements AlloyFactory<T> {
  const _Fn(this.build);

  final T Function(AlloyResolver resolver) build;

  @override
  T create(AlloyResolver resolver) => build(resolver);
}

final class _AsyncFn<T extends Object> implements AlloyAsyncFactory<T> {
  const _AsyncFn(this.build);

  final Future<T> Function(AlloyResolver resolver) build;

  @override
  Future<T> create(AlloyResolver resolver) => build(resolver);
}

final class _ParamFn<T extends Object, P extends Object>
    implements AlloyParamFactory<T, P> {
  const _ParamFn(this.build);

  final T Function(AlloyResolver resolver, P param) build;

  @override
  T create(AlloyResolver resolver, P param) => build(resolver, param);
}
