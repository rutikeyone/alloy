import 'package:cobalt/src/errors/cobalt_error.dart';
import 'package:cobalt/src/key/cobalt_key.dart';

/// Thrown when a parameterized registration is resolved without its argument.
///
/// The container has no value to pass, and inventing one would hand back an
/// object built from something nobody chose.
class CobaltParamRequiredError extends CobaltError {
  /// Creates an error for the parameterized [key].
  CobaltParamRequiredError(this.key)
    : super('$key requires a parameter; resolve it with getWithParam.');

  /// The key that needs an argument.
  final CobaltKey key;
}
