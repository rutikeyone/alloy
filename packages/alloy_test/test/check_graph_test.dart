import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('checkGraph', () {
    test('a complete graph resolves', () async {
      final scope = alloyTestRoot()
        ..registerLazySingleton<Clock>(const ValueFactory(Clock()))
        ..registerLazySingleton<Api>(FnFactory((r) => Api(r.get<Clock>())));

      final report = await checkGraph(scope);

      expect(report.isComplete, isTrue);
      expect(report.entries, hasLength(2));
    });

    test('names a dependency nothing registers', () async {
      final scope = alloyTestRoot()
        ..registerLazySingleton<Broken>(
          FnFactory((r) => Broken(r.get<Logger>())),
        );

      final report = await checkGraph(scope);

      expect(report.isComplete, isFalse);
      expect(report.failures.single.key, const AlloyKey(Broken));
      expect(report.failures.single.error, isA<AlloyNotRegisteredError>());
    });

    test('reports every hole at once, not the first', () async {
      final scope = alloyTestRoot()
        ..registerLazySingleton<Broken>(
          FnFactory((r) => Broken(r.get<Logger>())),
        )
        ..registerLazySingleton<Api>(FnFactory((r) => Api(r.get<Clock>())));

      final report = await checkGraph(scope);

      expect(report.failures, hasLength(2));
    });

    test('expectGraphResolves fails with every hole listed', () async {
      final scope = alloyTestRoot()
        ..registerLazySingleton<Broken>(
          FnFactory((r) => Broken(r.get<Logger>())),
        );

      await expectLater(
        expectGraphResolves(scope),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Broken'),
          ),
        ),
      );
    });

    test('sees what an ancestor registered', () async {
      final root = alloyTestRoot()
        ..registerLazySingleton<Clock>(const ValueFactory(Clock()));
      final child = root.pushForTest()
        ..registerLazySingleton<Api>(FnFactory((r) => Api(r.get<Clock>())));

      final report = await checkGraph(child);

      expect(report.isComplete, isTrue);
      expect(report.entries, hasLength(2));
    });
  });

  group('what it cannot check', () {
    test(
      'a parameterized registration is listed by name, not skipped',
      () async {
        final scope = alloyTestRoot()
          ..registerParamFactory<Ticket, String>(const TicketFactory());

        final report = await checkGraph(scope);

        expect(report.unchecked.single.key, const AlloyKey(Ticket));
        expect(report.unchecked.single.reason, contains('parameterized'));
        expect(report.isComplete, isTrue, reason: 'unchecked is not failed');
      },
    );

    test('a sample value makes it checkable', () async {
      final scope = alloyTestRoot()
        ..registerParamFactory<Ticket, String>(const TicketFactory());

      final report = await checkGraph(
        scope,
        params: {const AlloyKey(Ticket): 'abc'},
      );

      expect(report.unchecked, isEmpty);
      expect(report.entries.single.outcome, AlloyGraphOutcome.resolved);
    });
  });

  group('side effects it is honest about', () {
    test('an async singleton is initialised before being resolved', () async {
      final scope = alloyTestRoot()
        ..registerAsyncSingleton<Clock>(const AsyncFnFactory(_slowClock));

      final report = await checkGraph(scope);

      expect(report.isComplete, isTrue);
      expect(scope.state, AlloyScopeState.active);
    });

    test(
      'it builds every lazy singleton, which is why it is terminal',
      () async {
        var built = 0;
        final scope = alloyTestRoot()
          ..registerLazySingleton<Clock>(
            FnFactory((_) {
              built++;
              return const Clock();
            }),
          );

        expect(built, 0);
        await checkGraph(scope);
        expect(built, 1, reason: 'resolving is the check; there is no dry run');
      },
    );

    test(
      'a transient it built is disposed, since the scope will not',
      () async {
        final recorder = DisposeRecorder();
        final scope = alloyTestRoot()
          ..registerFactory<Disposable>(recorder.factory('loose'));

        await checkGraph(scope);

        expect(recorder.entries, ['loose']);
      },
    );

    test('a cycle arrives with its path', () async {
      final scope = alloyTestRoot()
        ..registerLazySingleton<Api>(FnFactory((r) => r.get<Api>()));

      final report = await checkGraph(scope);

      expect(report.failures.single.error, isA<AlloyCycleError>());
    });
  });
}

Future<Clock> _slowClock(AlloyResolver resolver) async {
  await Future<void>.delayed(Duration.zero);
  return const Clock();
}
