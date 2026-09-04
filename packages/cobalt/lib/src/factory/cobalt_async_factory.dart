import 'package:cobalt/src/lifecycle/cobalt_resolver.dart';

/// Builds a [T] asynchronously, for registrations that need I/O before they
/// are usable.
///
/// Used by `registerAsyncSingleton`; the scope awaits [create] during
/// `init()`, and the instance only becomes resolvable once it completes.
abstract interface class CobaltAsyncFactory<T extends Object> {
  /// Builds a new [T], resolving its dependencies from [resolver].
  Future<T> create(CobaltResolver resolver);
}
