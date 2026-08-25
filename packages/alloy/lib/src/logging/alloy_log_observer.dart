import 'package:alloy/src/logging/alloy_log_level.dart';
import 'package:alloy/src/logging/alloy_log_record.dart';
import 'package:alloy/src/logging/alloy_log_sink.dart';
import 'package:alloy/src/logging/alloy_recording_observer.dart';

/// Turns Alloy's events into log records and hands them to a sink.
///
/// This is the shortest path from "I want to see what the graph is doing" to
/// output: pick a sink, pass one of these as an observer, done.
///
/// ```dart
/// final scope = await AlloyApplication.start(
///   root: const AppScope(),
///   observers: [AlloyLogObserver(const AlloyDeveloperLogSink())],
/// );
/// ```
///
/// [minimumLevel] drops anything quieter. The default keeps per-instance
/// records out, since a large graph builds a lot of them.
final class AlloyLogObserver extends AlloyRecordingObserver {
  /// Sends records to [sink], keeping those at [minimumLevel] or above.
  const AlloyLogObserver(this.sink, {this.minimumLevel = AlloyLogLevel.debug});

  /// Where records go.
  final AlloyLogSink sink;

  /// The quietest level that still reaches [sink].
  final AlloyLogLevel minimumLevel;

  @override
  void onRecord(AlloyLogRecord record) {
    if (record.level.index < minimumLevel.index) return;
    sink.write(record);
  }
}
