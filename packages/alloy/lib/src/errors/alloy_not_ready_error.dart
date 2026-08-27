import 'package:alloy/src/errors/alloy_error.dart';
import 'package:alloy/src/key/alloy_key.dart';

/// Thrown when an async singleton is requested before `init()` has built it.
///
/// Alloy reports this instead of returning a half-built object, so an ordering
/// mistake surfaces at the point it happens.
class AlloyNotReadyError extends AlloyError {
  /// Creates an error for the not-yet-initialized [key].
  ///
  /// [resolving] is what was being built when the key was asked for, outermost
  /// first — the same trail [AlloyNotRegisteredError] carries, because the
  /// question it answers is the same one: which class do I have to change.
  AlloyNotReadyError(this.key, {this.resolving = const []})
    : super(_message(key, resolving));

  /// The key that is not ready yet.
  final AlloyKey key;

  /// The registrations under construction when this was asked for.
  final List<AlloyKey> resolving;

  static String _message(AlloyKey key, List<AlloyKey> resolving) {
    final what =
        '$key is an async registration and was requested before init().';
    if (resolving.isEmpty) return what;
    final path = [...resolving, key].join(' -> ');
    return '$what Resolving: $path.';
  }
}
