import 'package:alloy/src/errors/alloy_dispose_failure.dart';
import 'package:alloy/src/key/alloy_key.dart';
import 'package:alloy/src/scope/alloy_registration_kind.dart';
import 'package:alloy/src/observer/alloy_scope_ref.dart';

/// Watches what a scope tree does.
///
/// Every method does nothing by default, so an observer overrides only what it
/// cares about and a new event added later does not break it. Pass observers
/// to `AlloyScope.root` or `AlloyApplication.start`; a child scope inherits
/// its parent's observers.
///
/// Callbacks are invoked synchronously, in the middle of the work they
/// describe. Keep them cheap, and do not resolve, register or dispose from
/// inside one — which is why they receive [AlloyScopeRef] and [AlloyKey]
/// rather than live objects.
///
/// An exception thrown from a callback is caught and ignored: watching must
/// not be able to break the graph it is watching.
///
/// Resolution itself is not reported. A cache hit is the hot path, and an
/// event per `get` would be noise; what is worth seeing is an instance being
/// *built*, which [onInstanceCreated] covers.
abstract base class AlloyObserver {
  /// Creates an observer.
  const AlloyObserver();

  /// A child scope was pushed.
  void onScopePushed(AlloyScopeRef scope) {}

  /// `init()` started, with [levels] levels of async singletons to build.
  ///
  /// Not called when the scope has no async registrations.
  void onScopeInitStarted(AlloyScopeRef scope, int levels) {}

  /// Every async singleton finished building.
  void onScopeInitCompleted(AlloyScopeRef scope, Duration took) {}

  /// `init()` failed. The error is also thrown to whoever called `init()`.
  void onScopeInitFailed(
    AlloyScopeRef scope,
    Object error,
    StackTrace stackTrace,
  ) {}

  /// An instance was constructed.
  ///
  /// [kind] is the registration it came from, and [retained] whether the scope
  /// will dispose it — false for transients and parameterized factories, whose
  /// caller owns them. Both are reported because they answer different
  /// questions: one is how long the thing lives, the other is who closes it.
  ///
  /// An eager singleton never reaches here. It is built by whoever called
  /// `registerSingleton` and handed over already made, so the scope has
  /// nothing to report constructing.
  void onInstanceCreated(
    AlloyScopeRef scope,
    AlloyKey key, {
    required AlloyRegistrationKind kind,
    required bool retained,
  }) {}

  /// An owned instance was disposed without error. [label] is its type.
  void onInstanceDisposed(AlloyScopeRef scope, String label) {}

  /// Teardown began. The scope is already unusable at this point.
  void onScopeDisposeStarted(AlloyScopeRef scope) {}

  /// Teardown finished, always — [failures] is what it could not release.
  void onScopeDisposed(
    AlloyScopeRef scope,
    Duration took,
    List<AlloyDisposeFailure> failures,
  ) {}

  /// A bootstrap step is about to run.
  void onBootstrapStepStarted(String step) {}

  /// A bootstrap step finished.
  void onBootstrapStepCompleted(String step, Duration took) {}

  /// A bootstrap step threw. Startup is aborted and earlier steps released.
  void onBootstrapStepFailed(
    String step,
    Object error,
    StackTrace stackTrace,
  ) {}

  /// Releasing an already-completed step failed while rolling startup back.
  ///
  /// This one exists because the alternative is silence: the rollback cannot
  /// report through `AlloyBootstrapError` without masking the failure that
  /// caused it, so before observers existed the error was dropped.
  void onBootstrapStepReleaseFailed(
    String step,
    Object error,
    StackTrace stackTrace,
  ) {}
}
