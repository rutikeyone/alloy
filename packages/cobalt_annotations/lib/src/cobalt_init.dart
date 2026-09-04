import 'package:meta/meta_meta.dart';

/// Registers the annotated class as an async singleton whose `init()` is
/// awaited during `scope.init()`.
///
/// The class must declare `Future<void> init()` — implementing
/// `AsyncInitializable` is the intended way. The generated factory constructs
/// the object, awaits `init()`, and only then hands it to the scope, so anyone
/// resolving it afterwards gets a fully initialized instance. Resolving it
/// before `scope.init()` completes throws `CobaltNotReadyError` rather than
/// returning a half-built object.
///
/// [dependsOn] turns the initializers into a graph. It is topologically sorted
/// at build time into levels: everything in one level runs together through
/// `Future.wait`, and the next level starts only once the previous finished.
/// Declaring a cycle fails the build and names it.
///
/// ```dart
/// @CobaltInit(dependsOn: [Database])
/// class SearchIndex implements AsyncInitializable {
///   SearchIndex(this._database);
///   final Database _database;
///
///   @override
///   Future<void> init() async => _database.buildIndex();
/// }
/// ```
@Target({TargetKind.classType})
class CobaltInit {
  /// Creates an annotation marking an async initializer.
  const CobaltInit({this.dependsOn = const <Type>[]});

  /// Types whose initialization must complete before this one starts.
  ///
  /// Only ordering is declared here; constructor parameters are resolved
  /// separately and also count as dependency edges.
  final List<Type> dependsOn;
}

/// Registers the class as an async singleton with no ordering constraints.
const cobaltInit = CobaltInit();
