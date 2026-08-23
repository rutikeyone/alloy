/// Base class for everything Alloy throws at runtime.
///
/// Extends `StateError` because every case means the container was asked for
/// something it cannot deliver in its current state — a programming error, not
/// a condition to recover from at runtime.
class AlloyError extends StateError {
  /// Creates an error carrying [message].
  AlloyError(super.message);
}
