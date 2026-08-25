import 'package:alloy/src/logging/alloy_error_report.dart';

/// Where failures go.
///
/// Separate from `AlloyLogSink` because the two have different contracts: a
/// log sink is handed a stream of lines and is expected to be cheap, while
/// this is handed discrete incidents that usually cost a network call and a
/// quota.
abstract interface class AlloyErrorSink {
  /// Creates a sink from a callback.
  ///
  /// The whole of an adapter, for a reporter Alloy ships nothing for:
  ///
  /// ```dart
  /// AlloyErrorSink.from(
  ///   (report) => Sentry.captureException(
  ///     report.error,
  ///     stackTrace: report.stackTrace,
  ///     withScope: (scope) => scope.setContexts('alloy', report.toStructured()),
  ///   ),
  /// )
  /// ```
  const factory AlloyErrorSink.from(void Function(AlloyErrorReport) report) =
      _CallbackErrorSink;

  /// Reports one failure.
  void report(AlloyErrorReport report);
}

final class _CallbackErrorSink implements AlloyErrorSink {
  const _CallbackErrorSink(this._report);

  final void Function(AlloyErrorReport) _report;

  @override
  void report(AlloyErrorReport report) => _report(report);
}
