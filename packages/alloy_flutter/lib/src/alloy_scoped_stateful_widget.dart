import 'package:alloy/alloy.dart';
import 'package:alloy_flutter/src/alloy_scope_widget.dart';
import 'package:flutter/widgets.dart';

/// A stateful widget that owns a scope for as long as it is mounted.
///
/// The stateful counterpart of `AlloyScopedWidget`: the widget declares what
/// the scope holds, and its [AlloyScopedState] builds the UI below that scope.
/// `setState` rebuilds only the content — the scope is created once on mount
/// and disposed on unmount, not rebuilt.
///
/// ```dart
/// class NoteDetailScreen extends AlloyScopedStatefulWidget {
///   const NoteDetailScreen({super.key});
///
///   @override
///   void registerScope(AlloyScope scope) =>
///       scope.registerLazySingleton<NoteDraft>(const NoteDraftFactory());
///
///   @override
///   AlloyScopedState<NoteDetailScreen> createState() => _NoteDetailState();
/// }
///
/// class _NoteDetailState extends AlloyScopedState<NoteDetailScreen> {
///   @override
///   Widget buildScoped(BuildContext context) =>
///       Text(context.alloy<NoteDraft>().text);
/// }
/// ```
abstract class AlloyScopedStatefulWidget extends StatefulWidget {
  /// Creates a widget owning a scope.
  const AlloyScopedStatefulWidget({super.key});

  /// Name of the scope, defaulting to this widget's own type.
  String? get scopeName => null;

  /// Shown while the scope initializes, when it registers async singletons.
  Widget? get loading => null;

  /// Shown when initialization fails. Without it the error is rethrown.
  Widget Function(BuildContext context, Object error)? get errorBuilder => null;

  /// Declares what this widget's scope holds.
  void registerScope(AlloyScope scope);

  @override
  AlloyScopedState<AlloyScopedStatefulWidget> createState();
}

/// State for an [AlloyScopedStatefulWidget].
///
/// Override [buildScoped] instead of `build`; it runs below the scope, so
/// `context.alloy<T>()` there resolves from it.
abstract class AlloyScopedState<W extends AlloyScopedStatefulWidget>
    extends State<W> {
  /// Builds the UI, with the scope available on [context].
  Widget buildScoped(BuildContext context);

  @override
  Widget build(BuildContext context) => AlloyScopeWidget(
    name: widget.scopeName ?? widget.runtimeType.toString(),
    builder: AlloyStatefulScopeBuilder(widget),
    loading: widget.loading,
    errorBuilder: widget.errorBuilder,
    child: AlloyScopedStateChild(this),
  );
}

/// Adapts an [AlloyScopedStatefulWidget] to [AlloyScopeBuilder].
final class AlloyStatefulScopeBuilder implements AlloyScopeBuilder {
  /// Wraps [widget] so its `registerScope` can be passed as a builder.
  const AlloyStatefulScopeBuilder(this.widget);

  /// The widget whose scope this builds.
  final AlloyScopedStatefulWidget widget;

  @override
  void build(AlloyScope scope) => widget.registerScope(scope);
}

/// Renders an [AlloyScopedState]'s content below its scope.
final class AlloyScopedStateChild extends StatelessWidget {
  /// Renders the content of [owner].
  const AlloyScopedStateChild(this.owner, {super.key});

  /// The state whose [AlloyScopedState.buildScoped] this calls.
  final AlloyScopedState<AlloyScopedStatefulWidget> owner;

  @override
  Widget build(BuildContext context) => owner.buildScoped(context);
}
