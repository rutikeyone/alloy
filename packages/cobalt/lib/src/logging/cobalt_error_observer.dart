import 'dart:collection';

import 'package:cobalt/src/logging/cobalt_error_report.dart';
import 'package:cobalt/src/logging/cobalt_error_sink.dart';
import 'package:cobalt/src/logging/cobalt_log_level.dart';
import 'package:cobalt/src/logging/cobalt_log_record.dart';
import 'package:cobalt/src/logging/cobalt_recording_observer.dart';

/// Reports what the graph could not do, with the events that led up to it.
///
/// ```dart
/// final scope = await CobaltApplication.start(
///   root: const AppScope(),
///   observers: [
///     CobaltErrorObserver(
///       CobaltErrorSink.from((r) => Sentry.captureException(r.error,
///           stackTrace: r.stackTrace)),
///     ),
///   ],
/// );
/// ```
///
/// Reports only what Cobalt itself knows went wrong: an initializer that threw,
/// a bootstrap step that failed, a teardown that could not finish. There is no
/// method for reporting an arbitrary error, because this is not a general
/// error channel — the reporter you are already using is that.
final class CobaltErrorObserver extends CobaltRecordingObserver {
  /// Sends failures to [sink], each carrying up to [breadcrumbs] earlier
  /// events.
  CobaltErrorObserver(
    this.sink, {
    this.breadcrumbs = 20,
    this.reportAt = CobaltLogLevel.error,
  }) : assert(breadcrumbs >= 0, 'a negative trail is not a trail');

  /// Where failures go.
  final CobaltErrorSink sink;

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
  final CobaltLogLevel reportAt;

  final Queue<CobaltLogRecord> _trail = Queue<CobaltLogRecord>();

  @override
  void onRecord(CobaltLogRecord record) {
    if (record.level.index >= reportAt.index && record.isFailure) {
      sink.report(
        CobaltErrorReport(
          failure: record,
          breadcrumbs: List.unmodifiable(_trail),
        ),
      );
    }
    _remember(record);
  }

  /// A ring, so a long-running app cannot grow this without bound.
  void _remember(CobaltLogRecord record) {
    if (breadcrumbs == 0) return;
    if (_trail.length == breadcrumbs) _trail.removeFirst();
    _trail.addLast(record);
  }
}
