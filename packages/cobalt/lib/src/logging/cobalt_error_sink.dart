import 'package:cobalt/src/logging/cobalt_error_report.dart';

/// Where failures go.
///
/// Separate from `CobaltLogSink` because the two have different contracts: a
/// log sink is handed a stream of lines and is expected to be cheap, while
/// this is handed discrete incidents that usually cost a network call and a
/// quota.
abstract interface class CobaltErrorSink {
  /// Creates a sink from a callback.
  ///
  /// The whole of an adapter, for a reporter Cobalt ships nothing for:
  ///
  /// ```dart
  /// CobaltErrorSink.from(
  ///   (report) => Sentry.captureException(
  ///     report.error,
  ///     stackTrace: report.stackTrace,
  ///     withScope: (scope) => scope.setContexts('cobalt', report.toStructured()),
  ///   ),
  /// )
  /// ```
  const factory CobaltErrorSink.from(void Function(CobaltErrorReport) report) =
      _CallbackErrorSink;

  /// Reports one failure.
  void report(CobaltErrorReport report);
}

final class _CallbackErrorSink implements CobaltErrorSink {
  const _CallbackErrorSink(this._report);

  final void Function(CobaltErrorReport) _report;

  @override
  void report(CobaltErrorReport report) => _report(report);
}
