import 'package:flow_scopes/app/app_routes.dart';
import 'package:flow_scopes/features/diagnostics/ui/scope_tree_screen.dart';
import 'package:flow_scopes/features/home/ui/home_screen.dart';
import 'package:flow_scopes/features/orders/order_flow_route.dart';
import 'package:flow_scopes/features/workspace/workspace_shell_route.dart';
import 'package:go_router/go_router.dart';

/// The whole routing table.
///
/// [OrderFlowRoute] is the only thing that is not plain go_router, and it is
/// an ordinary `ShellRoute` subclass — everything inside it resolves from the
/// flow's scope, and that scope is gone the moment navigation leaves.
GoRouter buildAppRouter({String initialLocation = AppRoutes.home}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: AppRoutes.scopeTree,
      builder: (_, _) => const ScopeTreeScreen(),
    ),
    OrderFlowRoute(),
    WorkspaceShellRoute(),
  ],
);
