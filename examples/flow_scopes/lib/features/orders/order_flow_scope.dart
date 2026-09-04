import 'package:cobalt_go_router/cobalt_go_router.dart';
import 'package:flow_scopes/features/orders/domain/order_draft.dart';

/// What one run of the checkout flow owns.
class OrderFlowScope implements CobaltScopeBuilder {
  const OrderFlowScope(this.orderId);

  final String orderId;

  @override
  void build(CobaltScope scope) =>
      scope.registerLazySingleton<OrderDraft>(OrderDraftFactory(orderId));
}
