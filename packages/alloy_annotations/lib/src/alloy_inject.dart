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
@Target({TargetKind.classType, TargetKind.method, TargetKind.getter})
class AlloyInject {
  /// Creates an annotation describing how the registration behaves.
  const AlloyInject({
    this.lifetime = AlloyLifetime.lazySingleton,
    this.name,
    this.exposeAs,
    this.dispose,
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

  /// Closes the instance at teardown, for a type that cannot say how itself.
  ///
  /// Point it at a top-level or static function taking the registered type:
  /// `@AlloyInject(dispose: closeClient)`. It works on a class and on an
  /// [AlloyModule] member alike — it used to be read only for members, and a
  /// class naming one registered without it and was never closed.
  ///
  /// Prefer implementing `Disposable` or `AsyncDisposable` where you can: that
  /// keeps the knowledge on the object rather than at every registration of
  /// it. Reach for this when you cannot — a type from another package, or one
  /// whose closing method belongs to a base class you do not control.
  ///
  /// A transient and a parameterized registration are never retained by the
  /// scope, so it could never call this — pairing them is a build error.
  final Function? dispose;
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
