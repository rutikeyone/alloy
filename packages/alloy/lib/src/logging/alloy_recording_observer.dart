import 'package:alloy/src/errors/alloy_dispose_failure.dart';
import 'package:alloy/src/key/alloy_key.dart';
import 'package:alloy/src/logging/alloy_log_level.dart';
import 'package:alloy/src/logging/alloy_log_record.dart';
import 'package:alloy/src/observer/alloy_event_kind.dart';
import 'package:alloy/src/observer/alloy_observer.dart';
import 'package:alloy/src/observer/alloy_scope_ref.dart';
import 'package:alloy/src/scope/alloy_registration_kind.dart';

/// Turns Alloy's events into [AlloyLogRecord]s and hands each to [onRecord].
///
/// The wording of every event lives here and only here. Two lenses read the
/// same stream — one writes lines, one collects failures with the events that
/// led to them — and if each carried its own copy of these twelve mappings the
/// two would drift apart on the first reworded sentence.
///
/// Deliberately stateless, so a subclass that needs no state of its own can
/// still be `const`.
abstract base class AlloyRecordingObserver extends AlloyObserver {
  /// Creates the base.
  const AlloyRecordingObserver();

  /// Receives every event, already turned into a record.
  void onRecord(AlloyLogRecord record);

  void _emit(
    AlloyEventKind kind,
    AlloyLogLevel level,
    String message, {
    AlloyScopeRef? scope,
    AlloyKey? key,
    AlloyRegistrationKind? registrationKind,
    bool? retained,
    Object? error,
    StackTrace? stackTrace,
  }) => onRecord(
    AlloyLogRecord(
      kind: kind,
      level: level,
      message: message,
      scope: scope,
      key: key,
      registrationKind: registrationKind,
      retained: retained,
      error: error,
      stackTrace: stackTrace,
    ),
  );

  @override
  void onScopePushed(AlloyScopeRef scope) => _emit(
    AlloyEventKind.scopePushed,
    AlloyLogLevel.debug,
    'scope "$scope" pushed',
    scope: scope,
  );

  @override
  void onScopeInitStarted(AlloyScopeRef scope, int levels) => _emit(
    AlloyEventKind.scopeInitStarted,
    AlloyLogLevel.debug,
    'scope "$scope" initializing, $levels level(s)',
    scope: scope,
  );

  @override
  void onScopeInitCompleted(AlloyScopeRef scope, Duration took) => _emit(
    AlloyEventKind.scopeInitCompleted,
    AlloyLogLevel.info,
    'scope "$scope" ready in ${took.inMilliseconds}ms',
    scope: scope,
  );

  @override
  void onScopeInitFailed(
    AlloyScopeRef scope,
    Object error,
    StackTrace stackTrace,
  ) => _emit(
    AlloyEventKind.scopeInitFailed,
    AlloyLogLevel.error,
    'scope "$scope" failed to initialize',
    scope: scope,
    error: error,
    stackTrace: stackTrace,
  );

  @override
  void onInstanceCreated(
    AlloyScopeRef scope,
    AlloyKey key, {
    required AlloyRegistrationKind kind,
    required bool retained,
  }) => _emit(
    AlloyEventKind.instanceCreated,
    AlloyLogLevel.trace,
    retained
        ? 'built $key in "$scope" as ${kind.name}'
        : 'built $key in "$scope" as ${kind.name}, not retained',
    scope: scope,
    key: key,
    registrationKind: kind,
    retained: retained,
  );

  @override
  void onInstanceDisposed(AlloyScopeRef scope, String label) => _emit(
    AlloyEventKind.instanceDisposed,
    AlloyLogLevel.trace,
    'released $label in "$scope"',
    scope: scope,
  );

  @override
  void onScopeDisposeStarted(AlloyScopeRef scope) => _emit(
    AlloyEventKind.scopeDisposeStarted,
    AlloyLogLevel.debug,
    'scope "$scope" disposing',
    scope: scope,
  );

  @override
  void onScopeDisposed(
    AlloyScopeRef scope,
    Duration took,
    List<AlloyDisposeFailure> failures,
  ) {
    if (failures.isEmpty) {
      _emit(
        AlloyEventKind.scopeDisposed,
        AlloyLogLevel.debug,
        'scope "$scope" disposed in ${took.inMilliseconds}ms',
        scope: scope,
      );
      return;
    }
    // One record per failure, not one for the lot: each carries its own error
    // and stack trace, and a destination that groups by exception would
    // otherwise see them merged into a single unrelated blob.
    for (final failure in failures) {
      _emit(
        AlloyEventKind.scopeDisposeFailed,
        AlloyLogLevel.warning,
        'scope "$scope" could not release ${failure.label}',
        scope: scope,
        error: failure.error,
        stackTrace: failure.stackTrace,
      );
    }
  }

  @override
  void onBootstrapStepStarted(String step) => _emit(
    AlloyEventKind.bootstrapStepStarted,
    AlloyLogLevel.debug,
    'bootstrap "$step" started',
  );

  @override
  void onBootstrapStepCompleted(String step, Duration took) => _emit(
    AlloyEventKind.bootstrapStepCompleted,
    AlloyLogLevel.info,
    'bootstrap "$step" done in ${took.inMilliseconds}ms',
  );

  @override
  void onBootstrapStepFailed(
    String step,
    Object error,
    StackTrace stackTrace,
  ) => _emit(
    AlloyEventKind.bootstrapStepFailed,
    AlloyLogLevel.error,
    'bootstrap "$step" failed',
    error: error,
    stackTrace: stackTrace,
  );

  @override
  void onBootstrapStepReleaseFailed(
    String step,
    Object error,
    StackTrace stackTrace,
  ) => _emit(
    AlloyEventKind.bootstrapStepReleaseFailed,
    AlloyLogLevel.warning,
    'bootstrap "$step" could not be released while rolling startup back',
    error: error,
    stackTrace: stackTrace,
  );
}
