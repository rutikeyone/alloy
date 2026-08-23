import 'package:alloy_go_router/alloy_go_router.dart';
import 'package:flow_router/core/event_log.dart';

/// What the whole app owns, for as long as it runs.
class AppScope implements AlloyScopeBuilder {
  const AppScope();

  @override
  void build(AlloyScope scope) =>
      scope.registerLazySingleton<EventLog>(const EventLogFactory());
}
