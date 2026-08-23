import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flutter/material.dart';

/// Shared chrome around the flow.
///
/// It is built *inside* the flow's scope, which is why the app bar can name
/// the scope the flow is running in.
class OrderFlowChrome extends StatelessWidget {
  const OrderFlowChrome({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Checkout flow'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(28),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'scope: ${context.alloyScope.name}',
            key: const Key('flow-scope-name'),
          ),
        ),
      ),
    ),
    body: child,
  );
}
