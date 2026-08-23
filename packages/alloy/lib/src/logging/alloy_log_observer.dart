import 'package:alloy/src/errors/alloy_dispose_failure.dart';
import 'package:alloy/src/key/alloy_key.dart';
import 'package:alloy/src/logging/alloy_log_level.dart';
import 'package:alloy/src/logging/alloy_log_record.dart';
import 'package:alloy/src/logging/alloy_log_sink.dart';
import 'package:alloy/src/observer/alloy_observer.dart';
import 'package:alloy/src/observer/alloy_scope_ref.dart';

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
final class AlloyLogObserver extends AlloyObserver {
  /// Sends records to [sink], keeping those at [minimumLevel] or above.
  const AlloyLogObserver(this.sink, {this.minimumLevel = AlloyLogLevel.debug});

  /// Where records go.
  final AlloyLogSink sink;

  /// The quietest level that still reaches [sink].
  final AlloyLogLevel minimumLevel;

  void _write(
    AlloyLogLevel level,
    String message, {
    AlloyScopeRef? scope,
    AlloyKey? key,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minimumLevel.index) return;
    sink.write(
      AlloyLogRecord(
        level: level,
        message: message,
        scope: scope,
        key: key,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  void onScopePushed(AlloyScopeRef scope) =>
      _write(AlloyLogLevel.debug, 'scope "$scope" pushed', scope: scope);

  @override
  void onScopeInitStarted(AlloyScopeRef scope, int levels) => _write(
    AlloyLogLevel.debug,
    'scope "$scope" initializing, $levels level(s)',
    scope: scope,
  );

  @override
  void onScopeInitCompleted(AlloyScopeRef scope, Duration took) => _write(
    AlloyLogLevel.info,
    'scope "$scope" ready in ${took.inMilliseconds}ms',
    scope: scope,
  );

  @override
  void onScopeInitFailed(
    AlloyScopeRef scope,
    Object error,
    StackTrace stackTrace,
  ) => _write(
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
    required bool retained,
  }) => _write(
    AlloyLogLevel.trace,
    retained
        ? 'built $key in "$scope"'
        : 'built $key in "$scope", not retained',
    scope: scope,
    key: key,
  );

  @override
  void onInstanceDisposed(AlloyScopeRef scope, String label) =>
      _write(AlloyLogLevel.trace, 'released $label in "$scope"', scope: scope);

  @override
  void onScopeDisposeStarted(AlloyScopeRef scope) =>
      _write(AlloyLogLevel.debug, 'scope "$scope" disposing', scope: scope);

  @override
  void onScopeDisposed(
    AlloyScopeRef scope,
    Duration took,
    List<AlloyDisposeFailure> failures,
  ) {
    if (failures.isEmpty) {
      _write(
        AlloyLogLevel.debug,
        'scope "$scope" disposed in ${took.inMilliseconds}ms',
        scope: scope,
      );
      return;
    }
    for (final failure in failures) {
      _write(
        AlloyLogLevel.warning,
        'scope "$scope" could not release ${failure.label}',
        scope: scope,
        error: failure.error,
        stackTrace: failure.stackTrace,
      );
    }
  }

  @override
  void onBootstrapStepStarted(String step) =>
      _write(AlloyLogLevel.debug, 'bootstrap "$step" started');

  @override
  void onBootstrapStepCompleted(String step, Duration took) => _write(
    AlloyLogLevel.info,
    'bootstrap "$step" done in ${took.inMilliseconds}ms',
  );

  @override
  void onBootstrapStepFailed(
    String step,
    Object error,
    StackTrace stackTrace,
  ) => _write(
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
  ) => _write(
    AlloyLogLevel.warning,
    'bootstrap "$step" could not be released while rolling startup back',
    error: error,
    stackTrace: stackTrace,
  );
}
