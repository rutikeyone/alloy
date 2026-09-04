import 'package:cobalt/src/graph/cobalt_cycle_error.dart';
import 'package:cobalt/src/key/cobalt_key.dart';

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
/// `CobaltNotReadyError` without ever reaching this class.
final class CobaltResolutionTracker {
  final _stack = <CobaltKey>[];
  final _chain = <CobaltKey>[];

  /// What is under construction right now, outermost first.
  ///
  /// Several branches at once during a parallel init level, so this answers
  /// "what is being built", never "what asked for what". For the second
  /// question use [chain].
  List<CobaltKey> get pending => List.unmodifiable(_stack);

  /// The synchronous chain of factories currently on the Dart stack.
  ///
  /// Only [guard] adds to this, which is what makes it a chain rather than a
  /// set: synchronous calls nest strictly, so the last entry really did ask
  /// for the next thing resolved. [guardAsync] deliberately stays out — an
  /// awaited build shares the stack with its siblings, and presenting those as
  /// a chain would name a caller that never called.
  ///
  /// The cost of that is a shorter chain, never a wrong one: a resolve inside
  /// an async factory shows the sync calls below it and stops there.
  List<CobaltKey> get chain => List.unmodifiable(_chain);

  void enter(CobaltKey key) {
    final index = _stack.indexOf(key);
    if (index >= 0) {
      throw CobaltCycleError([
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
  void exit(CobaltKey key) => _stack.remove(key);

  T guard<T>(CobaltKey key, T Function() build) {
    enter(key);
    _chain.add(key);
    try {
      return build();
    } finally {
      _chain.removeLast();
      exit(key);
    }
  }

  Future<T> guardAsync<T>(CobaltKey key, Future<T> Function() build) async {
    enter(key);
    try {
      return await build();
    } finally {
      exit(key);
    }
  }
}
