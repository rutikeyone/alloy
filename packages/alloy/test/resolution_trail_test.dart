import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

class Missing {}

class Ready {}

class Api {
  Api(this.repository);

  final Object repository;
}

class Repository {
  Repository(this.missing);

  final Object missing;
}

void main() {
  group('a failure inside a factory', () {
    test('names the registration that asked for it', () {
      final scope = alloyTestRoot(name: 'app')
        ..registerLazySingleton<Repository>(
          FnFactory((resolver) => Repository(resolver.get<Missing>())),
        );

      expect(
        () => scope.get<Repository>(),
        throwsA(
          isA<AlloyNotRegisteredError>().having(
            (e) => e.toString(),
            'message',
            contains('Resolving: Repository -> Missing'),
          ),
        ),
      );
    });

    test('names every step of a chain, outermost first', () {
      final scope = alloyTestRoot(name: 'app')
        ..registerLazySingleton<Api>(
          FnFactory((resolver) => Api(resolver.get<Repository>())),
        )
        ..registerLazySingleton<Repository>(
          FnFactory((resolver) => Repository(resolver.get<Missing>())),
        );

      expect(
        () => scope.get<Api>(),
        throwsA(
          isA<AlloyNotRegisteredError>().having(
            (e) => e.toString(),
            'message',
            contains('Resolving: Api -> Repository -> Missing'),
          ),
        ),
      );
    });

    test('carries the trail as keys, not only as prose', () {
      final scope = alloyTestRoot(name: 'app')
        ..registerLazySingleton<Repository>(
          FnFactory((resolver) => Repository(resolver.get<Missing>())),
        );

      try {
        scope.get<Repository>();
        fail('the missing registration should have thrown');
      } on AlloyNotRegisteredError catch (error) {
        expect(error.resolving.map((key) => key.type), [Repository]);
        expect(error.key.type, Missing);
      }
    });

    test('an async singleton asked for too early names the asker too', () {
      final scope = alloyTestRoot(name: 'app')
        ..registerAsyncSingleton<Ready>(AsyncFnFactory((_) async => Ready()))
        ..registerLazySingleton<Repository>(
          FnFactory((resolver) => Repository(resolver.get<Ready>())),
        );

      expect(
        () => scope.get<Repository>(),
        throwsA(
          isA<AlloyNotReadyError>().having(
            (e) => e.toString(),
            'message',
            contains('Resolving: Repository -> Ready'),
          ),
        ),
      );
    });
  });

  group('a failure outside one', () {
    test('asking from the top has no trail to report', () {
      final scope = alloyTestRoot(name: 'app');

      expect(
        () => scope.get<Missing>(),
        throwsA(
          isA<AlloyNotRegisteredError>().having(
            (e) => e.toString(),
            'message',
            isNot(contains('Resolving:')),
          ),
        ),
      );
    });

    /// The reason the trail is built by `guard` alone.
    ///
    /// `Future.wait` enters every registration in a level before any of them
    /// suspends, so both keys are under construction at once. Reading that as
    /// a chain would print a caller that never called.
    test('a parallel init level does not invent a caller', () async {
      final scope = alloyTestRoot(name: 'app')
        ..registerAsyncSingleton<Ready>(
          AsyncFnFactory((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return Ready();
          }),
        )
        ..registerAsyncSingleton<Api>(
          AsyncFnFactory((resolver) async => Api(resolver.get<Missing>())),
        );

      await expectLater(
        scope.init(),
        throwsA(
          isA<AlloyNotRegisteredError>()
              .having((e) => e.toString(), 'message', isNot(contains('Ready')))
              .having((e) => e.resolving, 'resolving', isEmpty),
        ),
      );
    });
  });
}
