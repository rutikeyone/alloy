import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_scopes/features/workspace/domain/tab_marker.dart';

/// What the workspace shell, or one of its tabs, owns.
///
/// Eager rather than lazy, so entering the shell or a tab shows up in the
/// event log without anything having to resolve it first.
class WorkspaceScope implements AlloyScopeBuilder {
  const WorkspaceScope(this.label);

  final String label;

  @override
  void build(AlloyScope scope) =>
      scope.registerSingleton<TabMarker>(TabMarkerFactory(label).create(scope));
}
