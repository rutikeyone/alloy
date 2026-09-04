import 'package:meta/meta_meta.dart';

/// Restricts the annotated registration to an environment.
///
/// This is an advanced feature and entirely optional: leave it alone and the
/// graph has exactly one environment, [defaultEnvironment], which everything
/// belongs to. Reach for it when one build needs a different implementation
/// than another.
///
/// A class carrying no [CobaltEnvironment] belongs to every graph. A class
/// carrying one or more is registered only when the environment picked at
/// startup matches, which is how one interface gets a different implementation
/// per build:
///
/// ```dart
/// @CobaltInject(exposeAs: NoteStore)
/// @CobaltEnvironment.prod
/// class NoteRepository implements NoteStore { ... }
///
/// @CobaltInject(exposeAs: NoteStore)
/// @CobaltEnvironment.dev
/// @CobaltEnvironment.test
/// class InMemoryNotes implements NoteStore { ... }
/// ```
///
/// [dev], [stage], [prod] and [test] are conveniences, not a closed set:
/// `@CobaltEnvironment('canary')` declares an environment of your own, and
/// nothing about it is second class.
///
/// Two registrations of the same type may not be active together. The
/// generator rejects a graph where they could be, so a missing or overlapping
/// environment is a build failure rather than a silent last-one-wins.
@Target({TargetKind.classType, TargetKind.method, TargetKind.getter})
class CobaltEnvironment {
  /// Creates an environment called [name].
  const CobaltEnvironment(this.name);

  /// The one environment a graph has until you split it.
  ///
  /// Environments are opt-in. A project that never writes [CobaltEnvironment]
  /// has a single graph, every registration belongs to it, and startup takes
  /// no environment at all. This constant is what that single environment is
  /// called once you ask.
  ///
  /// It matches unrestricted registrations and nothing else, so starting a
  /// split graph without choosing leaves the split types unregistered and the
  /// first resolution of one fails saying so.
  static const defaultEnvironment = CobaltEnvironment('default');

  /// Local development.
  static const dev = CobaltEnvironment('dev');

  /// A production-like deployment that is not production.
  static const stage = CobaltEnvironment('stage');

  /// Production.
  static const prod = CobaltEnvironment('prod');

  /// Automated tests.
  static const test = CobaltEnvironment('test');

  /// What this environment is called.
  final String name;

  /// Whether a registration restricted to [environments] belongs to this one.
  ///
  /// An empty [environments] means the registration named no environment at
  /// all, so it belongs everywhere.
  ///
  /// Override this to select more than one environment at a time, or to match
  /// on something other than the name:
  ///
  /// ```dart
  /// class DevWithMocks extends CobaltEnvironment {
  ///   const DevWithMocks() : super('dev');
  ///
  ///   @override
  ///   bool matches(Set<String> environments) =>
  ///       environments.isEmpty ||
  ///       environments.contains('dev') ||
  ///       environments.contains('mock');
  /// }
  /// ```
  bool matches(Set<String> environments) =>
      environments.isEmpty || environments.contains(name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CobaltEnvironment &&
          other.runtimeType == runtimeType &&
          other.name == name;

  @override
  int get hashCode => Object.hash(runtimeType, name);

  @override
  String toString() => 'CobaltEnvironment($name)';
}
