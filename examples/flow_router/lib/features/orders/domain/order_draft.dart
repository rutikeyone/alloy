import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_router/core/event_log.dart';

/// The thing a checkout flow is holding on to.
///
/// It is registered in the flow's scope, so it is built when the flow opens
/// and disposed when the flow closes — no screen has to remember to clear it.
class OrderDraft implements Disposable {
  OrderDraft(this.orderId, this._log) {
    _log.record('draft $orderId created');
  }

  final String orderId;
  final EventLog _log;

  var _note = '';

  String get note => _note;

  void write(String value) => _note = value;

  @override
  void dispose() => _log.record('draft $orderId disposed');
}

final class OrderDraftFactory implements AlloyFactory<OrderDraft> {
  const OrderDraftFactory(this.orderId);

  final String orderId;

  @override
  OrderDraft create(AlloyResolver resolver) =>
      OrderDraft(orderId, resolver.get<EventLog>());
}
