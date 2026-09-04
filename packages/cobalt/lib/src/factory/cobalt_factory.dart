import 'package:cobalt/src/lifecycle/cobalt_resolver.dart';

/// Builds a [T] synchronously.
///
/// Cobalt registers factory *objects* rather than closures, so generated
/// factories can be `const` and carry no captured state. Implementations are
/// expected to be stateless and are usually const classes with a single
/// [create] method.
abstract interface class CobaltFactory<T extends Object> {
  /// Builds a new [T], resolving its dependencies from [resolver].
  T create(CobaltResolver resolver);
}
