import 'package:cobalt_go_router/cobalt_go_router.dart';
import 'package:flow_scopes/l10n/flow_scopes_l10n.dart';
import 'package:flutter/material.dart';

/// Shared chrome around the flow.
///
/// It is built *inside* the flow's scope, which is why the app bar can name
/// the scope the flow is running in.
class OrderFlowChrome extends StatelessWidget {
  const OrderFlowChrome({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = FlowScopesL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checkoutFlow),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.scopeLine(context.cobaltScope.name),
              key: const Key('flow-scope-name'),
            ),
          ),
        ),
      ),
      body: child,
    );
  }
}
