import 'dart:async';

import 'package:alloy/alloy.dart';
import 'package:alloy_test/alloy_test.dart';
import 'package:test/test.dart';

AlloyLogRecord _record(AlloyLogLevel level) => AlloyLogRecord(
  kind: AlloyEventKind.scopePushed,
  level: level,
  message: 'scope "app" pushed',
);

void main() {
  /// Both of these are what the documentation tells you to reach for first,
  /// and coverage found neither of them executed by a test.
  group('the sinks Alloy ships', () {
    test('the developer sink has a level for every level there is', () {
      const sink = AlloyDeveloperLogSink();

      for (final level in AlloyLogLevel.values) {
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
      const sink = AlloyDeveloperLogSink(loggerName: 'graph');

      expect(
        () => sink.write(
          AlloyLogRecord(
            kind: AlloyEventKind.scopeDisposeFailed,
            level: AlloyLogLevel.error,
            message: 'teardown failed',
            error: StateError('closed twice'),
            stackTrace: StackTrace.current,
          ),
        ),
        returnsNormally,
      );
    });

    test('the print sink writes the record and its trace', () {
      const sink = AlloyPrintLogSink();
      final printed = <String>[];

      runZoned(
        () {
          sink.write(
            AlloyLogRecord(
              kind: AlloyEventKind.scopeInitFailed,
              level: AlloyLogLevel.error,
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
      final reports = <AlloyErrorReport>[];
      final sink = AlloyErrorSink.from(reports.add);

      final report = AlloyErrorReport(
        failure: AlloyLogRecord(
          kind: AlloyEventKind.scopeInitFailed,
          level: AlloyLogLevel.error,
          message: 'init failed',
          error: StateError('nope'),
        ),
        breadcrumbs: [
          AlloyLogRecord(
            kind: AlloyEventKind.scopePushed,
            level: AlloyLogLevel.debug,
            message: 'scope "app" pushed',
          ),
        ],
      );

      sink.report(report);

      expect(reports.single.failure.message, 'init failed');
      expect(reports.single.breadcrumbs, hasLength(1));
    });

    test('reaches an observer end to end', () async {
      final reports = <AlloyErrorReport>[];
      final scope = alloyTestRoot(
        name: 'app',
        observers: [AlloyErrorObserver(AlloyErrorSink.from(reports.add))],
      )..registerAsyncSingleton<Object>(const _Exploding());

      await expectLater(scope.init(), throwsA(isA<StateError>()));

      expect(reports, isNotEmpty);
      expect(reports.first.failure.kind, AlloyEventKind.scopeInitFailed);
    });
  });
}

final class _Exploding implements AlloyAsyncFactory<Object> {
  const _Exploding();

  @override
  Future<Object> create(AlloyResolver resolver) async =>
      throw StateError('nope');
}
