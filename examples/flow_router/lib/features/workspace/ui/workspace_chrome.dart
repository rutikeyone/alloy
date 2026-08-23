import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_router/app/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared chrome for the workspace, built inside the shell's scope.
class WorkspaceChrome extends StatelessWidget {
  const WorkspaceChrome({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Workspace'),
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
            'shell scope: ${context.alloyScope.name}',
            key: const Key('workspace-scope-name'),
          ),
        ),
      ),
    ),
    body: navigationShell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: navigationShell.goBranch,
      destinations: const [
        NavigationDestination(
          key: Key('tab-feed'),
          icon: Icon(Icons.list),
          label: 'Feed',
        ),
        NavigationDestination(
          key: Key('tab-profile'),
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}
