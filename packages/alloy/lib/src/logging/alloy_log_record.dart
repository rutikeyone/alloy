import 'package:alloy/src/key/alloy_key.dart';
import 'package:alloy/src/logging/alloy_log_level.dart';
import 'package:alloy/src/observer/alloy_event_kind.dart';
import 'package:alloy/src/observer/alloy_scope_ref.dart';
import 'package:meta/meta.dart';

/// One line an [AlloyLogSink] is asked to write.
///
/// [message] is already formatted, but [kind], [scope], [key] and [error] are
/// kept alongside it so a sink that can do better than a string — attaching the
/// scope as structured data, colouring by kind, keying on the event — still
/// can.
@immutable
final class AlloyLogRecord {
  /// Creates a record.
  const AlloyLogRecord({
    required this.kind,
    required this.level,
    required this.message,
    this.scope,
    this.key,
    this.error,
    this.stackTrace,
  });

  /// What happened, as a value.
  ///
  /// Required rather than optional: a record without one is exactly the gap
  /// this field exists to close, and an optional field would let it back in.
  final AlloyEventKind kind;

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

  /// Whether this record is about something going wrong.
  bool get isFailure => error != null;

  /// The record as data, for a destination that takes structured input.
  ///
  /// This is the whole of a GELF or JSON sink: hand the map over and let the
  /// destination decide what to index. Keys are stable — the message is free
  /// to be reworded, these are not.
  ///
  /// Null entries are dropped rather than sent as nulls, since most
  /// destinations treat a present-but-null field as a field.
  Map<String, Object?> toStructured() => {
    'event': kind.name,
    'level': level.name,
    'message': message,
    if (scope != null) ...{
      'scope': scope!.name,
      'scope_depth': scope!.depth,
      if (scope!.parentName != null) 'scope_parent': scope!.parentName,
    },
    if (key != null) 'key': key.toString(),
    if (error != null) 'error': error.toString(),
    if (stackTrace != null) 'stack_trace': stackTrace.toString(),
  };

  @override
  String toString() => error == null ? message : '$message: $error';
}
