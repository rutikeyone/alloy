/// A whole-package problem found while assembling the container, such as two
/// classes claiming to be the root scope.
class AlloyGenerationError implements Exception {
  AlloyGenerationError(this.message);

  final String message;

  @override
  String toString() => 'AlloyGenerationError: $message';
}
