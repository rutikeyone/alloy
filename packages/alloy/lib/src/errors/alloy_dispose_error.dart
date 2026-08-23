import 'package:alloy/src/errors/alloy_dispose_failure.dart';
import 'package:alloy/src/errors/alloy_dispose_stage.dart';
import 'package:alloy/src/errors/alloy_error.dart';

/// Thrown when teardown finished but some of it did not go cleanly.
///
/// The scope is fully disposed by the time this is thrown. Teardown is
/// best-effort: a step that throws or runs past the deadline is recorded and
/// the rest still runs, so one broken object cannot strand everything
/// registered after it.
///
/// Steps that timed out were abandoned, not cancelled — Dart cannot cancel a
/// future — which is the main reason this is reported rather than swallowed.
class AlloyDisposeError extends AlloyError {
  /// Creates an error describing every [failures] entry from [scopeName].
  AlloyDisposeError(this.scopeName, this.failures)
    : super(_describe(scopeName, failures));

  /// The scope whose teardown was incomplete.
  final String scopeName;

  /// Everything that did not complete, in teardown order.
  final List<AlloyDisposeFailure> failures;

  /// The subset that ran out of time rather than throwing.
  Iterable<AlloyDisposeFailure> get timeouts =>
      failures.where((failure) => failure.isTimeout);

  /// Whether any step ran past the deadline.
  bool get hasTimeout => failures.any((failure) => failure.isTimeout);

  /// The subset that is an initialization failure rather than a teardown one.
  ///
  /// Present only as context: an init failure alone never produces this error,
  /// because it was already delivered to whoever called `init()`.
  Iterable<AlloyDisposeFailure> get initFailures =>
      failures.where((failure) => failure.isInitFailure);

  /// The subset that is teardown proper — everything Alloy could not release.
  Iterable<AlloyDisposeFailure> get releaseFailures =>
      failures.where((failure) => !failure.isInitFailure);

  static String _describe(String scope, List<AlloyDisposeFailure> failures) {
    final released = failures
        .where((failure) => failure.stage == AlloyDisposeStage.releasing)
        .length;
    final lines = failures.map((failure) => '  $failure').join('\n');
    final context = failures.length - released;
    final suffix = context == 0
        ? ''
        : ' The scope was never fully built; $context initialization '
              'failure(s) are listed for context.';
    return 'Disposing scope "$scope" could not release $released step(s).'
        '$suffix\n$lines';
  }
}
