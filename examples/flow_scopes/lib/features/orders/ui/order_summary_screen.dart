import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_scopes/app/app_routes.dart';
import 'package:flow_scopes/features/orders/domain/order_draft.dart';
import 'package:flow_scopes/l10n/flow_scopes_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final l10n = FlowScopesL10n.of(context);
    final draft = context.alloy<OrderDraft>();

    return ListView(
      children: [
        ListTile(
          key: const Key('summary-draft'),
          title: const Text('get<OrderDraft>()'),
          subtitle: Text(
            l10n.draftLine(draft.orderId, '${identityHashCode(draft)}'),
          ),
        ),
        const Divider(),
        ListTile(
          key: const Key('to-payment'),
          title: Text(l10n.continueToPayment),
          subtitle: Text(l10n.continueToPaymentDetail),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(AppRoutes.payment(orderId)),
        ),
      ],
    );
  }
}
