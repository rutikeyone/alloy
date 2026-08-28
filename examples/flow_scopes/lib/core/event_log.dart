import 'dart:async';

import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_scopes/core/flow_event.dart';
import 'package:flutter/foundation.dart';

/// Records what the graph did, so the example can show it on screen.
///
/// It lives in the root scope, which is why a flow can write to it and the
/// entry outlives the flow being torn down.
class EventLog extends ChangeNotifier {
  EventLog();

  final _entries = <FlowEvent>[];

  /// Everything recorded so far, oldest first.
  List<FlowEvent> get entries => List.unmodifiable(_entries);

  /// Appends [entry] and tells listeners on the next microtask.
  ///
  /// Not synchronous on purpose. A scope's registrations are built inside
  /// `didChangeDependencies`, which runs during the build phase, so a
  /// dependency that logs from its constructor would call `notifyListeners`
  /// mid-build and Flutter would throw `setState() called during build`.
  void record(FlowEvent entry) {
    _entries.add(entry);
    scheduleMicrotask(notifyListeners);
  }
}

final class EventLogFactory implements AlloyFactory<EventLog> {
  const EventLogFactory();

  @override
  EventLog create(AlloyResolver resolver) => EventLog();
}
