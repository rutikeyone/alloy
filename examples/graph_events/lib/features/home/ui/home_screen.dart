import 'package:alloy_flutter/alloy_flutter.dart';
import 'package:flutter/material.dart';
import 'package:graph_events/features/session/session_scope.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Drives the graph so the log has something to show.
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.talker, super.key});

  final Talker talker;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AlloyScope? _session;
  var _busy = false;

  Future<void> _openSession({required bool breaks}) async {
    if (_session != null || _busy) return;
    setState(() => _busy = true);
    final scope = context.alloyScope.push(
      breaks ? 'session:broken' : 'session',
    );
    SessionScope(breaks: breaks).build(scope);
    await scope.init();
    if (!mounted) return;
    setState(() {
      _session = scope;
      _busy = false;
    });
  }

  Future<void> _closeSession() async {
    final scope = _session;
    if (scope == null || _busy) return;
    setState(() => _busy = true);
    try {
      await scope.dispose();
    } on AlloyDisposeError catch (error) {
      widget.talker.handle(error, StackTrace.current, 'session teardown');
    }
    if (!mounted) return;
    setState(() {
      _session = null;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Alloy · observability'),
      actions: [
        IconButton(
          key: const Key('open-log'),
          tooltip: 'the live log',
          icon: const Icon(Icons.receipt_long),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TalkerScreen(talker: widget.talker),
            ),
          ),
        ),
      ],
    ),
    body: ListView(
      children: [
        const ListTile(
          title: Text('Every event below is the graph reporting itself'),
          subtitle: Text(
            'AlloyTalkerObserver files each kind under its own title, so the '
            'log screen can filter them apart.',
          ),
        ),
        const Divider(),
        ListTile(
          key: const Key('open-session'),
          enabled: _session == null && !_busy,
          title: const Text('Open a session scope'),
          subtitle: const Text('a push, an async init, some instances'),
          trailing: const Icon(Icons.login),
          onTap: () => _openSession(breaks: false),
        ),
        ListTile(
          key: const Key('open-broken-session'),
          enabled: _session == null && !_busy,
          title: const Text('Open one that will not close'),
          subtitle: const Text('its teardown throws, on purpose'),
          trailing: const Icon(Icons.report),
          onTap: () => _openSession(breaks: true),
        ),
        ListTile(
          key: const Key('close-session'),
          enabled: _session != null && !_busy,
          title: const Text('Close the session'),
          subtitle: Text(
            _session == null ? 'nothing open' : 'scope "${_session!.name}"',
          ),
          trailing: const Icon(Icons.logout),
          onTap: _closeSession,
        ),
        const Divider(),
        ListTile(
          key: const Key('event-count'),
          title: const Text('Events recorded'),
          subtitle: Text('${widget.talker.history.length}'),
        ),
      ],
    ),
  );
}
