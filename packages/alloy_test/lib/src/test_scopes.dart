import 'package:alloy/alloy.dart';
import 'package:test_api/scaffolding.dart';

/// Starts a graph and disposes it when the test ends.
///
/// The same three lines appeared in most test files in this repository, once
/// per graph. Registering the teardown is the part that is easy to leave out,
/// and leaving it out leaks between tests rather than failing.
Future<AlloyScope> alloyTestScope({
  required AlloyScopeBuilder root,
  List<AlloyBootstrapStep> bootstrap = const [],
  String rootName = 'root',
  List<AlloyObserver> observers = const [],
}) async {
  final scope = await AlloyApplication.start(
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
AlloyScope alloyTestRoot({
  String name = 'root',
  List<AlloyObserver> observers = const [],
}) {
  final scope = AlloyScope.root(name: name, observers: observers);
  addTearDown(scope.dispose);
  return scope;
}

/// Helpers for overriding part of a graph in a test.
extension AlloyTestScope on AlloyScope {
  /// Pushes a child scope to register overrides into, disposed with the test.
  ///
  /// Shadowing from a child is how production overrides work too, so a test
  /// uses the same mechanism the app does rather than a back door.
  AlloyScope pushForTest([String name = 'test']) {
    final scope = push(name);
    addTearDown(scope.dispose);
    return scope;
  }

  /// The scope that owns [T] as seen from here, or null when nothing does.
  ///
  /// The answer to "will my override actually be used": a factory runs on the
  /// scope that owns *its* registration, so an override below the consumer is
  /// invisible to it.
  AlloyScope? ownerOf<T extends Object>({String? name}) =>
      visibleKeys[AlloyKey(T, name: name)];
}
