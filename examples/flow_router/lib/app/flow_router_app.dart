import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_router/app/app_router.dart';
import 'package:flow_router/app/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FlowRouterApp extends StatefulWidget {
  const FlowRouterApp({this.router, super.key});

  /// Supplied by tests that need to drive navigation directly.
  final GoRouter? router;

  @override
  State<FlowRouterApp> createState() => _FlowRouterAppState();
}

class _FlowRouterAppState extends State<FlowRouterApp> {
  late final GoRouter _router = widget.router ?? buildAppRouter();

  @override
  void dispose() {
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlloyAppScope(
    start: startFlowRouter,
    loading: const MaterialApp(
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    child: MaterialApp.router(
      title: 'Alloy flow scopes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      routerConfig: _router,
    ),
  );
}
