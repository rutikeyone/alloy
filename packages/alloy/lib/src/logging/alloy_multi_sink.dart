import 'package:alloy/src/logging/alloy_log_record.dart';
import 'package:alloy/src/logging/alloy_log_sink.dart';

/// Writes every record to several sinks.
///
/// The production shape: a console logger to read during development and a
/// crash reporter that only cares about failures.
///
/// ```dart
/// AlloyLogObserver(
///   const AlloyMultiSink([
///     AlloyDeveloperLogSink(),
///     _CrashReporterSink(),
///   ]),
/// )
/// ```
///
/// A sink that throws does not stop the others. One broken destination
/// silencing every working one is the failure mode this exists to avoid.
final class AlloyMultiSink implements AlloyLogSink {
  /// Fans records out to [sinks], in order.
  const AlloyMultiSink(this.sinks);

  /// Where records go.
  final List<AlloyLogSink> sinks;

  @override
  void write(AlloyLogRecord record) {
    for (final sink in sinks) {
      try {
        sink.write(record);
      } catch (_) {
        // One destination failing must not cost the others their record.
      }
    }
  }
}
