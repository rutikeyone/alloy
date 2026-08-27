import 'package:alloy/src/errors/alloy_error.dart';
import 'package:alloy/src/key/alloy_key.dart';

/// Thrown when `dependsOn` names something it cannot order.
///
/// `dependsOn` sequences phase 1, so the only thing it can wait for is another
/// async registration. Naming anything else used to be accepted and silently
/// dropped, which left the declaration reading as an ordering guarantee that
/// was never in force.
class AlloyDependsOnError extends AlloyError {
  /// Creates an error for [dependency], declared by [dependent].
  AlloyDependsOnError(this.dependent, this.dependency, {required this.reason})
    : super(
        '$dependent declares dependsOn: $dependency, which $reason. '
        'dependsOn orders async initialization and can wait only for another '
        'async registration.',
      );

  /// The async registration that declared the dependency.
  final AlloyKey dependent;

  /// The key it declared.
  final AlloyKey dependency;

  /// Why that key cannot be waited for.
  final String reason;
}
