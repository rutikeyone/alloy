import 'package:alloy/src/key/alloy_key.dart';
import 'package:alloy/src/logging/alloy_log_level.dart';
import 'package:alloy/src/observer/alloy_scope_ref.dart';
import 'package:meta/meta.dart';

/// One line an [AlloyLogSink] is asked to write.
///
/// [message] is already formatted, but [scope], [key] and [error] are kept
/// alongside it so a sink that can do better than a string — attaching the
/// scope as structured data, colouring by kind — still can.
@immutable
final class AlloyLogRecord {
  /// Creates a record.
  const AlloyLogRecord({
    required this.level,
    required this.message,
    this.scope,
    this.key,
    this.error,
    this.stackTrace,
  });

  /// How much this record matters.
  final AlloyLogLevel level;

  /// The formatted message.
  final String message;

  /// The scope the event happened in, when there is one.
  final AlloyScopeRef? scope;

  /// The registration the event was about, when there is one.
  final AlloyKey? key;

  /// The failure, for warnings and errors.
  final Object? error;

  /// Where [error] came from.
  final StackTrace? stackTrace;

  @override
  String toString() => error == null ? message : '$message: $error';
}
