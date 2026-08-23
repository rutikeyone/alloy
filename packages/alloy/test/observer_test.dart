import 'package:alloy/alloy.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Records what it is told, in the order it is told.
final class RecordingObserver extends AlloyObserver {
  RecordingObserver();

  final events = <String>[];

  @override
  void onScopePushed(AlloyScopeRef scope) => events.add('pushed:$scope');

  @override
  void onScopeInitStarted(AlloyScopeRef scope, int levels) =>
      events.add('init-started:$scope:$levels');

  @override
  void onScopeInitCompleted(AlloyScopeRef scope, Duration took) =>
      events.add('init-done:$scope');

  @override
  void onScopeInitFailed(
    AlloyScopeRef scope,
    Object error,
    StackTrace stackTrace,
  ) => events.add('init-failed:$scope');

  @override
  void onInstanceCreated(
    AlloyScopeRef scope,
    AlloyKey key, {
    required bool retained,
  }) => events.add('created:$key:${retained ? 'kept' : 'loose'}');

  @override
  void onInstanceDisposed(AlloyScopeRef scope, String label) =>
      events.add('disposed:$label');

  @override
  void onScopeDisposeStarted(AlloyScopeRef scope) =>
      events.add('disposing:$scope');

  @override
  void onScopeDisposed(
    AlloyScopeRef scope,
    Duration took,
    List<AlloyDisposeFailure> failures,
  ) => events.add('disposed-scope:$scope:${failures.length}');

  @override
  void onBootstrapStepStarted(String step) => events.add('boot-start:$step');

  @override
  void onBootstrapStepCompleted(String step, Duration took) =>
      events.add('boot-done:$step');

  @override
  void onBootstrapStepFailed(String s, Object e, StackTrace t) =>
      events.add('boot-failed:$s');

  @override
  void onBootstrapStepReleaseFailed(String s, Object e, StackTrace t) =>
      events.add('boot-release-failed:$s');
}

final class ExplodingObserver extends AlloyObserver {
  const ExplodingObserver();

  @override
  void onScopePushed(AlloyScopeRef scope) => throw StateError('boom');

  @override
  void onInstanceCreated(
    AlloyScopeRef scope,
    AlloyKey key, {
    required bool retained,
  }) => throw StateError('boom');
}

class NoisyStep implements AlloyBootstrapStep, Disposable {
  NoisyStep(this.name, {this.failsOnRun = false, this.failsOnRelease = false});

  @override
  final String name;

  final bool failsOnRun;
  final bool failsOnRelease;

  @override
  void run() {
    if (failsOnRun) throw StateError('$name refused to run');
  }

  @override
  void dispose() {
    if (failsOnRelease) throw StateError('$name refused to release');
  }
}

class TwoStepScope implements AlloyScopeBuilder {
  const TwoStepScope();

  @override
  void build(AlloyScope scope) =>
      scope.registerLazySingleton<Logger>(const LoggerFactory());
}

