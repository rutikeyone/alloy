import 'dart:async';

import 'package:alloy/alloy.dart';
import 'package:flutter/foundation.dart';
import 'package:notes_app/features/session/domain/session_user.dart';
import 'package:notes_app/features/session/session_scope.dart';

class SessionManager extends ChangeNotifier {
  SessionManager(this._appScope);

  final AlloyScope _appScope;
  AlloyScope? _session;

  AlloyScope? get scope => _session;

  bool get isSignedIn => _session != null;

  SessionUser? get user => _session?.get<SessionUser>();

  Future<void> signIn(SessionUser user) async {
    await signOut();
    final scope = _appScope.push('session:${user.id}');
    SessionScope(user).build(scope);
    await scope.init();
    _session = scope;
    notifyListeners();
  }

  Future<void> signOut() async {
    final scope = _session;
    if (scope == null) return;
    _session = null;
    await scope.dispose();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(signOut());
    super.dispose();
  }
}
