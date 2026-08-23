import 'package:alloy/src/logging/alloy_log_record.dart';
import 'package:alloy/src/logging/alloy_log_sink.dart';

/// Writes to stdout with `print`.
///
/// For a CLI, a test, or a first look at what the graph is doing. In a Flutter
/// app prefer `AlloyDeveloperLogSink`, which is equally dependency-free and
/// shows up in DevTools' logging view with a level attached.
final class AlloyPrintLogSink implements AlloyLogSink {
  /// Prefixes every line with [prefix].
  const AlloyPrintLogSink({this.prefix = 'alloy'});

  /// What each line starts with.
  final String prefix;

  @override
  void write(AlloyLogRecord record) {
    // ignore: avoid_print — printing is this class's entire purpose.
    print('[$prefix] ${record.level.name.toUpperCase()} $record');
    final stackTrace = record.stackTrace;
    if (stackTrace != null) {
      // ignore: avoid_print
      print(stackTrace);
    }
  }
}