void main() {
  setUp(resetLogs);

  group('a graph with no observers', () {
    test('behaves exactly as before', () async {
      final root = AlloyScope.root(name: 'app')
        ..registerLazySingleton<Logger>(const LoggerFactory());
      await root.init();

      expect(root.get<Logger>(), isA<Logger>());
      await root.dispose();

      expect(disposeLog, ['Logger']);
    });
  });

  group('scope events', () {
    test('a push is reported with the parent it hangs from', () {
      final observer = RecordingObserver();
      final root = AlloyScope.root(name: 'app', observers: [observer]);
      addTearDown(root.dispose);

      root.push('session');

      expect(observer.events, ['pushed:app/session']);
    });

    test('a child inherits the observers of its parent', () {
      final observer = RecordingObserver();
      final root = AlloyScope.root(name: 'app', observers: [observer]);
      addTearDown(root.dispose);

      root.push('session').push('screen');

      expect(observer.events, ['pushed:app/session', 'pushed:session/screen']);
    });

    test('the ref describes the scope without exposing it', () {
      final observer = RecordingObserver();
      final root = AlloyScope.root(name: 'app', observers: [observer]);
      addTearDown(root.dispose);
      AlloyScopeRef? seen;

      final captured = _CapturingObserver((ref) => seen = ref);
      final other = AlloyScope.root(name: 'app', observers: [captured]);
      addTearDown(other.dispose);
      other.push('session');

      expect(seen!.name, 'session');
      expect(seen!.depth, 1);
      expect(seen!.parentName, 'app');
      expect(seen, isA<AlloyScopeRef>());
    });
  });

  group('instance events', () {
    test('a lazy singleton is reported once, on first resolve', () {
      final observer = RecordingObserver();
      final root = AlloyScope.root(name: 'app', observers: [observer])
        ..registerLazySingleton<Logger>(const LoggerFactory());
      addTearDown(root.dispose);

      root
        ..get<Logger>()
        ..get<Logger>();

      expect(observer.events, ['created:Logger:kept']);
    });

    test('a transient is reported every time and marked loose', () {
      final observer = RecordingObserver();
      final root = AlloyScope.root(name: 'app', observers: [observer])
        ..registerFactory<Logger>(const LoggerFactory());
      addTearDown(root.dispose);

      root
        ..get<Logger>()
        ..get<Logger>();

      expect(observer.events, ['created:Logger:loose', 'created:Logger:loose']);
    });

    test('a parameterized factory is reported as loose', () {
      final observer = RecordingObserver();
      final root = AlloyScope.root(name: 'app', observers: [observer])
        ..registerParamFactory<Greeting, String>(const GreetingFactory());
      addTearDown(root.dispose);

      root.getWithParam<Greeting, String>('there');

      expect(observer.events, ['created:Greeting:loose']);
    });

    test('a named registration keeps its name in the key', () {
      final observer = RecordingObserver();
      final root = AlloyScope.root(name: 'app', observers: [observer])
        ..registerLazySingleton<Logger>(const LoggerFactory(), name: 'audit');
      addTearDown(root.dispose);

      root.get<Logger>(name: 'audit');

      expect(observer.events, ['created:Logger(audit):kept']);
    });
  });

  group('init events', () {
    test('report the level count and completion', () async {
      final observer = RecordingObserver();
      final root = AlloyScope.root(name: 'app', observers: [observer])
        ..registerAsyncSingleton<AsyncRecorder>(const RecorderFactory());

      await root.init();
      addTearDown(root.dispose);

      expect(observer.events.first, 'init-started:app:1');
      expect(observer.events, contains('init-done:app'));
    });

    test('are silent when there is nothing async to build', () async {
      final observer = RecordingObserver();
      final root = AlloyScope.root(name: 'app', observers: [observer])
        ..registerLazySingleton<Logger>(const LoggerFactory());

      await root.init();
      addTearDown(root.dispose);

      expect(observer.events.where((e) => e.startsWith('init-')), isEmpty);
    });
  });

  group('dispose events', () {
    test('report the order teardown actually happened in', () async {
      final observer = RecordingObserver();
      final root = AlloyScope.root(name: 'app', observers: [observer])
        ..registerLazySingleton<Logger>(const LoggerFactory())
        ..registerLazySingleton<ApiClient>(const ApiClientFactory());
      root.get<ApiClient>();

      await root.dispose();

      expect(observer.events, [
        'created:Logger:kept',
        'created:ApiClient:kept',
        'disposing:app',
        'disposed:ApiClient',
        'disposed:Logger',
        'disposed-scope:app:0',
      ]);
    });

    test(
      'a failed release is counted, and the instance is not reported',
      () async {
        final observer = RecordingObserver();
        final root = AlloyScope.root(name: 'app', observers: [observer])
          ..registerSingleton<_Angry>(_Angry());

        await expectLater(root.dispose(), throwsA(isA<AlloyDisposeError>()));

        expect(observer.events, isNot(contains('disposed:_Angry')));
        expect(observer.events.last, 'disposed-scope:app:1');
      },
    );
  });

  group('bootstrap events', () {
    test('bracket every step', () async {
      final observer = RecordingObserver();
      final scope = await AlloyApplication.start(
        root: const TwoStepScope(),
        bootstrap: [NoisyStep('platform'), NoisyStep('config')],
        rootName: 'app',
        observers: [observer],
      );
      addTearDown(scope.dispose);

      expect(observer.events.take(4), [
        'boot-start:platform',
        'boot-done:platform',
        'boot-start:config',
        'boot-done:config',
      ]);
    });

    test('a step that fails to release is no longer swallowed', () async {
      final observer = RecordingObserver();

      await expectLater(
        AlloyApplication.start(
          root: const TwoStepScope(),
          bootstrap: [
            NoisyStep('platform', failsOnRelease: true),
            NoisyStep('config', failsOnRun: true),
          ],
          observers: [observer],
        ),
        throwsA(isA<AlloyBootstrapError>()),
      );

      expect(
        observer.events,
        containsAllInOrder(<String>[
          'boot-failed:config',
          'boot-release-failed:platform',
        ]),
        reason:
            'before observers existed this rollback failure had nowhere to go '
            'and was dropped by a bare catch',
      );
    });
  });

  group('an observer that throws', () {
    test('cannot break the graph it is watching', () {
      final root = AlloyScope.root(
        name: 'app',
        observers: [const ExplodingObserver()],
      )..registerLazySingleton<Logger>(const LoggerFactory());
      addTearDown(root.dispose);

      expect(root.push('session'), isA<AlloyScope>());
      expect(root.get<Logger>(), isA<Logger>());
    });
  });
}

final class _CapturingObserver extends AlloyObserver {
  _CapturingObserver(this.onPushed);

  final void Function(AlloyScopeRef ref) onPushed;

  @override
  void onScopePushed(AlloyScopeRef scope) => onPushed(scope);
}

class _Angry implements Disposable {
  @override
  void dispose() => throw StateError('no');
}
