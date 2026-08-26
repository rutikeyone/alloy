import 'package:alloy/src/graph/alloy_cycle_error.dart';
import 'package:alloy/src/key/alloy_key.dart';

/// Tracks what is being built, so a resolution that comes back round on itself
/// fails naming the path instead of recursing until the stack overflows.
///
/// One tracker serves a whole scope tree, because a cycle can run through a
/// parent as easily as through one scope.
///
/// During a parallel init level this holds several branches at once rather than
/// a single call chain: `Future.wait` enters every registration in the level
/// before any of them suspends. That does not weaken the check. A cycle forms
/// in a synchronous chain of resolves, and two async branches cannot resolve
/// each other synchronously — an async singleton that is not ready yet throws
/// `AlloyNotReadyError` without ever reaching this class.
final class AlloyResolutionTracker {
  final _stack = <AlloyKey>[];

  /// What is under construction right now, outermost first.
  List<AlloyKey> get pending => List.unmodifiable(_stack);

  void enter(AlloyKey key) {
    final index = _stack.indexOf(key);
    if (index >= 0) {
      throw AlloyCycleError([
        for (final entry in _stack.skip(index)) entry.toString(),
        key.toString(),
      ]);
    }
    _stack.add(key);
  }

  /// Removes [key] wherever it sits, not only from the top.
  ///
  /// Assuming the top is a mistake once a level runs in parallel: the branch
  /// that finishes first is usually not the one entered last, and a top-only
  /// removal would leave its key behind forever. [enter] rejects duplicates,
  /// so there is at most one entry to remove.
  void exit(AlloyKey key) => _stack.remove(key);

  T guard<T>(AlloyKey key, T Function() build) {
    enter(key);
    try {
      return build();
    } finally {
      exit(key);
    }
  }

  Future<T> guardAsync<T>(AlloyKey key, Future<T> Function() build) async {
    enter(key);
    try {
      return await build();
    } finally {
      exit(key);
    }
  }
}
