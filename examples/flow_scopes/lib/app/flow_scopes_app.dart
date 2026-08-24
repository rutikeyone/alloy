import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_scopes/app/app_router.dart';
import 'package:flow_scopes/app/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FlowScopesApp extends StatefulWidget {
  const FlowScopesApp({this.router, super.key});

  /// Supplied by tests that need to drive navigation directly.
  final GoRouter? router;

  @override
  State<FlowScopesApp> createState() => _FlowScopesAppState();
}

class _FlowScopesAppState extends State<FlowScopesApp> {
  late final GoRouter _router = widget.router ?? buildAppRouter();

  @override
  void dispose() {
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Alloy flow scopes',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
    builder: AlloyAppScope.builder(
      root: const AppScope(),
      rootName: 'app',
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    routerConfig: _router,
  );
}
