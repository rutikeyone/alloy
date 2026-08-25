import 'package:meta/meta_meta.dart';

/// Marks a class whose members register types you did not write.
///
/// `@AlloyInject` goes on a class, so it can only register classes you own.
/// A module is the way in for everything else — a client from another package,
/// a value only known at runtime, an object built by a factory function:
///
/// ```dart
/// @alloyModule
/// class NetworkModule {
///   const NetworkModule();
///
///   @alloyInject
///   Dio dio(AppConfig config) => Dio(BaseOptions(baseUrl: config.apiBase));
///
///   @alloySingleton
///   Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
/// }
/// ```
///
/// The annotation carries nothing itself. Every member configures its own
/// registration with the same annotations a class uses — `@AlloyInject` for
/// the lifetime, name and `exposeAs`, `@Named` on its parameters, and
/// `@AlloyEnvironment` to restrict it to one build.
///
/// The class needs a public `const` constructor taking no arguments, so the
/// generated factory can hold `const NetworkModule()` and carry no state of
/// its own. Members must be public, instance rather than static, and take only
/// positional parameters; each parameter is resolved from the scope.
///
/// A member returning `Future<T>` registers `T` as an async singleton, built
/// during startup. There is no `@AlloyInit` on a member: the return type
/// already says it.
///
/// A member cannot be abstract. "Build it from its own constructor" is what
/// `@AlloyInject` on the class already means, and publishing it under an
/// interface is what `exposeAs` means.
@Target({TargetKind.classType})
class AlloyModule {
  /// Creates the marker.
  const AlloyModule();
}

/// Marks the class as a module of provider members.
const alloyModule = AlloyModule();
