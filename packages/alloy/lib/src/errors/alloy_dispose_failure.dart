import 'dart:async';

import 'package:alloy/src/errors/alloy_dispose_stage.dart';
import 'package:meta/meta.dart';

/// One step of teardown that did not complete.
@immutable
final class AlloyDisposeFailure {
  /// Records that [label] failed with [error] during [stage].
  const AlloyDisposeFailure(
    this.label,
    this.error,
    this.stackTrace, {
    this.stage = AlloyDisposeStage.releasing,
  });

  /// What was being torn down, such as `EventLog.dispose`, `init`, or
  /// `session/CacheStore.dispose` for a step inside a child scope.
  final String label;

  /// Why it did not complete. A [TimeoutException] means the step ran past the
  /// deadline and was abandoned rather than having failed on its own.
  final Object error;

  /// Where [error] came from.
  final StackTrace stackTrace;

  /// Which part of teardown this came from.
  final AlloyDisposeStage stage;

  /// Whether this step ran out of time instead of throwing.
  bool get isTimeout => error is TimeoutException;

  /// Whether this is an initialization failure rather than a teardown failure.
  ///
  /// An initialization that *threw* never makes `dispose` throw by itself —
  /// the error belongs to whoever called `init()` and was already delivered
  /// there, so it appears only as context saying the scope was never fully
  /// built. An initialization that ran past the deadline is different: waiting
  /// for it is teardown's own work, so [isTimeout] entries here are reported
  /// like any other overrun.
  bool get isInitFailure => stage == AlloyDisposeStage.awaitingInit;

  @override
  String toString() => switch (stage) {
    AlloyDisposeStage.awaitingInit when !isTimeout =>
      '$label — initialization failed before teardown started: $error',
    _ => '$label — $error',
  };
}
