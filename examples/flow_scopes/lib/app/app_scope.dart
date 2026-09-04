import 'package:cobalt_go_router/cobalt_go_router.dart';
import 'package:flow_scopes/core/event_log.dart';

/// What the whole app owns, for as long as it runs.
class AppScope implements CobaltScopeBuilder {
  const AppScope();

  @override
  void build(CobaltScope scope) =>
      scope.registerLazySingleton<EventLog>(const EventLogFactory());
}
