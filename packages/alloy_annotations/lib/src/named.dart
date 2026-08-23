import 'package:meta/meta_meta.dart';

/// Selects a named registration for the annotated parameter or field.
///
/// ```dart
/// @alloyInject
/// class Auditor {
///   Auditor(@Named('audit') this.logger);
///   final Logger logger;
/// }
/// ```
@Target({TargetKind.parameter, TargetKind.field})
class Named {
  /// Creates an annotation pointing at the registration called [name].
  const Named(this.name);

  /// The registration name to resolve.
  final String name;
}
