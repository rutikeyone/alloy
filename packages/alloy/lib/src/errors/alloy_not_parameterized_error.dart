import 'package:alloy/src/errors/alloy_error.dart';
import 'package:alloy/src/key/alloy_key.dart';

/// Thrown when a parameterized resolve names a registration that takes no
/// parameter.
///
/// The mirror of [AlloyParamRequiredError]: one says you passed an argument
/// where none is wanted, the other that you passed none where one is.
class AlloyNotParameterizedError extends AlloyError {
  /// Creates an error for [key], which is registered but not with a parameter.
  AlloyNotParameterizedError(this.key)
    : super(
        '$key is not registered as a parameterized factory; resolve it with '
        'get.',
      );

  /// The key that was resolved with a parameter.
  final AlloyKey key;
}
