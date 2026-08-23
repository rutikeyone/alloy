/// Where a scope is in its lifecycle.
enum AlloyScopeState {
  /// Accepting registrations; async singletons have not been built yet.
  open,

  /// `init()` is running. Registrations and resolutions still work, so a
  /// factory can resolve during initialization.
  initializing,

  /// Fully built. Every async singleton is ready to resolve.
  active,

  /// Teardown has begun. Any further use throws `AlloyScopeStateError`.
  disposing,

  /// Torn down and detached from its parent. Permanently unusable.
  disposed,
}
