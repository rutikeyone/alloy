/// go_router bindings for Alloy.
///
/// Re-exports the Flutter bindings, so an app routing with go_router needs
/// this import alone. [alloyFlowRoute] declares a navigation flow that owns a
/// scope: created on entry, disposed on exit, with `context.alloy<T>()`
/// resolving from it while the flow is open.
library;

export 'package:alloy_flutter/alloy_flutter.dart';

export 'package:alloy_go_router/src/alloy_flow_route.dart';
export 'package:alloy_go_router/src/alloy_flow_scope.dart';
export 'package:alloy_go_router/src/alloy_flow_shell_branch.dart';
export 'package:alloy_go_router/src/alloy_flow_shell_route.dart';
