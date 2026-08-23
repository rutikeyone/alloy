import 'package:alloy/src/lifecycle/alloy_resolver.dart';

/// Receives its dependencies after construction rather than through its
/// constructor.
///
/// The scope calls [onInject] immediately after a factory returns, before the
/// instance is handed to anyone, so fields assigned here are set before they
/// can be read.
///
/// In Code-Gen Mode the generated `_$ClassName` mixin implements this for you
/// from `@injected` fields. Implementing it by hand is equally valid and is
/// what makes property injection available in Manual Mode.
abstract interface class AlloyInjectable {
  /// Assigns this object's dependencies from [resolver].
  void onInject(AlloyResolver resolver);
}
