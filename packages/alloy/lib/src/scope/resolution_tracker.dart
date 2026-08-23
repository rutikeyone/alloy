import 'package:alloy/src/graph/alloy_cycle_error.dart';
import 'package:alloy/src/key/alloy_key.dart';

final class AlloyResolutionTracker {
  final _stack = <AlloyKey>[];

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

  void exit(AlloyKey key) {
    if (_stack.isNotEmpty && _stack.last == key) _stack.removeLast();
  }

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
