import 'package:alloy_annotations/src/alloy_lifetime.dart';
import 'package:meta/meta_meta.dart';

/// Registers the annotated class in the generated container.
///
/// The class needs a public generative constructor; every parameter is
/// resolved from the scope, and [Named] selects a named registration.
///
/// ```dart
/// @alloyInject
/// class Repository {
///   Repository(this.database);
///   final Database database;
/// }
/// ```
@Target({TargetKind.classType})
class AlloyInject {
  /// Creates an annotation describing how the class is registered.
  const AlloyInject({
    this.lifetime = AlloyLifetime.lazySingleton,
    this.name,
    this.exposeAs,
  });

  /// How long the instance lives. Defaults to [AlloyLifetime.lazySingleton].
  final AlloyLifetime lifetime;

  /// Distinguishes this registration from others of the same type.
  ///
  /// Consumers ask for it with `@Named('...')` or `get<T>(name: '...')`.
  final String? name;

  /// Registers the class under this type instead of its own.
  ///
  /// Use it to publish an interface and keep the implementation unreachable:
  /// `@AlloyInject(exposeAs: NoteStore)` on `NoteRepository` means
  /// `get<NoteStore>()` works and `get<NoteRepository>()` does not.
  final Type? exposeAs;
}

/// Registers the class as a lazy singleton — one instance per scope, built on
/// first use.
const alloyInject = AlloyInject();

/// Registers the class as an eager singleton, built while the container is
/// assembled.
const alloySingleton = AlloyInject(lifetime: AlloyLifetime.singleton);

/// Registers the class as a transient — a fresh instance per resolution, not
/// retained by the scope.
const alloyTransient = AlloyInject(lifetime: AlloyLifetime.transient);
