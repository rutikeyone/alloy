import 'dart:async';

import 'package:alloy/alloy.dart';
import 'package:test/test.dart';

import 'support.dart';

class ThrowingDisposable implements Disposable {
  ThrowingDisposable(this.label);

  final String label;

  @override
  void dispose() => throw StateError('$label refused to close');
}

class ThrowingAsyncDisposable implements AsyncDisposable {
  ThrowingAsyncDisposable(this.label);

  final String label;

  @override
  Future<void> dispose() async => throw StateError('$label refused to close');
}

class NeverFinishes implements AsyncDisposable {
  NeverFinishes(this.label);

  final String label;

  @override
  Future<void> dispose() => Completer<void>().future;
}

class SlowDisposable implements AsyncDisposable {
  SlowDisposable(this.label, this.delay);

  final String label;
  final Duration delay;

  @override
  Future<void> dispose() async {
    await Future<void>.delayed(delay);
    disposeLog.add(label);
  }
}

class FailingInit implements AlloyAsyncFactory<Recorder> {
  const FailingInit();

  @override
  Future<Recorder> create(AlloyResolver resolver) async =>
      throw StateError('the database refused to open');
}

class FailingAsyncInit implements AlloyAsyncFactory<AsyncRecorder> {
  const FailingAsyncInit();

  @override
  Future<AsyncRecorder> create(AlloyResolver resolver) async =>
      throw StateError('boom');
}

class StuckInit implements AlloyAsyncFactory<Recorder> {
  const StuckInit();

  @override
  Future<Recorder> create(AlloyResolver resolver) =>
      Completer<Recorder>().future;
}

