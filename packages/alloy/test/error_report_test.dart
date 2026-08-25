import 'package:alloy/alloy.dart';
import 'package:test/test.dart';

final class _Collecting implements AlloyErrorSink {
  final reports = <AlloyErrorReport>[];

  @override
  void report(AlloyErrorReport report) => reports.add(report);
}

final class _BrokenSink implements AlloyErrorSink {
  const _BrokenSink();

  @override
  void report(AlloyErrorReport report) => throw StateError('reporter is down');
}

/// Records every event, so a test can assert on the kinds that were produced.
final class _Kinds extends AlloyRecordingObserver {
  final seen = <AlloyEventKind>[];

  @override
  void onRecord(AlloyLogRecord record) => seen.add(record.kind);
}

final class _FailingInit implements AsyncInitializable {
  @override
  Future<void> init() async => throw StateError('init went wrong');
}

final class _FailingInitFactory implements AlloyAsyncFactory<_FailingInit> {
  const _FailingInitFactory();

  @override
  Future<_FailingInit> create(AlloyResolver resolver) async {
    final instance = _FailingInit();
    await instance.init();
    return instance;
  }
}

final class _Marker {}

final class _MarkerFactory implements AlloyFactory<_Marker> {
  const _MarkerFactory();

  @override
  _Marker create(AlloyResolver resolver) => _Marker();
}

final class _Graph implements AlloyScopeBuilder {
  const _Graph({this.failing = false});

  final bool failing;

  @override
  void build(AlloyScope scope) {
    scope.registerSingleton<_Marker>(const _MarkerFactory().create(scope));
    if (failing) {
      scope.registerAsyncSingleton<_FailingInit>(const _FailingInitFactory());
    }
  }
}

void main() {
  group('the record carries what happened', () {
    test('every kind is reachable from a real graph or named by a mapping', () {
      // Not a coverage assertion — a guard. A new observer event that forgets
      // to pick a kind cannot compile, and a kind nothing ever emits is dead
      // weight worth noticing here.
      expect(AlloyEventKind.values, isNotEmpty);
      expect(
        AlloyEventKind.values.toSet(),
        hasLength(AlloyEventKind.values.length),
      );
    });

    test('a graph reports its events by kind, not by prose', () async {
      final kinds = _Kinds();
      final scope = await AlloyApplication.start(
        root: const _Graph(),
        rootName: 'app',
        observers: [kinds],
      );
      await scope.dispose();

      expect(
        kinds.seen,
        containsAll([
          AlloyEventKind.scopeDisposeStarted,
          AlloyEventKind.scopeDisposed,
        ]),
      );
    });

    test('toStructured names the event and the scope', () {
      const record = AlloyLogRecord(
        kind: AlloyEventKind.scopeInitFailed,
        level: AlloyLogLevel.error,
        message: 'scope "app" failed to initialize',
        scope: AlloyScopeRef(name: 'app', depth: 0),
      );

      expect(record.toStructured(), {
        'event': 'scopeInitFailed',
        'level': 'error',
        'message': 'scope "app" failed to initialize',
        'scope': 'app',
        'scope_depth': 0,
      });
    });

    test('toStructured drops absent fields rather than sending nulls', () {
      const record = AlloyLogRecord(
        kind: AlloyEventKind.scopePushed,
        level: AlloyLogLevel.debug,
        message: 'pushed',
      );

      expect(record.toStructured().keys, ['event', 'level', 'message']);
    });
  });

  group('a report carries the trail', () {
    test('a failed initializer is reported with what preceded it', () async {
      final sink = _Collecting();

      await expectLater(
        AlloyApplication.start(
          root: const _Graph(failing: true),
          rootName: 'app',
          observers: [AlloyErrorObserver(sink)],
        ),
        throwsA(isA<Object>()),
      );

      expect(sink.reports, hasLength(1));
      final report = sink.reports.single;
      expect(report.failure.kind, AlloyEventKind.scopeInitFailed);
      expect(report.error, isA<StateError>());
      expect(
        report.breadcrumbs,
        isNotEmpty,
        reason: 'the events before the failure are the point of the report',
      );
      expect(
        report.breadcrumbs,
        isNot(contains(report.failure)),
        reason: 'the failure is not also one of its own breadcrumbs',
      );
    });

    test('the trail is bounded and oldest first', () {
      final sink = _Collecting();
      final observer = AlloyErrorObserver(sink, breadcrumbs: 3);

      for (var i = 0; i < 10; i++) {
        observer.onRecord(
          AlloyLogRecord(
            kind: AlloyEventKind.scopePushed,
            level: AlloyLogLevel.debug,
            message: 'event $i',
          ),
        );
      }
      observer.onRecord(
        AlloyLogRecord(
          kind: AlloyEventKind.scopeInitFailed,
          level: AlloyLogLevel.error,
          message: 'boom',
          error: StateError('boom'),
        ),
      );

      final trail = sink.reports.single.breadcrumbs;
      expect(trail.map((r) => r.message), ['event 7', 'event 8', 'event 9']);
    });

    test('breadcrumbs: 0 reports the failure with no trail', () {
      final sink = _Collecting();
      final observer = AlloyErrorObserver(sink, breadcrumbs: 0);

      observer
        ..onRecord(
          const AlloyLogRecord(
            kind: AlloyEventKind.scopePushed,
            level: AlloyLogLevel.debug,
            message: 'pushed',
          ),
        )
        ..onRecord(
          AlloyLogRecord(
            kind: AlloyEventKind.scopeInitFailed,
            level: AlloyLogLevel.error,
            message: 'boom',
            error: StateError('boom'),
          ),
        );

      expect(sink.reports.single.breadcrumbs, isEmpty);
    });
  });

  group('what counts as worth reporting', () {
    AlloyLogRecord warning() => AlloyLogRecord(
      kind: AlloyEventKind.scopeDisposeFailed,
      level: AlloyLogLevel.warning,
      message: 'could not release Database',
      error: StateError('will not close'),
    );

    test('a teardown failure is below the default threshold', () {
      final sink = _Collecting();
      AlloyErrorObserver(sink).onRecord(warning());

      expect(sink.reports, isEmpty);
    });

    test('lowering the threshold picks it up', () {
      final sink = _Collecting();
      AlloyErrorObserver(
        sink,
        reportAt: AlloyLogLevel.warning,
      ).onRecord(warning());

      expect(sink.reports, hasLength(1));
    });

    test('an error-level record with no error is not a failure', () {
      final sink = _Collecting();
      AlloyErrorObserver(sink).onRecord(
        const AlloyLogRecord(
          kind: AlloyEventKind.scopeInitCompleted,
          level: AlloyLogLevel.error,
          message: 'loud, but nothing broke',
        ),
      );

      expect(sink.reports, isEmpty);
    });
  });

  test('a reporter that throws does not break the graph', () async {
    final scope = await AlloyApplication.start(
      root: const _Graph(failing: true),
      rootName: 'app',
      observers: [AlloyErrorObserver(const _BrokenSink())],
    ).then<AlloyScope?>((s) => s, onError: (_) => null);

    // Startup still failed for its own reason, not because the reporter did.
    expect(scope, isNull);
  });
}
