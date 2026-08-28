import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_scopes/core/event_log.dart';
import 'package:flow_scopes/core/flow_event.dart';

/// Something a scope owns, that says when it was built and torn down.
///
/// Both the shell and each branch register one, which is how the event log
/// shows that a tab is kept alive rather than kept visible.
class TabMarker implements Disposable {
  TabMarker(this.label, this._log) {
    _log.record(FlowEvent(FlowEventKind.scopeBuilt, label));
  }

  final String label;
  final EventLog _log;

  @override
  void dispose() => _log.record(FlowEvent(FlowEventKind.scopeDisposed, label));
}

final class TabMarkerFactory implements AlloyFactory<TabMarker> {
  const TabMarkerFactory(this.label);

  final String label;

  @override
  TabMarker create(AlloyResolver resolver) =>
      TabMarker(label, resolver.get<EventLog>());
}
