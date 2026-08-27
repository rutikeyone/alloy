import 'package:alloy/src/errors/alloy_error.dart';
import 'package:alloy/src/key/alloy_key.dart';

/// Thrown when a parameterized registration is resolved without its argument.
///
/// The container has no value to pass, and inventing one would hand back an
/// object built from something nobody chose.
class AlloyParamRequiredError extends AlloyError {
  /// Creates an error for the parameterized [key].
  AlloyParamRequiredError(this.key)
    : super('$key requires a parameter; resolve it with getWithParam.');

  /// The key that needs an argument.
  final AlloyKey key;
}
