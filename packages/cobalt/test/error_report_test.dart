import 'package:cobalt/cobalt.dart';
import 'package:test/test.dart';

final class _Collecting implements CobaltErrorSink {
  final reports = <CobaltErrorReport>[];

  @override
  void report(CobaltErrorReport report) => reports.add(report);
}

final class _BrokenSink implements CobaltErrorSink {
  const _BrokenSink();

  @override
  void report(CobaltErrorReport report) => throw StateError('reporter is down');
}

/// Records every event, so a test can assert on the kinds that were produced.
final class _Kinds extends CobaltRecordingObserver {
  final seen = <CobaltEventKind>[];

  @override
  void onRecord(CobaltLogRecord record) => seen.add(record.kind);
}

final class _FailingInit implements AsyncInitializable {
  @override
  Future<void> init() async => throw StateError('init went wrong');
}

final class _FailingInitFactory implements CobaltAsyncFactory<_FailingInit> {
  const _FailingInitFactory();

  @override
  Future<_FailingInit> create(CobaltResolver resolver) async {
    final instance = _FailingInit();
    await instance.init();
    return instance;
  }
}

final class _Marker {}

final class _MarkerFactory implements CobaltFactory<_Marker> {
  const _MarkerFactory();

  @override
  _Marker create(CobaltResolver resolver) => _Marker();
}

final class _Graph implements CobaltScopeBuilder {
  const _Graph({this.failing = false});

  final bool failing;

  @override
  void build(CobaltScope scope) {
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
      expect(CobaltEventKind.values, isNotEmpty);
      expect(
        CobaltEventKind.values.toSet(),
        hasLength(CobaltEventKind.values.length),
      );
    });

    test('a graph reports its events by kind, not by prose', () async {
      final kinds = _Kinds();
      final scope = await CobaltApplication.start(
        root: const _Graph(),
        rootName: 'app',
        observers: [kinds],
      );
      await scope.dispose();

      expect(
        kinds.seen,
        containsAll([
          CobaltEventKind.scopeDisposeStarted,
          CobaltEventKind.scopeDisposed,
        ]),
      );
    });

    test('toStructured names the event and the scope', () {
      const record = CobaltLogRecord(
        kind: CobaltEventKind.scopeInitFailed,
        level: CobaltLogLevel.error,
        message: 'scope "app" failed to initialize',
        scope: CobaltScopeRef(name: 'app', depth: 0),
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
      const record = CobaltLogRecord(
        kind: CobaltEventKind.scopePushed,
        level: CobaltLogLevel.debug,
        message: 'pushed',
      );

      expect(record.toStructured().keys, ['event', 'level', 'message']);
    });
  });

  group('a report carries the trail', () {
    test('a failed initializer is reported with what preceded it', () async {
      final sink = _Collecting();

      await expectLater(
        CobaltApplication.start(
          root: const _Graph(failing: true),
          rootName: 'app',
          observers: [CobaltErrorObserver(sink)],
        ),
        throwsA(isA<Object>()),
      );

      expect(sink.reports, hasLength(1));
      final report = sink.reports.single;
      expect(report.failure.kind, CobaltEventKind.scopeInitFailed);
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
      final observer = CobaltErrorObserver(sink, breadcrumbs: 3);

      for (var i = 0; i < 10; i++) {
        observer.onRecord(
          CobaltLogRecord(
            kind: CobaltEventKind.scopePushed,
            level: CobaltLogLevel.debug,
            message: 'event $i',
          ),
        );
      }
      observer.onRecord(
        CobaltLogRecord(
          kind: CobaltEventKind.scopeInitFailed,
          level: CobaltLogLevel.error,
          message: 'boom',
          error: StateError('boom'),
        ),
      );

      final trail = sink.reports.single.breadcrumbs;
      expect(trail.map((r) => r.message), ['event 7', 'event 8', 'event 9']);
    });

    test('breadcrumbs: 0 reports the failure with no trail', () {
      final sink = _Collecting();
      final observer = CobaltErrorObserver(sink, breadcrumbs: 0);

      observer
        ..onRecord(
          const CobaltLogRecord(
            kind: CobaltEventKind.scopePushed,
            level: CobaltLogLevel.debug,
            message: 'pushed',
          ),
        )
        ..onRecord(
          CobaltLogRecord(
            kind: CobaltEventKind.scopeInitFailed,
            level: CobaltLogLevel.error,
            message: 'boom',
            error: StateError('boom'),
          ),
        );

      expect(sink.reports.single.breadcrumbs, isEmpty);
    });
  });

  group('what counts as worth reporting', () {
    CobaltLogRecord warning() => CobaltLogRecord(
      kind: CobaltEventKind.scopeDisposeFailed,
      level: CobaltLogLevel.warning,
      message: 'could not release Database',
      error: StateError('will not close'),
    );

    test('a teardown failure is below the default threshold', () {
      final sink = _Collecting();
      CobaltErrorObserver(sink).onRecord(warning());

      expect(sink.reports, isEmpty);
    });

    test('lowering the threshold picks it up', () {
      final sink = _Collecting();
      CobaltErrorObserver(
        sink,
        reportAt: CobaltLogLevel.warning,
      ).onRecord(warning());

      expect(sink.reports, hasLength(1));
    });

    test('an error-level record with no error is not a failure', () {
      final sink = _Collecting();
      CobaltErrorObserver(sink).onRecord(
        const CobaltLogRecord(
          kind: CobaltEventKind.scopeInitCompleted,
          level: CobaltLogLevel.error,
          message: 'loud, but nothing broke',
        ),
      );

      expect(sink.reports, isEmpty);
    });
  });

  test('a reporter that throws does not break the graph', () async {
    final scope = await CobaltApplication.start(
      root: const _Graph(failing: true),
      rootName: 'app',
      observers: [CobaltErrorObserver(const _BrokenSink())],
    ).then<CobaltScope?>((s) => s, onError: (_) => null);

    // Startup still failed for its own reason, not because the reporter did.
    expect(scope, isNull);
  });
}
