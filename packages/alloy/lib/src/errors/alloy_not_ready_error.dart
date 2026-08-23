import 'package:alloy/src/errors/alloy_error.dart';
import 'package:alloy/src/key/alloy_key.dart';

/// Thrown when an async singleton is requested before `init()` has built it.
///
/// Alloy reports this instead of returning a half-built object, so an ordering
/// mistake surfaces at the point it happens.
class AlloyNotReadyError extends AlloyError {
  /// Creates an error for the not-yet-initialized [key].
  AlloyNotReadyError(this.key)
    : super('$key is an async registration and was requested before init().');

  /// The key that is not ready yet.
  final AlloyKey key;
}
