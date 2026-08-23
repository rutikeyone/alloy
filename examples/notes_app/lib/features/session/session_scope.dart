import 'package:alloy/alloy.dart';
import 'package:notes_app/features/session/data/session_activity_log.dart';
import 'package:notes_app/features/session/domain/session_user.dart';

class SessionScope implements AlloyScopeBuilder {
  const SessionScope(this.user);

  final SessionUser user;

  @override
  void build(AlloyScope scope) {
    scope
      ..registerSingleton<SessionUser>(user)
      ..registerLazySingleton<SessionActivityLog>(
        const SessionActivityLogFactory(),
      );
  }
}
