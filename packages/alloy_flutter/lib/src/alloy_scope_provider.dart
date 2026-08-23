import 'package:alloy/alloy.dart';
import 'package:flutter/widgets.dart';

/// Publishes an [AlloyScope] to a widget subtree.
///
/// This only exposes a scope; it never owns one. Mount it at the root with the
/// scope returned by startup, and use [AlloyScopeWidget] further down when a
/// part of the tree needs a scope with a shorter life.
class AlloyScopeProvider extends InheritedWidget {
  /// Publishes [scope] to [child] and everything below it.
  const AlloyScopeProvider({
    required this.scope,
    required super.child,
    super.key,
  });

  /// The scope descendants resolve from.
  final AlloyScope scope;

  /// The nearest scope above [context].
  ///
  /// Throws `AlloyError` when there is none, which is nearly always a missing
  /// provider at the root rather than a resolution problem.
  static AlloyScope of(BuildContext context) {
    final provider = maybeOf(context);
    if (provider == null) {
      throw AlloyError(
        'No AlloyScopeProvider found above this widget. '
        'Wrap your app in AlloyScopeProvider or AlloyScopeWidget.',
      );
    }
    return provider;
  }

  /// The nearest scope above [context], or `null` if the subtree has none.
  static AlloyScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AlloyScopeProvider>()?.scope;

  @override
  bool updateShouldNotify(AlloyScopeProvider oldWidget) =>
      !identical(scope, oldWidget.scope);
}
