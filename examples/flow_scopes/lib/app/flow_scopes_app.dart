import 'package:cobalt_go_router/cobalt_go_router.dart';
import 'package:flow_scopes/app/app_router.dart';
import 'package:flow_scopes/app/app_scope.dart';
import 'package:flow_scopes/l10n/flow_scopes_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    onGenerateTitle: (context) => FlowScopesL10n.of(context).appTitle,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
    // The gallery registers this delegate too, beside its own. Here it is
    // declared for the sake of running the example on its own.
    localizationsDelegates: const [
      FlowScopesL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: FlowScopesL10n.supportedLocales,
    builder: CobaltAppScope.builder(
      root: const AppScope(),
      rootName: 'app',
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    routerConfig: _router,
  );
}
