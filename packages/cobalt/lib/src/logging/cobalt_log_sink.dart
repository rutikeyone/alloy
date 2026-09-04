import 'package:cobalt/src/logging/cobalt_log_record.dart';

/// Where formatted Cobalt log records go.
///
/// Most of the time you do not need to implement this. [CobaltLogSink.from]
/// takes a callback, which is enough to reach any logger ever written:
///
/// ```dart
/// // loggy
/// CobaltLogSink.from((r) => logDebug(r.message));
///
/// // fimber
/// CobaltLogSink.from((r) => Fimber.d(r.message, ex: r.error));
///
/// // sentry — failures only
/// CobaltLogSink.from((r) {
///   if (r.error != null) Sentry.captureException(r.error, stackTrace: r.stackTrace);
/// });
/// ```
///
/// Cobalt ships `CobaltDeveloperLogSink` and `CobaltPrintLogSink` with no
/// dependencies, and the `cobalt_logging` / `cobalt_logger` packages for the two
/// loggers whose setup is worth a package. Everything else is a one-liner.
abstract interface class CobaltLogSink {
  /// Writes each record through [write].
  ///
  /// The shortest way to connect a logger Cobalt knows nothing about.
  const factory CobaltLogSink.from(
    void Function(CobaltLogRecord record) write,
  ) = _CallbackLogSink;

  /// Writes [record].
  ///
  /// Called synchronously from inside the work being described, so it should
  /// be cheap. Throwing is safe but pointless: `CobaltLogObserver` runs inside
  /// the observer contract, which swallows exceptions.
  void write(CobaltLogRecord record);
}

final class _CallbackLogSink implements CobaltLogSink {
  const _CallbackLogSink(this._write);

  final void Function(CobaltLogRecord record) _write;

  @override
  void write(CobaltLogRecord record) => _write(record);
}
