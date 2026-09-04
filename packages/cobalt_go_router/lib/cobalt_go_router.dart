/// go_router bindings for Cobalt.
///
/// Re-exports the Flutter bindings, so an app routing with go_router needs
/// this import alone. [cobaltShellRoute] declares a navigation flow that owns a
/// scope: created on entry, disposed on exit, with `context.cobalt<T>()`
/// resolving from it while the flow is open.
library;

export 'package:cobalt_flutter/cobalt_flutter.dart';

export 'package:cobalt_go_router/src/cobalt_route_scope.dart';
export 'package:cobalt_go_router/src/cobalt_shell_route.dart';
export 'package:cobalt_go_router/src/cobalt_stateful_shell_branch.dart';
export 'package:cobalt_go_router/src/cobalt_stateful_shell_route.dart';
