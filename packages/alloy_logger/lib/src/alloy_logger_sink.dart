import 'package:alloy/alloy.dart';
import 'package:logger/logger.dart' as pretty;

/// Writes Alloy's log records to a `package:logger` logger.
///
/// ```dart
/// final scope = await AlloyApplication.start(
///   root: const AppScope(),
///   observers: [AlloyLogObserver(AlloyLoggerSink())],
/// );
/// ```
///
/// Unlike `package:logging`, this one prints by itself — the default `Logger`
/// comes with a console output and the boxed `PrettyPrinter`.
final class AlloyLoggerSink implements AlloyLogSink {
  /// Writes to [logger], or to a default one.
  AlloyLoggerSink({pretty.Logger? logger})
    : _logger = logger ?? pretty.Logger();

  final pretty.Logger _logger;

  /// The logger records are written to.
  pretty.Logger get logger => _logger;

  @override
  void write(AlloyLogRecord record) => _logger.log(
    levelOf(record.level),
    record.message,
    error: record.error,
    stackTrace: record.stackTrace,
  );

  /// Maps an Alloy level onto `package:logger`'s enum.
  ///
  /// Every value maps to a real level: `Logger.log` throws `ArgumentError` on
  /// `all`, `off` and `nothing`, so none of those may appear here.
  static pretty.Level levelOf(AlloyLogLevel level) => switch (level) {
    AlloyLogLevel.trace => pretty.Level.trace,
    AlloyLogLevel.debug => pretty.Level.debug,
    AlloyLogLevel.info => pretty.Level.info,
    AlloyLogLevel.warning => pretty.Level.warning,
    AlloyLogLevel.error => pretty.Level.error,
  };
}
