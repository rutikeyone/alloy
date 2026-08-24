import 'package:flow_scopes/app/app_router.dart';
import 'package:flow_scopes/app/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:gallery/catalog/example_host.dart';
import 'package:go_router/go_router.dart';

/// Mounts `flow_scopes` — router and all — inside one gallery route.
///
/// The other examples hand over a screen; this one is *about* navigation, so
/// it brings its own routing table. A nested [Router] is what makes that
/// possible without the gallery adopting go_router everywhere: `GoRouter` is a
/// `RouterConfig`, so it drops straight in.
///
/// The back button needs saying out loud. A nested router only receives the
/// system back press if it is given a dispatcher of its own, so where there is
/// a parent [Router] this takes a child dispatcher and holds priority. The
/// gallery is Navigator-based, so usually there is none: on Android the
/// hardware back then leaves the example rather than stepping out of the flow.
/// Navigation *inside* the flow is unaffected — that comes from go_router's
/// own navigator, which is the part this example is about.
class FlowScopesHost extends StatefulWidget {
  const FlowScopesHost({super.key});

  @override
  State<FlowScopesHost> createState() => _FlowScopesHostState();
}

class _FlowScopesHostState extends State<FlowScopesHost> {
  late final GoRouter _router = buildAppRouter();
  ChildBackButtonDispatcher? _backButton;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backButton = Router.maybeOf(
      context,
    )?.backButtonDispatcher?.createChildBackButtonDispatcher()?..takePriority();
  }

  @override
  void dispose() {
    final backButton = _backButton;
    if (backButton != null) backButton.parent.forget(backButton);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExampleHost(
    root: const AppScope(),
    rootName: 'app',
    seedColor: Colors.teal,
    // Spelled out rather than Router.withConfig, which takes the dispatcher
    // from the config and gives no way to substitute the child one.
    child: Router<Object>(
      routeInformationProvider: _router.routeInformationProvider,
      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
      backButtonDispatcher: _backButton,
      restorationScopeId: 'flow-scopes',
    ),
  );
}
