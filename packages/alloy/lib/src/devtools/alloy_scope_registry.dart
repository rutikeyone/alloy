import 'package:alloy/src/scope/alloy_scope.dart';

/// The root scopes alive right now, for diagnostics only.
///
/// A registry of live objects is exactly the kind of global Alloy otherwise
/// refuses to have, which is why every entry point is `assert`-gated by the
/// caller and this holds [WeakReference]s rather than the scopes themselves.
///
/// **Entries are removed when a scope is disposed, not when it is collected.**
/// The weak reference is a backstop for a root nobody ever disposed — a leak,
/// which this must not make worse by holding it alive. Nothing here waits on
/// the garbage collector: Dart promises no timing for `WeakReference`, and a
/// view that trusted collection to prune it would show scopes that are gone.
abstract final class AlloyScopeRegistry {
  static final _roots = <WeakReference<AlloyScope>>[];

  /// Records [scope] as a live root.
  static void add(AlloyScope scope) {
    _prune();
    _roots.add(WeakReference(scope));
  }

  /// Forgets [scope], called as it is disposed.
  static void remove(AlloyScope scope) {
    _roots.removeWhere((ref) {
      final target = ref.target;
      return target == null || identical(target, scope);
    });
  }

  /// Every root still alive, oldest first.
  static List<AlloyScope> get roots {
    _prune();
    return [for (final ref in _roots) ?ref.target];
  }

  /// Drops entries whose scope was collected without being disposed.
  static void _prune() => _roots.removeWhere((ref) => ref.target == null);

  /// Empties the registry. For tests that assert on its contents.
  static void clear() => _roots.clear();
}
