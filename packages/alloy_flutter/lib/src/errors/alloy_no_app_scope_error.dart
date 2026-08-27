import 'package:alloy/alloy.dart';

/// Thrown when nothing owns a root scope above the widget asking to restart
/// it.
///
/// [AlloyScopeProvider] publishes a scope; only `AlloyAppScope` owns one, and
/// only an owner can take it down and build it again.
class AlloyNoAppScopeError extends AlloyError {
  /// Creates the error.
  AlloyNoAppScopeError()
    : super(
        'No AlloyAppScope found above this widget. Wrap your app in '
        'AlloyAppScope to restart its root scope; AlloyScopeProvider only '
        'publishes a scope somebody else owns.',
      );
}
