import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/features/session/data/session_activity_log.dart';
import 'package:notes_app/features/session/domain/session_user.dart';
import 'package:notes_app/features/session/session_manager.dart';
import 'package:notes_app/l10n/notes_app_l10n.dart';

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
    final l10n = NotesL10n.of(context);
    final session = _session;
    final scope = session?.scope;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionScope)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session != null && session.isSignedIn
                  ? l10n.signedInAs(session.user!.displayName)
                  : l10n.signedOut,
              key: const Key('session-status'),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.scopeLine(scope?.name ?? l10n.noScope),
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
                child: Text(l10n.signIn),
              )
            else ...[
              FilledButton(
                key: const Key('record'),
                onPressed: () => setState(
                  () => scope.get<SessionActivityLog>().record('opened notes'),
                ),
                child: Text(l10n.recordActivity),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.activityCount(
                  scope.get<SessionActivityLog>().entries.length,
                ),
                key: const Key('activity-count'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('sign-out'),
                onPressed: session.signOut,
                child: Text(l10n.signOut),
              ),
            ],
            const Spacer(),
            Text(l10n.sessionExplained),
          ],
        ),
      ),
    );
  }
}
