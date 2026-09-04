import 'dart:developer' as developer;

import 'package:cobalt/src/logging/cobalt_log_level.dart';
import 'package:cobalt/src/logging/cobalt_log_record.dart';
import 'package:cobalt/src/logging/cobalt_log_sink.dart';

/// Writes to `dart:developer`, which the SDK ships and every Dart tool reads.
///
/// The zero-dependency default: no package to add, output shows up in the
/// IDE's debug console and in DevTools' logging view. Reach for an adapter
/// when you want your app's own logger to own the records instead.
final class CobaltDeveloperLogSink implements CobaltLogSink {
  /// Logs under [loggerName].
  const CobaltDeveloperLogSink({this.loggerName = 'cobalt'});

  /// The name records are filed under.
  final String loggerName;

  @override
  void write(CobaltLogRecord record) => developer.log(
    record.message,
    name: loggerName,
    level: _levels[record.level]!,
    error: record.error,
    stackTrace: record.stackTrace,
  );

  /// Mapped onto `package:logging`'s numbering, which `dart:developer`
  /// documents as the scale it expects.
  static const _levels = {
    CobaltLogLevel.trace: 300,
    CobaltLogLevel.debug: 500,
    CobaltLogLevel.info: 800,
    CobaltLogLevel.warning: 900,
    CobaltLogLevel.error: 1000,
  };
}
