import 'package:meta/meta_meta.dart';

/// Names the root scope and makes the generator emit a start function.
///
/// Annotate any one class in the package — it is a marker, nothing is
/// registered from it. The generator then emits `$alloyRootScopeName` and
/// `$startAlloy()`, which wires the container, the bootstrap list and the name
/// together:
///
/// ```dart
/// @AlloyScopeRoot(name: 'app')
/// class AppScope {
///   const AppScope();
/// }
///
/// final scope = await $startAlloy();
/// ```
///
/// Without the annotation the root scope is called `root`. Two annotated
/// classes in one package is a generation error, since the package can only
/// have one root.
@Target({TargetKind.classType})
class AlloyScopeRoot {
  /// Creates an annotation naming the root scope.
  const AlloyScopeRoot({this.name = 'root'});

  /// The name the root scope reports, used in error messages and when
  /// inspecting the scope tree.
  final String name;
}
