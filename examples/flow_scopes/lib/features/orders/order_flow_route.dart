import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_scopes/features/orders/order_flow_scope.dart';
import 'package:flow_scopes/features/orders/ui/order_flow_chrome.dart';
import 'package:flow_scopes/features/orders/ui/order_payment_screen.dart';
import 'package:flow_scopes/features/orders/ui/order_summary_screen.dart';
import 'package:go_router/go_router.dart';

/// The checkout flow, as a route type of its own.
///
/// Everything the flow is — its scope, its identity, its screens and its
/// chrome — lives here, so the route table just names it.
class OrderFlowRoute extends AlloyFlowRoute {
  OrderFlowRoute()
    : super(
        name: 'order',
        identity: _orderId,
        scope: (state) => OrderFlowScope(_orderId(state)),
        shell: (_, _, child) => OrderFlowChrome(child: child),
        routes: [
          GoRoute(
            path: '/orders/:orderId/summary',
            builder: (_, state) => OrderSummaryScreen(orderId: _orderId(state)),
          ),
          GoRoute(
            path: '/orders/:orderId/payment',
            builder: (_, state) => OrderPaymentScreen(orderId: _orderId(state)),
          ),
        ],
      );

  static String _orderId(GoRouterState state) =>
      state.pathParameters['orderId']!;
}
