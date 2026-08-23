import 'package:alloy/src/logging/alloy_log_record.dart';

/// Where formatted Alloy log records go.
///
/// Most of the time you do not need to implement this. [AlloyLogSink.from]
/// takes a callback, which is enough to reach any logger ever written:
///
/// ```dart
/// // loggy
/// AlloyLogSink.from((r) => logDebug(r.message));
///
/// // fimber
/// AlloyLogSink.from((r) => Fimber.d(r.message, ex: r.error));
///
/// // sentry — failures only
/// AlloyLogSink.from((r) {
///   if (r.error != null) Sentry.captureException(r.error, stackTrace: r.stackTrace);
/// });
/// ```
///
/// Alloy ships `AlloyDeveloperLogSink` and `AlloyPrintLogSink` with no
/// dependencies, and the `alloy_logging` / `alloy_logger` packages for the two
/// loggers whose setup is worth a package. Everything else is a one-liner.
abstract interface class AlloyLogSink {
  /// Writes each record through [write].
  ///
  /// The shortest way to connect a logger Alloy knows nothing about.
  const factory AlloyLogSink.from(void Function(AlloyLogRecord record) write) =
      _CallbackLogSink;

  /// Writes [record].
  ///
  /// Called synchronously from inside the work being described, so it should
  /// be cheap. Throwing is safe but pointless: `AlloyLogObserver` runs inside
  /// the observer contract, which swallows exceptions.
  void write(AlloyLogRecord record);
}

final class _CallbackLogSink implements AlloyLogSink {
  const _CallbackLogSink(this._write);

  final void Function(AlloyLogRecord record) _write;

  @override
  void write(AlloyLogRecord record) => _write(record);
}
