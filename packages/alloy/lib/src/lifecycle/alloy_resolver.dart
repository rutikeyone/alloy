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

  /// Whether [T] can be resolved from this scope or any ancestor.
  bool isRegistered<T extends Object>({String? name});
}
