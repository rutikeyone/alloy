import 'package:cobalt/cobalt.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Records what it is told, in the order it is told.
final class RecordingObserver extends CobaltObserver {
  RecordingObserver();

  final events = <String>[];

  @override
  void onScopePushed(CobaltScopeRef scope) => events.add('pushed:$scope');

  @override
  void onScopeInitStarted(CobaltScopeRef scope, int levels) =>
      events.add('init-started:$scope:$levels');

  @override
  void onScopeInitCompleted(CobaltScopeRef scope, Duration took) =>
      events.add('init-done:$scope');

  @override
  void onScopeInitFailed(
    CobaltScopeRef scope,
    Object error,
    StackTrace stackTrace,
  ) => events.add('init-failed:$scope');

  @override
  void onInstanceCreated(
    CobaltScopeRef scope,
    CobaltKey key, {
    required CobaltRegistrationKind kind,
    required bool retained,
  }) => events.add('created:$key:${kind.name}:${retained ? 'kept' : 'loose'}');

  @override
  void onInstanceDisposed(CobaltScopeRef scope, String label) =>
      events.add('disposed:$label');

  @override
  void onScopeDisposeStarted(CobaltScopeRef scope) =>
      events.add('disposing:$scope');

  @override
  void onScopeDisposed(
    CobaltScopeRef scope,
    Duration took,
    List<CobaltDisposeFailure> failures,
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

final class ExplodingObserver extends CobaltObserver {
  const ExplodingObserver();

  @override
  void onScopePushed(CobaltScopeRef scope) => throw StateError('boom');

  @override
  void onInstanceCreated(
    CobaltScopeRef scope,
    CobaltKey key, {
    required CobaltRegistrationKind kind,
    required bool retained,
  }) => throw StateError('boom');
}

class NoisyStep implements CobaltBootstrapStep, Disposable {
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

class TwoStepScope implements CobaltScopeBuilder {
  const TwoStepScope();

  @override
  void build(CobaltScope scope) =>
      scope.registerLazySingleton<Logger>(const LoggerFactory());
}

void main() {
  setUp(resetLogs);

  group('a graph with no observers', () {
    test('behaves exactly as before', () async {
      final root = cobaltTestRoot(name: 'app')
        ..registerLazySingleton<Logger>(const LoggerFactory());
      await root.init();

      expect(root.get<Logger>(), isA<Logger>());
      await root.dispose();

      expect(recorder.entries, ['Logger']);
    });
  });

  group('scope events', () {
    test('a push is reported with the parent it hangs from', () {
      final observer = RecordingObserver();
      final root = cobaltTestRoot(name: 'app', observers: [observer]);

      root.push('session');

      expect(observer.events, ['pushed:app/session']);
    });

    test('a child inherits the observers of its parent', () {
      final observer = RecordingObserver();
      final root = cobaltTestRoot(name: 'app', observers: [observer]);

      root.push('session').push('screen');

      expect(observer.events, ['pushed:app/session', 'pushed:session/screen']);
    });

    test('the ref describes the scope without exposing it', () {
      final observer = RecordingObserver();
      cobaltTestRoot(name: 'app', observers: [observer]);
      CobaltScopeRef? seen;

      final captured = _CapturingObserver((ref) => seen = ref);
      final other = cobaltTestRoot(name: 'app', observers: [captured]);
      other.push('session');

      expect(seen!.name, 'session');
      expect(seen!.depth, 1);
      expect(seen!.parentName, 'app');
      expect(seen, isA<CobaltScopeRef>());
    });
  });

  group('instance events', () {
    test('a lazy singleton is reported once, on first resolve', () {
      final observer = RecordingObserver();
      final root = cobaltTestRoot(name: 'app', observers: [observer])
        ..registerLazySingleton<Logger>(const LoggerFactory());

      root
        ..get<Logger>()
        ..get<Logger>();

      expect(observer.events, ['created:Logger:lazySingleton:kept']);
    });

    test('a transient is reported every time and marked loose', () {
      final observer = RecordingObserver();
      final root = cobaltTestRoot(name: 'app', observers: [observer])
        ..registerFactory<Logger>(const LoggerFactory());

      root
        ..get<Logger>()
        ..get<Logger>();

      expect(observer.events, [
        'created:Logger:transient:loose',
        'created:Logger:transient:loose',
      ]);
    });

    test('a parameterized factory is reported as loose', () {
      final observer = RecordingObserver();
      final root = cobaltTestRoot(name: 'app', observers: [observer])
        ..registerParamFactory<Greeting, String>(const GreetingFactory());

      root.getWithParam<Greeting, String>('there');

      expect(observer.events, ['created:Greeting:parameterized:loose']);
    });

    test('a named registration keeps its name in the key', () {
      final observer = RecordingObserver();
      final root = cobaltTestRoot(name: 'app', observers: [observer])
        ..registerLazySingleton<Logger>(const LoggerFactory(), name: 'audit');

      root.get<Logger>(name: 'audit');

      expect(observer.events, ['created:Logger(audit):lazySingleton:kept']);
    });
  });

  group('init events', () {
    test('report the level count and completion', () async {
      final observer = RecordingObserver();
      final root = cobaltTestRoot(name: 'app', observers: [observer])
        ..registerAsyncSingleton<AsyncRecorder>(const RecorderFactory());

      await root.init();

      expect(observer.events.first, 'init-started:app:1');
      expect(observer.events, contains('init-done:app'));
    });

    test('are silent when there is nothing async to build', () async {
      final observer = RecordingObserver();
      final root = cobaltTestRoot(name: 'app', observers: [observer])
        ..registerLazySingleton<Logger>(const LoggerFactory());

      await root.init();

      expect(observer.events.where((e) => e.startsWith('init-')), isEmpty);
    });
  });

  group('the lifetime a creation reports', () {
    test('an eager singleton reports nothing, having been built already', () {
      final observer = RecordingObserver();
      cobaltTestRoot(
        name: 'app',
        observers: [observer],
      ).registerSingleton<Logger>(Logger());

      expect(
        observer.events,
        isEmpty,
        reason: 'the caller built it; the scope only took ownership',
      );
    });

    test('an async singleton is told apart from a lazy one', () async {
      final observer = RecordingObserver();
      final scope = cobaltTestRoot(name: 'app', observers: [observer])
        ..registerAsyncSingleton<SlowService>(const SlowFactory('db', 0));

      await scope.init();

      expect(
        observer.events,
        contains('created:SlowService:asyncSingleton:kept'),
      );
    });

    test('the record carries the lifetime as a value, not as prose', () {
      final records = <CobaltLogRecord>[];
      final scope = cobaltTestRoot(
        name: 'app',
        observers: [
          CobaltLogObserver(
            CobaltLogSink.from(records.add),
            minimumLevel: CobaltLogLevel.trace,
          ),
        ],
      )..registerFactory<Logger>(const LoggerFactory());

      scope.get<Logger>();

      final created = records.firstWhere(
        (record) => record.kind == CobaltEventKind.instanceCreated,
      );
      expect(created.registrationKind, CobaltRegistrationKind.transient);
      expect(created.retained, isFalse);
      expect(created.toStructured()['lifetime'], 'transient');
    });
  });

  group('dispose events', () {
    test('report the order teardown actually happened in', () async {
      final observer = RecordingObserver();
      final root = cobaltTestRoot(name: 'app', observers: [observer])
        ..registerLazySingleton<Logger>(const LoggerFactory())
        ..registerLazySingleton<ApiClient>(const ApiClientFactory());
      root.get<ApiClient>();

      await root.dispose();

      expect(observer.events, [
        'created:Logger:lazySingleton:kept',
        'created:ApiClient:lazySingleton:kept',
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
        final root = cobaltTestRoot(name: 'app', observers: [observer])
          ..registerSingleton<_Angry>(_Angry());

        await expectLater(root.dispose(), throwsA(isA<CobaltDisposeError>()));

        expect(observer.events, isNot(contains('disposed:_Angry')));
        expect(observer.events.last, 'disposed-scope:app:1');
      },
    );
  });

  group('bootstrap events', () {
    test('bracket every step', () async {
      final observer = RecordingObserver();
      await cobaltTestScope(
        root: const TwoStepScope(),
        bootstrap: [NoisyStep('platform'), NoisyStep('config')],
        rootName: 'app',
        observers: [observer],
      );

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
        CobaltApplication.start(
          root: const TwoStepScope(),
          bootstrap: [
            NoisyStep('platform', failsOnRelease: true),
            NoisyStep('config', failsOnRun: true),
          ],
          observers: [observer],
        ),
        throwsA(isA<CobaltBootstrapError>()),
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
      final root = cobaltTestRoot(
        name: 'app',
        observers: [const ExplodingObserver()],
      )..registerLazySingleton<Logger>(const LoggerFactory());

      expect(root.push('session'), isA<CobaltScope>());
      expect(root.get<Logger>(), isA<Logger>());
    });
  });
}

final class _CapturingObserver extends CobaltObserver {
  _CapturingObserver(this.onPushed);

  final void Function(CobaltScopeRef ref) onPushed;

  @override
  void onScopePushed(CobaltScopeRef scope) => onPushed(scope);
}

class _Angry implements Disposable {
  @override
  void dispose() => throw StateError('no');
}
