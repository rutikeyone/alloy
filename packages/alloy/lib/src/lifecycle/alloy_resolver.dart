/// Reads instances out of a scope.
///
/// A scope implements this, and it is what factories receive, so a factory can
/// resolve its own dependencies without holding a reference to the container.
abstract interface class AlloyResolver {
  /// Returns the instance registered for [T].
  ///
  /// Resolution starts in this scope and walks up through its ancestors, so a
  /// child can see everything its parents registered and can shadow any of it.
  /// It never walks downwards — a parent cannot reach a child's registrations.
  ///
  /// Throws `AlloyNotRegisteredError` if nothing matches, and
  /// `AlloyNotReadyError` for an async singleton requested before `init()`.
  /// A dependency cycle throws `AlloyCycleError` naming the path.
  T get<T extends Object>({String? name});

  /// Returns every registration of [T] visible from this scope, nearest first.
  ///
  /// Registrations are keyed by type *and* name, so this collects the unnamed
  /// one together with all named ones. When a child re-registers the same key
  /// as an ancestor, only the child's instance appears.
  List<T> getAll<T extends Object>();

  /// Builds an instance from a parameterized factory, passing [param] to it.
  ///
  /// The result is never retained by the scope; the caller owns it. Throws
  /// `AlloyError` if the registration is not a parameterized factory.
  T getWithParam<T extends Object, P extends Object>(P param, {String? name});

  /// Returns the instance registered for [T], or null when nothing is.
  ///
  /// This is what an optional dependency reads. A `Foo?` parameter or
  /// `@injected` field resolves through here, so a graph that does not supply
  /// `Foo` injects null instead of failing.
  ///
  /// Null means exactly one thing: nothing is registered under this key.
  /// Everything else still throws — an async singleton requested before
  /// `init()` raises `AlloyNotReadyError`, a parameterized factory raises
  /// `AlloyError`, and a cycle raises `AlloyCycleError`. Folding those into
  /// null would turn a startup-ordering bug into a value that reads as
  /// "absent".
  T? getOrNull<T extends Object>({String? name});

  /// Whether [T] can be resolved from this scope or any ancestor.
  bool isRegistered<T extends Object>({String? name});
}
