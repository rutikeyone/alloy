import 'package:cobalt_annotations/src/cobalt_scope_root.dart';

/// A registration the generated container does not make itself.
///
/// Use it in [CobaltScopeRoot.provides] when a dependency is registered by
/// hand — by a scope builder wrapping the generated one, or by another
/// package — and the type alone is not enough because the registration is
/// named:
///
/// ```dart
/// @CobaltScopeRoot(
///   name: 'app',
///   provides: [SessionManager, CobaltProvided(Logger, name: 'audit')],
/// )
/// class AppScope {
///   const AppScope();
/// }
/// ```
///
/// A plain `Type` in the same list means the same thing without a name, which
/// is the common case.
class CobaltProvided {
  /// Declares that [type], optionally registered under [name], is supplied
  /// from outside the generated container.
  const CobaltProvided(this.type, {this.name});

  /// The type the registration is keyed under — the exposed type, not the
  /// concrete class, exactly as `@CobaltInject(exposeAs: ...)` would key it.
  final Type type;

  /// The `@Named` qualifier the registration carries, or null when it has
  /// none.
  final String? name;
}
