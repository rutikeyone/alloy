import 'package:cobalt_go_router/cobalt_go_router.dart';
import 'package:flow_scopes/app/app_routes.dart';
import 'package:flow_scopes/l10n/flow_scopes_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Renders the live scope tree, so a flow's scope can be watched appearing
/// and disappearing.
class ScopeTreeScreen extends StatelessWidget {
  const ScopeTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = FlowScopesL10n.of(context);
    final root = context.cobaltScope.root;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scopeTree),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: ListView(children: [..._rows(l10n, root, 0)]),
    );
  }

  Iterable<Widget> _rows(
    FlowScopesL10n l10n,
    CobaltScope scope,
    int depth,
  ) sync* {
    yield ListTile(
      key: Key('scope-${scope.name}'),
      dense: true,
      title: Padding(
        padding: EdgeInsets.only(left: depth * 16.0),
        child: Text(scope.name),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(left: depth * 16.0),
        child: Text(l10n.scopeNode(scope.state.name, scope.children.length)),
      ),
    );
    for (final child in scope.children) {
      yield* _rows(l10n, child, depth + 1);
    }
  }
}
