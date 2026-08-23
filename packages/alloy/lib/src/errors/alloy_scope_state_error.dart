import 'package:alloy/src/errors/alloy_error.dart';

/// Thrown when a scope is used after it started disposing.
///
/// Registering into, resolving from, or pushing a child onto a disposed scope
/// all raise this rather than silently working against torn-down state.
class AlloyScopeStateError extends AlloyError {
  /// Creates an error describing the illegal use.
  AlloyScopeStateError(super.message);
}
