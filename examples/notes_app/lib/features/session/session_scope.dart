import 'package:cobalt/cobalt.dart';
import 'package:notes_app/features/session/data/session_activity_log.dart';
import 'package:notes_app/features/session/domain/session_user.dart';

class SessionScope implements CobaltScopeBuilder {
  const SessionScope(this.user);

  final SessionUser user;

  @override
  void build(CobaltScope scope) {
    scope
      ..registerSingleton<SessionUser>(user)
      ..registerLazySingleton<SessionActivityLog>(
        const SessionActivityLogFactory(),
      );
  }
}
