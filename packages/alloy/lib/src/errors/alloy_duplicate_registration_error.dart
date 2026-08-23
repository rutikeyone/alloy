import 'package:alloy/src/errors/alloy_error.dart';
import 'package:alloy/src/key/alloy_key.dart';

/// Thrown when the same key is registered twice in one scope.
///
/// Overriding a dependency is done by registering it again in a *child* scope,
/// which shadows the ancestor without mutating it. That is also the intended
/// way to swap a dependency for a test double.
class AlloyDuplicateRegistrationError extends AlloyError {
  /// Creates an error for the duplicated [key] in [scopeName].
  AlloyDuplicateRegistrationError(this.key, this.scopeName)
    : super('$key is already registered in scope "$scopeName".');

  /// The key that was registered twice.
  final AlloyKey key;

  /// The scope that already held the key.
  final String scopeName;
}
