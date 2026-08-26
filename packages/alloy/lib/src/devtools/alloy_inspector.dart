import 'dart:convert';
import 'dart:developer' as developer;

import 'package:alloy/src/devtools/alloy_scope_registry.dart';
import 'package:alloy/src/scope/alloy_scope.dart';

/// Publishes the live scope tree over the VM service.
///
/// Call [enable] once during startup, guarded so it never reaches a release
/// build:
///
/// ```dart
/// assert(() {
///   AlloyInspector.enable();
///   return true;
/// }());
/// ```
///
/// After that `ext.alloy.getScopeTree` answers with every root alive and what
/// each scope registers.
///
/// The guard is what decides whether it exists at all: with asserts off the
/// call never runs and the extension is simply absent, which is the point in a
/// release build — but it also means `dart run` needs `--enable-asserts` to see
/// it, since only Flutter's debug mode turns them on for you. DevTools is one consumer; a test driving the app
/// through `package:vm_service` is another, and that one needs no UI at all.
///
/// **What it reports is what was declared.** A lazy singleton nobody resolved
/// is indistinguishable from one that is built, objects handed to `adopt` have
/// no key, and nothing records what a factory will ask for — so this is a tree
/// of scopes and their registrations, never a dependency graph.
abstract final class AlloyInspector {
  static var _registered = false;

  /// Registers the service extension. Calling it twice does nothing.
  static void enable() {
    if (_registered) return;
    _registered = true;
    developer.registerExtension('ext.alloy.getScopeTree', (_, _) async {
      return developer.ServiceExtensionResponse.result(
        jsonEncode({
          'roots': [
            for (final root in AlloyScopeRegistry.roots) describe(root),
          ],
        }),
      );
    });
  }

  /// The JSON shape one scope and its subtree report.
  ///
  /// Public so a test can compare against it without going through the VM
  /// service.
  static Map<String, Object?> describe(AlloyScope scope) => {
    'name': scope.name,
    'depth': scope.depth,
    'state': scope.state.name,
    'keys': [for (final key in scope.keys) key.toString()],
    'inherited': [
      for (final entry in scope.visibleKeys.entries)
        if (!identical(entry.value, scope))
          {'key': entry.key.toString(), 'owner': entry.value.name},
    ],
    'children': [for (final child in scope.children) describe(child)],
  };
}
