import 'package:alloy/alloy.dart';
import 'package:alloy_flutter/src/alloy_scope_widget.dart';
import 'package:flutter/widgets.dart';

/// A stateless widget that owns a scope for as long as it is mounted.
///
/// Collapses the three pieces an owned scope otherwise needs — a scope builder,
/// an [AlloyScopeWidget] wrapper and a separate child widget — into one class.
/// Declare what the scope holds in [registerScope] and the UI in [buildScoped];
/// the scope is pushed on mount and disposed on unmount.
///
/// ```dart
/// class NoteDetailScreen extends AlloyScopedWidget {
///   const NoteDetailScreen({super.key});
///
///   @override
///   void registerScope(AlloyScope scope) =>
///       scope.registerLazySingleton<NoteDraft>(const NoteDraftFactory());
///
///   @override
///   Widget buildScoped(BuildContext context) =>
///       Text(context.alloy<NoteDraft>().text);
/// }
/// ```
///
/// [buildScoped] runs below the scope, so `context.alloy<T>()` there resolves
/// from it. Use [AlloyScopeWidget] directly when the scope has to wrap only
/// part of a subtree rather than the whole widget.
abstract class AlloyScopedWidget extends StatelessWidget {
  /// Creates a widget owning a scope.
  const AlloyScopedWidget({super.key});

  /// Name of the scope, defaulting to this widget's own type.
  String? get scopeName => null;

  /// Shown while the scope initializes, when it registers async singletons.
  Widget? get loading => null;

  /// Shown when initialization fails. Without it the error is rethrown.
  Widget Function(BuildContext context, Object error)? get errorBuilder => null;

  /// Declares what this widget's scope holds.
  void registerScope(AlloyScope scope);

  /// Builds the UI, with the scope available on [context].
  Widget buildScoped(BuildContext context);

  @override
  Widget build(BuildContext context) => AlloyScopeWidget(
    name: scopeName ?? runtimeType.toString(),
    builder: AlloyWidgetScopeBuilder(this),
    loading: loading,
    errorBuilder: errorBuilder,
    child: AlloyScopedChild(this),
  );
}

/// Adapts an [AlloyScopedWidget] to [AlloyScopeBuilder].
///
/// An object rather than a closure, so nothing is captured beyond the widget
/// itself and the builder compares by the widget it wraps.
final class AlloyWidgetScopeBuilder implements AlloyScopeBuilder {
  /// Wraps [widget] so its `registerScope` can be passed as a builder.
  const AlloyWidgetScopeBuilder(this.widget);

  /// The widget whose scope this builds.
  final AlloyScopedWidget widget;

  @override
  void build(AlloyScope scope) => widget.registerScope(scope);
}

/// Renders an [AlloyScopedWidget]'s content below its scope.
final class AlloyScopedChild extends StatelessWidget {
  /// Renders the content of [owner].
  const AlloyScopedChild(this.owner, {super.key});

  /// The widget whose [AlloyScopedWidget.buildScoped] this calls.
  final AlloyScopedWidget owner;

  @override
  Widget build(BuildContext context) => owner.buildScoped(context);
}
