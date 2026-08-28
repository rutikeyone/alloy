import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_scopes/app/app_routes.dart';
import 'package:flow_scopes/l10n/flow_scopes_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared chrome for the workspace, built inside the shell's scope.
class WorkspaceChrome extends StatelessWidget {
  const WorkspaceChrome({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = FlowScopesL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workspace),
        leading: IconButton(
          key: const Key('leave-workspace'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.shellScope(context.alloyScope.name),
              key: const Key('workspace-scope-name'),
            ),
          ),
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          NavigationDestination(
            key: const Key('tab-feed'),
            icon: const Icon(Icons.list),
            label: l10n.tabFeed,
          ),
          NavigationDestination(
            key: const Key('tab-profile'),
            icon: const Icon(Icons.person),
            label: l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}
