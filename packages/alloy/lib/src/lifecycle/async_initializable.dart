/// Prepared asynchronously before the scope reports itself active.
///
/// A class annotated `@AlloyInit` implements this; the generated factory
/// awaits [init] before the instance becomes resolvable. In Manual Mode the
/// same contract is expressed by an `AlloyAsyncFactory` that awaits [init]
/// itself.
abstract interface class AsyncInitializable {
  /// Performs the asynchronous part of construction.
  Future<void> init();
}
