import 'package:alloy/src/lifecycle/alloy_resolver.dart';

/// Builds a [T] synchronously.
///
/// Alloy registers factory *objects* rather than closures, so generated
/// factories can be `const` and carry no captured state. Implementations are
/// expected to be stateless and are usually const classes with a single
/// [create] method.
abstract interface class AlloyFactory<T extends Object> {
  /// Builds a new [T], resolving its dependencies from [resolver].
  T create(AlloyResolver resolver);
}
