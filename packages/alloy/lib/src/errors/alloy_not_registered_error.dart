import 'package:alloy/src/errors/alloy_error.dart';
import 'package:alloy/src/key/alloy_key.dart';

/// Thrown when nothing matching the requested key exists in the scope or any
/// of its ancestors.
///
/// A common cause is asking a parent for something only a child registered:
/// resolution walks upwards, never down.
class AlloyNotRegisteredError extends AlloyError {
  /// Creates an error for the missing [key], reported from [scopeName].
  ///
  /// [resolving] is what was being built when the key was asked for, outermost
  /// first. It turns "Config is not registered" into the sentence that also
  /// names the class that wanted it, which is the one you have to change.
  AlloyNotRegisteredError(this.key, this.scopeName, {this.resolving = const []})
    : super(_message(key, scopeName, resolving));

  /// The key that could not be resolved.
  final AlloyKey key;

  /// The scope the resolution started from.
  final String scopeName;

  /// The registrations under construction when this was asked for.
  final List<AlloyKey> resolving;

  static String _message(
    AlloyKey key,
    String scopeName,
    List<AlloyKey> resolving,
  ) {
    final where =
        '$key is not registered in scope "$scopeName" or its ancestors.';
    if (resolving.isEmpty) return where;
    final path = [...resolving, key].join(' -> ');
    return '$where Resolving: $path.';
  }
}
