import 'package:cobalt/cobalt.dart';
import 'package:test_api/scaffolding.dart';

/// Starts a graph and disposes it when the test ends.
///
/// The same three lines appeared in most test files in this repository, once
/// per graph. Registering the teardown is the part that is easy to leave out,
/// and leaving it out leaks between tests rather than failing.
Future<CobaltScope> cobaltTestScope({
  required CobaltScopeBuilder root,
  List<CobaltBootstrapStep> bootstrap = const [],
  String rootName = 'root',
  List<CobaltObserver> observers = const [],
}) async {
  final scope = await CobaltApplication.start(
    root: root,
    bootstrap: bootstrap,
    rootName: rootName,
    observers: observers,
  );
  addTearDown(scope.dispose);
  return scope;
}

/// A bare root scope, disposed when the test ends.
///
/// For unit tests that register a handful of things directly and never need
/// two-phase startup.
CobaltScope cobaltTestRoot({
  String name = 'root',
  List<CobaltObserver> observers = const [],
}) {
  final scope = CobaltScope.root(name: name, observers: observers);
  addTearDown(scope.dispose);
  return scope;
}

/// Helpers for overriding part of a graph in a test.
extension CobaltTestScope on CobaltScope {
  /// Pushes a child scope to register overrides into, disposed with the test.
  ///
  /// Shadowing from a child is how production overrides work too, so a test
  /// uses the same mechanism the app does rather than a back door.
  CobaltScope pushForTest([String name = 'test']) {
    final scope = push(name);
    addTearDown(scope.dispose);
    return scope;
  }

  /// The scope that owns [T] as seen from here, or null when nothing does.
  ///
  /// The answer to "will my override actually be used": a factory runs on the
  /// scope that owns *its* registration, so an override below the consumer is
  /// invisible to it.
  CobaltScope? ownerOf<T extends Object>({String? name}) =>
      visibleKeys[CobaltKey(T, name: name)];
}
