import 'package:cobalt/src/lifecycle/cobalt_resolver.dart';

/// Builds a [T] from a runtime argument that the container cannot supply.
///
/// Use it when part of the input is only known at the call site — a record id,
/// a route argument. Resolve through `getWithParam`; the scope never retains
/// the result.
abstract interface class CobaltParamFactory<
  T extends Object,
  P extends Object
> {
  /// Builds a new [T] from [param], resolving the rest from [resolver].
  T create(CobaltResolver resolver, P param);
}
