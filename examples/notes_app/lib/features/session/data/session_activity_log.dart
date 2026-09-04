import 'package:cobalt/cobalt.dart';
import 'package:notes_app/core/event_log.dart';
import 'package:notes_app/features/session/domain/session_user.dart';

class SessionActivityLog implements Disposable {
  SessionActivityLog(this._user, this._appLog);

  final SessionUser _user;
  final EventLog _appLog;
  final entries = <String>[];

  var isClosed = false;

  void record(String entry) => entries.add('${_user.id}: $entry');

  @override
  void dispose() {
    isClosed = true;
    _appLog.record('session ${_user.id} closed with ${entries.length} entries');
  }
}

class SessionActivityLogFactory implements CobaltFactory<SessionActivityLog> {
  const SessionActivityLogFactory();

  @override
  SessionActivityLog create(CobaltResolver resolver) =>
      SessionActivityLog(resolver.get<SessionUser>(), resolver.get<EventLog>());
}
