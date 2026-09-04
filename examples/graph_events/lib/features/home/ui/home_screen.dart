import 'package:cobalt_flutter/cobalt_flutter.dart';
import 'package:flutter/material.dart';
import 'package:graph_events/app/report_log.dart';
import 'package:graph_events/l10n/graph_events_l10n.dart';
import 'package:graph_events/features/home/ui/last_report_tile.dart';
import 'package:graph_events/features/session/session_scope.dart';
import 'package:cobalt_talker_flutter/cobalt_talker_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Drives the graph so the log has something to show.
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.talker, required this.reports, super.key});

  final Talker talker;

  /// Where CobaltErrorObserver's reports land.
  final ReportLog reports;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CobaltScope? _session;
  var _busy = false;

  Future<void> _openSession({required bool breaks}) async {
    if (_session != null || _busy) return;
    setState(() => _busy = true);
    final scope = context.cobaltScope.push(
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
    } on CobaltDisposeError catch (error) {
      widget.talker.handle(error, StackTrace.current, 'session teardown');
    }
    if (!mounted) return;
    setState(() {
      _session = null;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GraphEventsL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            key: const Key('open-log'),
            tooltip: l10n.liveLog,
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CobaltTalkerScreen(talker: widget.talker),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.everyEvent),
            subtitle: Text(l10n.everyEventDetail),
          ),
          const Divider(),
          ListTile(
            key: const Key('open-session'),
            enabled: _session == null && !_busy,
            title: Text(l10n.openSession),
            subtitle: Text(l10n.openSessionDetail),
            trailing: const Icon(Icons.login),
            onTap: () => _openSession(breaks: false),
          ),
          ListTile(
            key: const Key('open-broken-session'),
            enabled: _session == null && !_busy,
            title: Text(l10n.openBrokenSession),
            subtitle: Text(l10n.openBrokenSessionDetail),
            trailing: const Icon(Icons.report),
            onTap: () => _openSession(breaks: true),
          ),
          ListTile(
            key: const Key('close-session'),
            enabled: _session != null && !_busy,
            title: Text(l10n.closeSession),
            subtitle: Text(
              _session == null
                  ? l10n.nothingOpen
                  : l10n.scopeNamed(_session!.name),
            ),
            trailing: const Icon(Icons.logout),
            onTap: _closeSession,
          ),
          const Divider(),
          LastReportTile(log: widget.reports),
          const Divider(),
          ListTile(
            key: const Key('event-count'),
            title: Text(l10n.eventsRecorded),
            subtitle: Text('${widget.talker.history.length}'),
          ),
        ],
      ),
    );
  }
}
