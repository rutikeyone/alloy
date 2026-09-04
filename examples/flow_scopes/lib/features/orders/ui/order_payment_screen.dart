import 'package:cobalt_go_router/cobalt_go_router.dart';
import 'package:flow_scopes/app/app_routes.dart';
import 'package:flow_scopes/features/orders/domain/order_draft.dart';
import 'package:flow_scopes/l10n/flow_scopes_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderPaymentScreen extends StatelessWidget {
  const OrderPaymentScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final l10n = FlowScopesL10n.of(context);
    final draft = context.cobalt<OrderDraft>();
    final other = orderId == '1' ? '2' : '1';

    return ListView(
      children: [
        ListTile(
          key: const Key('payment-draft'),
          title: const Text('get<OrderDraft>()'),
          subtitle: Text(
            l10n.draftLine(draft.orderId, '${identityHashCode(draft)}'),
          ),
        ),
        const Divider(),
        ListTile(
          key: const Key('switch-order'),
          title: Text(l10n.switchToOrder(other)),
          subtitle: Text(l10n.switchToOrderDetail),
          trailing: const Icon(Icons.swap_horiz),
          onTap: () => context.go(AppRoutes.summary(other)),
        ),
        ListTile(
          key: const Key('leave-flow'),
          title: Text(l10n.leaveFlow),
          subtitle: Text(l10n.leaveFlowDetail),
          trailing: const Icon(Icons.logout),
          onTap: () => context.go(AppRoutes.home),
        ),
      ],
    );
  }
}
