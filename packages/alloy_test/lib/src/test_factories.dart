import 'package:alloy/alloy.dart';

/// An [AlloyFactory] built from a function.
///
/// Registering a lazy singleton needs a factory object, so a test that only
/// wants to return a stub had to declare a class for it. This is that class,
/// written once.
class FnFactory<T extends Object> implements AlloyFactory<T> {
  /// Creates a factory that calls [build].
  const FnFactory(this.build);

  /// Builds the instance, resolving whatever else it needs.
  final T Function(AlloyResolver resolver) build;

  @override
  T create(AlloyResolver resolver) => build(resolver);
}

/// An [AlloyFactory] that always returns the same value.
///
/// Unlike `registerSingleton`, this keeps the registration lazy — the value is
/// handed out on first resolution, so a test can assert that nothing resolved
/// it at all.
class ValueFactory<T extends Object> implements AlloyFactory<T> {
  /// Creates a factory returning [value].
  const ValueFactory(this.value);

  /// What every resolution returns.
  final T value;

  @override
  T create(AlloyResolver resolver) => value;
}

/// An [AlloyAsyncFactory] built from a function.
class AsyncFnFactory<T extends Object> implements AlloyAsyncFactory<T> {
  /// Creates a factory that calls [build].
  const AsyncFnFactory(this.build);

  /// Builds the instance.
  final Future<T> Function(AlloyResolver resolver) build;

  @override
  Future<T> create(AlloyResolver resolver) => build(resolver);
}

/// An [AlloyParamFactory] built from a function.
///
/// The sibling of [FnFactory] for `registerParamFactory`, which needs its own
/// interface because the argument the container cannot supply is passed in.
class FnParamFactory<T extends Object, P extends Object>
    implements AlloyParamFactory<T, P> {
  /// Creates a factory that calls [build].
  const FnParamFactory(this.build);

  /// Builds the instance from the runtime argument.
  final T Function(AlloyResolver resolver, P param) build;

  @override
  T create(AlloyResolver resolver, P param) => build(resolver, param);
}
