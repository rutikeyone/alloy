/// Released asynchronously by the owning scope.
///
/// Behaves like `Disposable`, except the scope awaits [dispose] before moving
/// on to the next object, so teardown stays ordered even when it does I/O.
abstract interface class AsyncDisposable {
  /// Releases whatever this object holds, and completes when it is done.
  Future<void> dispose();
}
