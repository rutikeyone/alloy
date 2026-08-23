import 'package:alloy/alloy.dart';
import 'package:logging/logging.dart' as logging;

/// Writes Alloy's log records to a `package:logging` logger.
///
/// ```dart
/// final scope = await AlloyApplication.start(
///   root: const AppScope(),
///   observers: [AlloyLogObserver(AlloyLoggingSink())],
/// );
/// ```
///
/// Nothing is printed until something listens — `package:logging` is a routing
/// layer, not an output. The usual setup is
/// `Logger.root.onRecord.listen(print)` plus a `Logger.root.level`.
final class AlloyLoggingSink implements AlloyLogSink {
  /// Writes to a logger named [name], or to [logger] when one is given.
  AlloyLoggingSink({String name = 'alloy', logging.Logger? logger})
    : _logger = logger ?? logging.Logger(name);

  final logging.Logger _logger;

  /// The logger records are written to.
  logging.Logger get logger => _logger;

  @override
  void write(AlloyLogRecord record) => _logger.log(
    levelOf(record.level),
    record.message,
    record.error,
    record.stackTrace,
  );

  /// Maps an Alloy level onto `package:logging`'s scale.
  ///
  /// `trace` lands on `FINEST` rather than `FINE`, because Alloy's trace is
  /// per-instance and a graph of any size produces a lot of it.
  static logging.Level levelOf(AlloyLogLevel level) => switch (level) {
    AlloyLogLevel.trace => logging.Level.FINEST,
    AlloyLogLevel.debug => logging.Level.FINE,
    AlloyLogLevel.info => logging.Level.INFO,
    AlloyLogLevel.warning => logging.Level.WARNING,
    AlloyLogLevel.error => logging.Level.SEVERE,
  };
}
