import 'package:cobalt_go_router/cobalt_go_router.dart';
import 'package:flow_scopes/app/app_routes.dart';
import 'package:flow_scopes/features/workspace/ui/tab_screen.dart';
import 'package:flow_scopes/features/workspace/ui/workspace_chrome.dart';
import 'package:flow_scopes/features/workspace/workspace_scope.dart';
import 'package:go_router/go_router.dart';

/// A tabbed area where the shell and each tab own a scope.
///
/// Three levels: `app` holds the shell's `workspace`, which holds `feed` and
/// `profile`. Switching tabs disposes nothing — branch navigators are kept
/// alive off-screen — and leaving the workspace disposes all three.
class WorkspaceShellRoute extends CobaltStatefulShellRoute {
  WorkspaceShellRoute()
    : super.indexedStack(
        name: 'workspace',
        scope: (_) => const WorkspaceScope('workspace'),
        shell: (_, _, navigationShell) =>
            WorkspaceChrome(navigationShell: navigationShell),
        branches: [
          CobaltStatefulShellBranch(
            name: 'feed',
            scope: (_) => const WorkspaceScope('feed'),
            routes: [
              GoRoute(
                path: AppRoutes.workspaceFeed,
                builder: (_, _) => const TabScreen(),
              ),
            ],
          ),
          CobaltStatefulShellBranch(
            name: 'profile',
            scope: (_) => const WorkspaceScope('profile'),
            routes: [
              GoRoute(
                path: AppRoutes.workspaceProfile,
                builder: (_, _) => const TabScreen(),
              ),
            ],
          ),
        ],
      );
}
