import 'package:alloy/alloy.dart';
import 'package:alloy_flutter/src/alloy_scope_provider.dart';
import 'package:flutter/widgets.dart';

/// Resolves dependencies from the nearest [AlloyScopeProvider].
///
/// Every member here reads an inherited widget, so none of them may be called
/// from `initState` or a constructor — Flutter asserts on that. Resolve in
/// `build`, or in `didChangeDependencies` when the result has to be stored,
/// which is also where a subscription belongs:
///
/// ```dart
/// @override
/// void didChangeDependencies() {
///   super.didChangeDependencies();
///   final session = context.alloy<SessionManager>();
///   if (identical(session, _session)) return;
///   _session?.removeListener(_onChanged);
///   _session = session..addListener(_onChanged);
/// }
/// ```
///
/// A `late final` field initialized from `context` is fine as long as it is
/// first read during `build`, since that is when the lazy initializer runs.
extension AlloyBuildContext on BuildContext {
  /// The nearest scope above this context.
  AlloyScope get alloyScope => AlloyScopeProvider.of(this);

  /// Resolves [T] from the nearest scope.
  T alloy<T extends Object>({String? name}) =>
      AlloyScopeProvider.of(this).get<T>(name: name);

  /// Resolves every registration of [T] visible from the nearest scope.
  List<T> alloyAll<T extends Object>() =>
      AlloyScopeProvider.of(this).getAll<T>();

  /// Builds [T] from a parameterized factory, passing [param].
  T alloyWithParam<T extends Object, P extends Object>(
    P param, {
    String? name,
  }) => AlloyScopeProvider.of(this).getWithParam<T, P>(param, name: name);
}
