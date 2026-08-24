import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_scopes/features/orders/domain/order_draft.dart';

/// What one run of the checkout flow owns.
class OrderFlowScope implements AlloyScopeBuilder {
  const OrderFlowScope(this.orderId);

  final String orderId;

  @override
  void build(AlloyScope scope) =>
      scope.registerLazySingleton<OrderDraft>(OrderDraftFactory(orderId));
}
