import 'package:alloy/src/errors/alloy_error.dart';
import 'package:alloy/src/key/alloy_key.dart';

/// Thrown when nothing matching the requested key exists in the scope or any
/// of its ancestors.
///
/// A common cause is asking a parent for something only a child registered:
/// resolution walks upwards, never down.
class AlloyNotRegisteredError extends AlloyError {
  /// Creates an error for the missing [key], reported from [scopeName].
  AlloyNotRegisteredError(this.key, this.scopeName)
    : super('$key is not registered in scope "$scopeName" or its ancestors.');

  /// The key that could not be resolved.
  final AlloyKey key;

  /// The scope the resolution started from.
  final String scopeName;
}
