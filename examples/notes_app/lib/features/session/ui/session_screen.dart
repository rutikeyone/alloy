import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/features/session/data/session_activity_log.dart';
import 'package:notes_app/features/session/domain/session_user.dart';
import 'package:notes_app/features/session/session_manager.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  SessionManager? _session;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.alloy<SessionManager>();
    if (identical(session, _session)) return;
    _session?.removeListener(_onChanged);
    _session = session;
    session.addListener(_onChanged);
  }

  @override
  void dispose() {
    _session?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final scope = session?.scope;

    return Scaffold(
      appBar: AppBar(title: const Text('Session scope')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session != null && session.isSignedIn
                  ? 'signed in as ${session.user!.displayName}'
                  : 'signed out',
              key: const Key('session-status'),
            ),
            const SizedBox(height: 8),
            Text(
              'scope: ${scope?.name ?? 'none'}',
              key: const Key('session-scope'),
            ),
            const SizedBox(height: 16),
            if (session == null)
              const SizedBox.shrink()
            else if (scope == null)
              FilledButton(
                key: const Key('sign-in'),
                onPressed: () => session.signIn(
                  const SessionUser(id: 'u-1', displayName: 'Ada'),
                ),
                child: const Text('sign in'),
              )
            else ...[
              FilledButton(
                key: const Key('record'),
                onPressed: () => setState(
                  () => scope.get<SessionActivityLog>().record('opened notes'),
                ),
                child: const Text('record activity'),
              ),
              const SizedBox(height: 8),
              Text(
                'activity: ${scope.get<SessionActivityLog>().entries.length}',
                key: const Key('activity-count'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('sign-out'),
                onPressed: session.signOut,
                child: const Text('sign out'),
              ),
            ],
            const Spacer(),
            const Text(
              'Signing out disposes the session scope. Everything built inside '
              'it goes with it — no reset() on any repository, no session '
              'listener anywhere.',
            ),
          ],
        ),
      ),
    );
  }
}
