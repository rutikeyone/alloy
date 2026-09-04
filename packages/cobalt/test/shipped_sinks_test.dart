import 'dart:async';

import 'package:cobalt/cobalt.dart';
import 'package:cobalt_test/cobalt_test.dart';
import 'package:test/test.dart';

CobaltLogRecord _record(CobaltLogLevel level) => CobaltLogRecord(
  kind: CobaltEventKind.scopePushed,
  level: level,
  message: 'scope "app" pushed',
);

void main() {
  /// Both of these are what the documentation tells you to reach for first,
  /// and coverage found neither of them executed by a test.
  group('the sinks Cobalt ships', () {
    test('the developer sink has a level for every level there is', () {
      const sink = CobaltDeveloperLogSink();

      for (final level in CobaltLogLevel.values) {
        expect(
          () => sink.write(_record(level)),
          returnsNormally,
          reason:
              'the mapping is read with `!`, so a level added to the enum and '
              'not to the map is a crash at the first record of that level',
        );
      }
    });

    test('the developer sink takes an error and a trace', () {
      const sink = CobaltDeveloperLogSink(loggerName: 'graph');

      expect(
        () => sink.write(
          CobaltLogRecord(
            kind: CobaltEventKind.scopeDisposeFailed,
            level: CobaltLogLevel.error,
            message: 'teardown failed',
            error: StateError('closed twice'),
            stackTrace: StackTrace.current,
          ),
        ),
        returnsNormally,
      );
    });

    test('the print sink writes the record and its trace', () {
      const sink = CobaltPrintLogSink();
      final printed = <String>[];

      runZoned(
        () {
          sink.write(
            CobaltLogRecord(
              kind: CobaltEventKind.scopeInitFailed,
              level: CobaltLogLevel.error,
              message: 'init failed',
              error: StateError('nope'),
              stackTrace: StackTrace.current,
            ),
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => printed.add(line),
        ),
      );

      expect(printed.join('\n'), contains('init failed'));
    });
  });

  group('an error sink from a callback', () {
    /// The form the README hands people for Sentry and Crashlytics.
    test('hands the report to the callback', () {
      final reports = <CobaltErrorReport>[];
      final sink = CobaltErrorSink.from(reports.add);

      final report = CobaltErrorReport(
        failure: CobaltLogRecord(
          kind: CobaltEventKind.scopeInitFailed,
          level: CobaltLogLevel.error,
          message: 'init failed',
          error: StateError('nope'),
        ),
        breadcrumbs: [
          CobaltLogRecord(
            kind: CobaltEventKind.scopePushed,
            level: CobaltLogLevel.debug,
            message: 'scope "app" pushed',
          ),
        ],
      );

      sink.report(report);

      expect(reports.single.failure.message, 'init failed');
      expect(reports.single.breadcrumbs, hasLength(1));
    });

    test('reaches an observer end to end', () async {
      final reports = <CobaltErrorReport>[];
      final scope = cobaltTestRoot(
        name: 'app',
        observers: [CobaltErrorObserver(CobaltErrorSink.from(reports.add))],
      )..registerAsyncSingleton<Object>(const _Exploding());

      await expectLater(scope.init(), throwsA(isA<StateError>()));

      expect(reports, isNotEmpty);
      expect(reports.first.failure.kind, CobaltEventKind.scopeInitFailed);
    });
  });
}

final class _Exploding implements CobaltAsyncFactory<Object> {
  const _Exploding();

  @override
  Future<Object> create(CobaltResolver resolver) async =>
      throw StateError('nope');
}
