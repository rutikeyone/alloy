import 'package:alloy/alloy.dart';
import 'package:alloy_talker/src/alloy_talker_logs.dart';
import 'package:talker/talker.dart';

/// Reports Alloy's events to talker as typed logs.
///
/// This is an [AlloyObserver] rather than an `AlloyLogSink`, which is the
/// whole point of using talker: each kind of event becomes its own
/// [TalkerLog] with a title and a colour, so `TalkerScreen` can filter them
/// apart. A sink would flatten everything into one stream of strings.
///
/// ```dart
/// final talker = Talker();
/// final scope = await AlloyApplication.start(
///   root: const AppScope(),
///   observers: [AlloyTalkerObserver(talker)],
/// );
/// ```
///
/// Set [verbose] to see every instance the graph builds. It is off by default
/// because a real graph builds a great many, and the useful signal — scopes
/// appearing, startup finishing, things failing — drowns in it.
final class AlloyTalkerObserver extends AlloyObserver {
  /// Reports to [talker].
  const AlloyTalkerObserver(this.talker, {this.verbose = false});

  /// Where logs go.
  final Talker talker;

  /// Whether per-instance logs are emitted.
  final bool verbose;

  @override
  void onScopePushed(AlloyScopeRef scope) =>
      talker.logCustom(AlloyScopeLog('scope "$scope" pushed'));

  @override
  void onScopeInitStarted(AlloyScopeRef scope, int levels) => talker.logCustom(
    AlloyStartupLog(
      'scope "$scope" initializing, $levels level(s)',
      logLevel: LogLevel.debug,
    ),
  );

  @override
  void onScopeInitCompleted(AlloyScopeRef scope, Duration took) =>
      talker.logCustom(
        AlloyStartupLog('scope "$scope" ready in ${took.inMilliseconds}ms'),
      );

  @override
  void onScopeInitFailed(
    AlloyScopeRef scope,
    Object error,
    StackTrace stackTrace,
  ) => talker.logCustom(
    AlloyFailureLog(
      'scope "$scope" failed to initialize',
      exception: error,
      stackTrace: stackTrace,
    ),
  );

  @override
  void onInstanceCreated(
    AlloyScopeRef scope,
    AlloyKey key, {
    required AlloyRegistrationKind kind,
    required bool retained,
  }) {
    if (!verbose) return;
    talker.logCustom(
      AlloyInstanceLog(
        retained
            ? 'built $key in "$scope" as ${kind.name}'
            : 'built $key in "$scope" as ${kind.name} (loose)',
      ),
    );
  }

  @override
  void onInstanceDisposed(AlloyScopeRef scope, String label) {
    if (!verbose) return;
    talker.logCustom(AlloyInstanceLog('released $label in "$scope"'));
  }

  @override
  void onScopeDisposeStarted(AlloyScopeRef scope) =>
      talker.logCustom(AlloyScopeLog('scope "$scope" disposing'));

  @override
  void onScopeDisposed(
    AlloyScopeRef scope,
    Duration took,
    List<AlloyDisposeFailure> failures,
  ) {
    if (failures.isEmpty) {
      talker.logCustom(
        AlloyScopeLog('scope "$scope" disposed in ${took.inMilliseconds}ms'),
      );
      return;
    }
    for (final failure in failures) {
      talker.logCustom(
        AlloyFailureLog(
          'scope "$scope" could not release ${failure.label}',
          exception: failure.error,
          stackTrace: failure.stackTrace,
          logLevel: LogLevel.warning,
        ),
      );
    }
  }

  @override
  void onBootstrapStepStarted(String step) => talker.logCustom(
    AlloyStartupLog('bootstrap "$step" started', logLevel: LogLevel.debug),
  );

  @override
  void onBootstrapStepCompleted(String step, Duration took) => talker.logCustom(
    AlloyStartupLog('bootstrap "$step" done in ${took.inMilliseconds}ms'),
  );

  @override
  void onBootstrapStepFailed(
    String step,
    Object error,
    StackTrace stackTrace,
  ) => talker.logCustom(
    AlloyFailureLog(
      'bootstrap "$step" failed',
      exception: error,
      stackTrace: stackTrace,
    ),
  );

  @override
  void onBootstrapStepReleaseFailed(
    String step,
    Object error,
    StackTrace stackTrace,
  ) => talker.logCustom(
    AlloyFailureLog(
      'bootstrap "$step" could not be released while rolling startup back',
      exception: error,
      stackTrace: stackTrace,
      logLevel: LogLevel.warning,
    ),
  );
}
