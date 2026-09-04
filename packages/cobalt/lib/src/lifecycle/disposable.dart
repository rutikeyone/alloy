/// Released by the owning scope when it is disposed.
///
/// A scope retains every singleton it builds that implements this, and calls
/// [dispose] in reverse creation order, so an object is always torn down
/// before the dependencies it was built from. Transient instances are not
/// retained and are the caller's to dispose.
abstract interface class Disposable {
  /// Releases whatever this object holds.
  void dispose();
}
