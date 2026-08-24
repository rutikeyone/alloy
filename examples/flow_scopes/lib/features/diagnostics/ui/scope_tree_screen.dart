import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_scopes/app/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Renders the live scope tree, so a flow's scope can be watched appearing
/// and disappearing.
class ScopeTreeScreen extends StatelessWidget {
  const ScopeTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final root = _rootOf(context.alloyScope);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scope tree'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: ListView(children: [..._rows(root, 0)]),
    );
  }

  AlloyScope _rootOf(AlloyScope scope) {
    var current = scope;
    for (var parent = current.parent; parent != null; parent = current.parent) {
      current = parent;
    }
    return current;
  }

  Iterable<Widget> _rows(AlloyScope scope, int depth) sync* {
    yield ListTile(
      key: Key('scope-${scope.name}'),
      dense: true,
      title: Padding(
        padding: EdgeInsets.only(left: depth * 16.0),
        child: Text(scope.name),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(left: depth * 16.0),
        child: Text('${scope.state.name} · ${scope.children.length} children'),
      ),
    );
    for (final child in scope.children) {
      yield* _rows(child, depth + 1);
    }
  }
}
