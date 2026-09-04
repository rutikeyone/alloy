import 'package:cobalt/src/logging/cobalt_log_record.dart';
import 'package:cobalt/src/logging/cobalt_log_sink.dart';

/// Writes every record to several sinks.
///
/// The production shape: a console logger to read during development and a
/// crash reporter that only cares about failures.
///
/// ```dart
/// CobaltLogObserver(
///   const CobaltMultiSink([
///     CobaltDeveloperLogSink(),
///     _CrashReporterSink(),
///   ]),
/// )
/// ```
///
/// A sink that throws does not stop the others. One broken destination
/// silencing every working one is the failure mode this exists to avoid.
final class CobaltMultiSink implements CobaltLogSink {
  /// Fans records out to [sinks], in order.
  const CobaltMultiSink(this.sinks);

  /// Where records go.
  final List<CobaltLogSink> sinks;

  @override
  void write(CobaltLogRecord record) {
    for (final sink in sinks) {
      try {
        sink.write(record);
      } catch (_) {
        // One destination failing must not cost the others their record.
      }
    }
  }
}
