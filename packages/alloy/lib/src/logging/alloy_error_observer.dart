import 'dart:collection';

import 'package:alloy/src/logging/alloy_error_report.dart';
import 'package:alloy/src/logging/alloy_error_sink.dart';
import 'package:alloy/src/logging/alloy_log_level.dart';
import 'package:alloy/src/logging/alloy_log_record.dart';
import 'package:alloy/src/logging/alloy_recording_observer.dart';

/// Reports what the graph could not do, with the events that led up to it.
///
/// ```dart
/// final scope = await AlloyApplication.start(
///   root: const AppScope(),
///   observers: [
///     AlloyErrorObserver(
///       AlloyErrorSink.from((r) => Sentry.captureException(r.error,
///           stackTrace: r.stackTrace)),
///     ),
///   ],
/// );
/// ```
///
/// Reports only what Alloy itself knows went wrong: an initializer that threw,
/// a bootstrap step that failed, a teardown that could not finish. There is no
/// method for reporting an arbitrary error, because this is not a general
/// error channel — the reporter you are already using is that.
final class AlloyErrorObserver extends AlloyRecordingObserver {
  /// Sends failures to [sink], each carrying up to [breadcrumbs] earlier
  /// events.
  AlloyErrorObserver(
    this.sink, {
    this.breadcrumbs = 20,
    this.reportAt = AlloyLogLevel.error,
  }) : assert(breadcrumbs >= 0, 'a negative trail is not a trail');

  /// Where failures go.
  final AlloyErrorSink sink;

  /// How many earlier events travel with a failure.
  ///
  /// The trail is kept whatever the level, including the per-instance records
  /// a log sink drops by default — they cost nothing until something fails,
  /// and "what was built last" is usually the useful line.
  final int breadcrumbs;

  /// The quietest level that is worth a report.
  ///
  /// `error` by default: a teardown failure arrives as a warning, and it does
  /// mean a resource leaked, but paging a paid service on every hiccup is how
  /// reports stop being read. Lower it deliberately.
  final AlloyLogLevel reportAt;

  final Queue<AlloyLogRecord> _trail = Queue<AlloyLogRecord>();

  @override
  void onRecord(AlloyLogRecord record) {
    if (record.level.index >= reportAt.index && record.isFailure) {
      sink.report(
        AlloyErrorReport(
          failure: record,
          breadcrumbs: List.unmodifiable(_trail),
        ),
      );
    }
    _remember(record);
  }

  /// A ring, so a long-running app cannot grow this without bound.
  void _remember(AlloyLogRecord record) {
    if (breadcrumbs == 0) return;
    if (_trail.length == breadcrumbs) _trail.removeFirst();
    _trail.addLast(record);
  }
}