void main() {
  setUp(resetLogs);

  test('a hanging init no longer blocks teardown forever', () async {
    final scope = AlloyScope.root(name: 'app')
      ..registerAsyncSingleton<Recorder>(const StuckInit());
    unawaited(scope.init());

    await expectLater(
      scope.dispose(timeout: const Duration(milliseconds: 50)),
      throwsA(
        isA<AlloyDisposeError>()
            .having((e) => e.scopeName, 'scopeName', 'app')
            .having((e) => e.hasTimeout, 'hasTimeout', isTrue)
            .having(
              (e) => e.failures.map((f) => f.label),
              'labels',
              contains('init'),
            ),
      ),
    );

    expect(scope.state, AlloyScopeState.disposed);
  });

  test('a hanging disposable is reported by type', () async {
    final scope = AlloyScope.root()..registerSingleton(NeverFinishes('stuck'));

    await expectLater(
      scope.dispose(timeout: const Duration(milliseconds: 50)),
      throwsA(
        isA<AlloyDisposeError>().having(
          (e) => e.failures.map((f) => f.label),
          'labels',
          contains('NeverFinishes.dispose'),
        ),
      ),
    );

    expect(scope.state, AlloyScopeState.disposed);
  });

  test('teardown continues past a step that timed out', () async {
    final scope = AlloyScope.root()
      ..registerSingleton(Recorder('first'), name: 'first')
      ..registerSingleton(NeverFinishes('stuck'))
      ..registerSingleton(Recorder('last'), name: 'last');

    await expectLater(
      scope.dispose(timeout: const Duration(milliseconds: 50)),
      throwsA(isA<AlloyDisposeError>()),
    );

    expect(disposeLog, [
      'last',
      'first',
    ], reason: 'the sync disposables on both sides of the stuck one still ran');
  });

  test('the deadline covers the whole tree, not each step', () async {
    final scope = AlloyScope.root()
      ..registerSingleton(NeverFinishes('a'), name: 'a')
      ..registerSingleton(NeverFinishes('b'), name: 'b')
      ..registerSingleton(NeverFinishes('c'), name: 'c');

    final watch = Stopwatch()..start();
    await expectLater(
      scope.dispose(timeout: const Duration(milliseconds: 100)),
      throwsA(isA<AlloyDisposeError>()),
    );
    watch.stop();

    expect(watch.elapsedMilliseconds, lessThan(250));
  });

  test('a child that overruns is reported under its own name', () async {
    final root = AlloyScope.root(name: 'app');
    root.push('session').registerSingleton(NeverFinishes('stuck'));

    await expectLater(
      root.dispose(timeout: const Duration(milliseconds: 50)),
      throwsA(
        isA<AlloyDisposeError>().having(
          (e) => e.failures.map((f) => f.label),
          'labels',
          contains('session/NeverFinishes.dispose'),
        ),
      ),
    );

    expect(root.state, AlloyScopeState.disposed);
  });

  test('teardown well inside the budget stays quiet', () async {
    final scope = AlloyScope.root()
      ..registerSingleton(
        SlowDisposable('slow', const Duration(milliseconds: 10)),
      );

    await scope.dispose(timeout: const Duration(seconds: 5));

    expect(disposeLog, ['slow']);
    expect(scope.state, AlloyScopeState.disposed);
  });

  test('a throwing disposable does not strand the rest', () async {
    final scope = AlloyScope.root()
      ..registerSingleton(Recorder('first'), name: 'first')
      ..registerSingleton(ThrowingDisposable('broken'))
      ..registerSingleton(Recorder('last'), name: 'last');

    await expectLater(
      scope.dispose(),
      throwsA(
        isA<AlloyDisposeError>()
            .having((e) => e.hasTimeout, 'hasTimeout', isFalse)
            .having((e) => e.failures, 'failures', hasLength(1))
            .having((e) => e.failures.single.error, 'cause', isA<StateError>()),
      ),
    );

    expect(disposeLog, ['last', 'first']);
    expect(scope.state, AlloyScopeState.disposed);
  });

  test('an async disposable that throws is recorded too', () async {
    final scope = AlloyScope.root()
      ..registerSingleton(ThrowingAsyncDisposable('broken'));

    await expectLater(
      scope.dispose(),
      throwsA(
        isA<AlloyDisposeError>().having(
          (e) => e.failures.single.label,
          'label',
          'ThrowingAsyncDisposable.dispose',
        ),
      ),
    );
  });

  test('timeouts and exceptions are reported together', () async {
    final scope = AlloyScope.root()
      ..registerSingleton(ThrowingDisposable('broken'))
      ..registerSingleton(NeverFinishes('stuck'));

    await expectLater(
      scope.dispose(timeout: const Duration(milliseconds: 50)),
      throwsA(
        isA<AlloyDisposeError>()
            .having((e) => e.failures, 'failures', hasLength(2))
            .having((e) => e.timeouts, 'timeouts', hasLength(1)),
      ),
    );
  });

  test('a failure inside a child is reported under the child name', () async {
    final root = AlloyScope.root(name: 'app');
    root.push('session').registerSingleton(ThrowingDisposable('broken'));

    await expectLater(
      root.dispose(),
      throwsA(
        isA<AlloyDisposeError>().having(
          (e) => e.failures.single.label,
          'label',
          'session/ThrowingDisposable.dispose',
        ),
      ),
    );

    expect(root.state, AlloyScopeState.disposed);
  });

  group('a failed init', () {
    test('does not make teardown itself fail', () async {
      final scope = AlloyScope.root(name: 'app')
        ..registerSingleton(Recorder('early'))
        ..registerAsyncSingleton<Recorder>(const FailingInit(), name: 'async');
      await expectLater(scope.init(), throwsA(isA<StateError>()));

      await scope.dispose();

      expect(disposeLog, ['early']);
      expect(scope.state, AlloyScopeState.disposed);
    });

    test('is listed as context when teardown also fails', () async {
      final scope = AlloyScope.root()
        ..registerSingleton(ThrowingDisposable('broken'))
        ..registerAsyncSingleton<Recorder>(const FailingInit());
      await expectLater(scope.init(), throwsA(isA<StateError>()));

      try {
        await scope.dispose();
        fail('expected AlloyDisposeError');
      } on AlloyDisposeError catch (error) {
        expect(error.failures, hasLength(2));
        expect(error.releaseFailures, hasLength(1));

        final context = error.initFailures.single;
        expect(context.isInitFailure, isTrue);
        expect(context.stage, AlloyDisposeStage.awaitingInit);
        expect(context.toString(), contains('initialization failed'));
        expect(error.toString(), contains('never fully built'));
      }
    });

    test('a still-running init that hangs is a teardown failure', () async {
      final scope = AlloyScope.root()
        ..registerAsyncSingleton<Recorder>(const StuckInit());
      unawaited(scope.init());

      await expectLater(
        scope.dispose(timeout: const Duration(milliseconds: 50)),
        throwsA(isA<AlloyDisposeError>()),
      );

      expect(scope.state, AlloyScopeState.disposed);
    });
  });

  test('the default budget is generous enough for ordinary teardown', () async {
    final scope = AlloyScope.root()
      ..registerSingleton(AsyncRecorder('async'))
      ..registerSingleton(Recorder('sync'));

    await scope.dispose();

    expect(disposeLog, ['sync', 'async']);
  });
}
