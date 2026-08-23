import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_router/app/app_routes.dart';
import 'package:flow_router/features/orders/domain/order_draft.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderPaymentScreen extends StatelessWidget {
  const OrderPaymentScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final draft = context.alloy<OrderDraft>();
    final other = orderId == '1' ? '2' : '1';

    return ListView(
      children: [
        ListTile(
          key: const Key('payment-draft'),
          title: const Text('get<OrderDraft>()'),
          subtitle: Text(
            'order ${draft.orderId} · instance '
            '${identityHashCode(draft)}',
          ),
        ),
        const Divider(),
        ListTile(
          key: const Key('switch-order'),
          title: Text('Switch to order $other'),
          subtitle: const Text('identity changes — a new scope is built'),
          trailing: const Icon(Icons.swap_horiz),
          onTap: () => context.go(AppRoutes.summary(other)),
        ),
        ListTile(
          key: const Key('leave-flow'),
          title: const Text('Leave the flow'),
          subtitle: const Text('the scope and the draft go with it'),
          trailing: const Icon(Icons.logout),
          onTap: () => context.go(AppRoutes.home),
        ),
      ],
    );
  }
}
