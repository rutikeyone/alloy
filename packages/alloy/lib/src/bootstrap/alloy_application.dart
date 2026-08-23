import 'package:alloy/src/bootstrap/alloy_bootstrap_step.dart';
import 'package:alloy/src/bootstrap/alloy_scope_builder.dart';
import 'package:alloy/src/errors/alloy_bootstrap_error.dart';
import 'package:alloy/src/lifecycle/async_disposable.dart';
import 'package:alloy/src/lifecycle/disposable.dart';
import 'package:alloy/src/observer/alloy_observer.dart';
import 'package:alloy/src/scope/alloy_scope.dart';

/// Runs the two-phase startup and hands back the root scope.
///
/// Phase 0 is [AlloyBootstrapStep]s, run one after another before any
/// container exists. Phase 1 builds the root scope from an
/// [AlloyScopeBuilder] and awaits its async initializers as a graph.
final class AlloyApplication {
  const AlloyApplication._();

  /// Runs [bootstrap], assembles the root scope from [root], initializes it
  /// and returns it active.
  ///
  /// Steps that ran are adopted by the root scope before anything is
  /// registered, so a step holding a resource is disposed with the scope —
  /// and, being adopted first, disposed last, after everything that was built
  /// on top of the platform it set up.
  ///
  /// A failing bootstrap step aborts startup: later steps do not run, the
  /// container is never assembled, and the failure is rethrown as
  /// [AlloyBootstrapError] naming the step. Steps that already ran are
  /// released first, in reverse order, since there is no scope to hand them
  /// to.
  ///
  /// The caller owns the returned scope and must dispose it. In Code-Gen Mode
  /// the generated `$startAlloy()` is this call with the generated container,
  /// bootstrap list and root name already filled in.
  static Future<AlloyScope> start({
    required AlloyScopeBuilder root,
    List<AlloyBootstrapStep> bootstrap = const [],
    String rootName = 'root',
    List<AlloyObserver> observers = const [],
  }) async {
    final completed = <AlloyBootstrapStep>[];

    for (final step in bootstrap) {
      final elapsed = Stopwatch()..start();
      _notify(
        observers,
        (observer) => observer.onBootstrapStepStarted(step.name),
      );
      try {
        await step.run();
      } catch (error, stackTrace) {
        _notify(
          observers,
          (observer) =>
              observer.onBootstrapStepFailed(step.name, error, stackTrace),
        );
        await _release(completed, observers);
        throw AlloyBootstrapError(step.name, error, stackTrace);
      }
      _notify(
        observers,
        (observer) =>
            observer.onBootstrapStepCompleted(step.name, elapsed.elapsed),
      );
      completed.add(step);
    }

    final scope = AlloyScope.root(name: rootName, observers: observers);
    for (final step in completed) {
      scope.adopt(step);
    }

    root.build(scope);
    await scope.init();
    return scope;
  }

  static Future<void> _release(
    List<AlloyBootstrapStep> completed,
    List<AlloyObserver> observers,
  ) async {
    for (final step in completed.reversed) {
      try {
        if (step is AsyncDisposable) {
          await (step as AsyncDisposable).dispose();
        } else if (step is Disposable) {
          (step as Disposable).dispose();
        }
      } catch (error, stackTrace) {
        // The bootstrap failure is the headline: a step that also fails to
        // release cannot be reported through AlloyBootstrapError without
        // masking it. Observers are the channel that does not have to choose.
        _notify(
          observers,
          (observer) => observer.onBootstrapStepReleaseFailed(
            step.name,
            error,
            stackTrace,
          ),
        );
      }
    }
  }

  static void _notify(
    List<AlloyObserver> observers,
    void Function(AlloyObserver observer) event,
  ) {
    for (final observer in observers) {
      try {
        event(observer);
      } catch (_) {
        // Watching must not break what it watches.
      }
    }
  }
}
