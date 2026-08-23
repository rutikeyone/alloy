import 'dart:developer' as developer;

import 'package:alloy/src/logging/alloy_log_level.dart';
import 'package:alloy/src/logging/alloy_log_record.dart';
import 'package:alloy/src/logging/alloy_log_sink.dart';

/// Writes to `dart:developer`, which the SDK ships and every Dart tool reads.
///
/// The zero-dependency default: no package to add, output shows up in the
/// IDE's debug console and in DevTools' logging view. Reach for an adapter
/// when you want your app's own logger to own the records instead.
final class AlloyDeveloperLogSink implements AlloyLogSink {
  /// Logs under [loggerName].
  const AlloyDeveloperLogSink({this.loggerName = 'alloy'});

  /// The name records are filed under.
  final String loggerName;

  @override
  void write(AlloyLogRecord record) => developer.log(
    record.message,
    name: loggerName,
    level: _levels[record.level]!,
    error: record.error,
    stackTrace: record.stackTrace,
  );

  /// Mapped onto `package:logging`'s numbering, which `dart:developer`
  /// documents as the scale it expects.
  static const _levels = {
    AlloyLogLevel.trace: 300,
    AlloyLogLevel.debug: 500,
    AlloyLogLevel.info: 800,
    AlloyLogLevel.warning: 900,
    AlloyLogLevel.error: 1000,
  };
}
